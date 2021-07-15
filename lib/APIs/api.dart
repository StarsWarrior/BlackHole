import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:blackhole/Helpers/format.dart';
import 'package:http/io_client.dart';

class SaavnAPI {
  List preferredLanguages = Hive.box('settings')
      .get('preferredLanguage', defaultValue: ['Hindi'])?.toList();
  Map<String, String> headers = {};
  String baseUrl = "www.jiosaavn.com";
  String apiStr = "/api.php?_format=json&_marker=0&api_version=4&ctx=web6dot0";
  Box settingsBox = Hive.box('settings');

  Future<Response> getResponse(String params,
      {bool usev4 = true, bool useProxy = false}) async {
    Uri url;
    if (!usev4)
      url = Uri.https(
          baseUrl, "$apiStr&$params".replaceAll("&api_version=4", ""));
    else
      url = Uri.https(baseUrl, "$apiStr&$params");
    preferredLanguages =
        preferredLanguages.map((lang) => lang.toLowerCase()).toList();
    String languageHeader = 'L=' + preferredLanguages.join('%2C');
    headers = {"cookie": languageHeader, "Accept": "*/*"};

    useProxy = useProxy && settingsBox.get('useProxy', defaultValue: false);
    if (useProxy) {
      final proxyIP = settingsBox.get("proxyIp");
      final proxyPort = settingsBox.get("proxyPort");
      HttpClient httpClient = new HttpClient();
      httpClient.findProxy = (uri) {
        return "PROXY $proxyIP:$proxyPort;";
      };
      httpClient.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => Platform.isAndroid);
      IOClient myClient = IOClient(httpClient);
      return await myClient.get(url, headers: headers);
    }

    return await get(url, headers: headers);
  }

  Future<Map> fetchHomePageData() async {
    String params = "__call=webapi.getLaunchData";
    Map result;
    try {
      final res = await getResponse(params);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        result = await FormatResponse().formatHomePageData(data);
      }
    } catch (e) {
      print(e);
    }
    return result;
  }

  Future<List> getTopSearches() async {
    List result = [];
    String params = "__call=content.getTopSearches";
    try {
      final res = await getResponse(params, useProxy: true);
      if (res.statusCode == 200) {
        final List getMain = json.decode(res.body);
        result = getMain.map((element) {
          return element["title"];
        }).toList();
      }
    } catch (e) {}
    return result;
  }

  Future<List> fetchSongSearchResults(String searchQuery, String count) async {
    List searchedList = [];
    String params = "p=1&q=$searchQuery&n=$count&__call=search.getResults";

    try {
      final res = await getResponse(params, useProxy: true);
      if (res.statusCode == 200) {
        final getMain = json.decode(res.body);
        List responseList = getMain["results"];
        searchedList =
            await FormatResponse().formatSongsResponse(responseList, 'song');
      }
    } catch (e) {}
    return searchedList;
  }

  Future<List<Map>> fetchSearchResults(String searchQuery) async {
    Map<String, List> result = {};
    Map<int, String> position = {};
    List searchedAlbumList = [];
    List searchedPlaylistList = [];
    List searchedArtistList = [];
    List searchedTopQueryList = [];

    String params =
        "__call=autocomplete.get&cc=in&includeMetaTags=1&query=$searchQuery";

    final res = await getResponse(params, usev4: false, useProxy: true);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List albumResponseList = getMain["albums"]["data"];
      position[getMain["albums"]["position"]] = 'Albums';
      List playlistResponseList = getMain["playlists"]["data"];
      position[getMain["playlists"]["position"]] = 'Playlists';
      List artistResponseList = getMain["artists"]["data"];
      position[getMain["artists"]["position"]] = 'Artists';
      List topQuery = getMain["topquery"]["data"];

      searchedAlbumList = await FormatResponse()
          .formatAlbumResponse(albumResponseList, 'album');
      if (searchedAlbumList.isNotEmpty) result['Albums'] = searchedAlbumList;

      searchedPlaylistList = await FormatResponse()
          .formatAlbumResponse(playlistResponseList, 'playlist');
      if (searchedPlaylistList.isNotEmpty)
        result['Playlists'] = searchedPlaylistList;

      searchedArtistList = await FormatResponse()
          .formatAlbumResponse(artistResponseList, 'artist');
      if (searchedArtistList.isNotEmpty) result['Artists'] = searchedArtistList;

      if (topQuery.isNotEmpty &&
          (topQuery[0]["type"] == 'playlist' ||
              topQuery[0]["type"] == 'artist' ||
              topQuery[0]["type"] == 'album')) {
        position[getMain["topquery"]["position"]] = 'Top Result';
        position[getMain["songs"]["position"]] = 'Songs';

        switch (topQuery[0]["type"]) {
          case ('artist'):
            searchedTopQueryList =
                await FormatResponse().formatAlbumResponse(topQuery, 'artist');
            break;
          case ('album'):
            searchedTopQueryList =
                await FormatResponse().formatAlbumResponse(topQuery, 'album');
            break;
          case ('playlist'):
            searchedTopQueryList = await FormatResponse()
                .formatAlbumResponse(topQuery, 'playlist');
            break;
          default:
            break;
        }
        if (searchedTopQueryList.isNotEmpty)
          result['Top Result'] = searchedTopQueryList;
      } else {
        if (topQuery.isNotEmpty && topQuery[0]["type"] == 'song') {
          position[getMain["topquery"]["position"]] = 'Songs';
        } else {
          position[getMain["songs"]["position"]] = 'Songs';
        }
      }
    }
    return [result, position];
  }

  Future<List> fetchAlbums(String searchQuery, String type) async {
    List searchedList = [];
    String params;
    if (type == 'playlist')
      params = "p=1&q=$searchQuery&n=20&__call=search.getPlaylistResults";
    if (type == 'album')
      params = "p=1&q=$searchQuery&n=20&__call=search.getAlbumResults";
    if (type == 'artist')
      params = "p=1&q=$searchQuery&n=20&__call=search.getArtistResults";

    final res = await getResponse(params);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List responseList = getMain["results"];
      searchedList =
          await FormatResponse().formatAlbumResponse(responseList, type);
    }
    return searchedList;
  }

  Future<List> fetchAlbumSongs(String albumId) async {
    List searchedList = [];
    String params = "__call=content.getAlbumDetails&cc=in&albumid=$albumId";
    final res = await getResponse(params);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List responseList = getMain["list"];
      searchedList =
          await FormatResponse().formatSongsResponse(responseList, 'album');
    }
    return searchedList;
  }

  Future<Map> fetchArtistSongs(String artistToken) async {
    Map<String, List> data = {};
    String params =
        "__call=webapi.get&type=artist&p=&n_song=50&n_album=50&sub_type=&category=&sort_order=&includeMetaTags=0&token=$artistToken";
    final res = await getResponse(params);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List topSongsResponseList = getMain["topSongs"];
      List topAlbumsResponseList = getMain["topAlbums"];
      // List singlesResponseList = getMain["singles"];
      // List latestReleaseResponseList = getMain["latest_release"];
      // List dedicatedArtistPlaylistResponseList = [];
      // if (getMain["dedicated_artist_playlist"] is List) {
      //   dedicatedArtistPlaylistResponseList =
      //       getMain["dedicated_artist_playlist"];
      // }
      // List featuredArtistPlaylistResponseList = [];
      // if (getMain["featured_artist_playlist"] is List) {
      //   featuredArtistPlaylistResponseList =
      //       getMain["featured_artist_playlist"];
      // }

      List topSongsSearchedList = await FormatResponse()
          .formatSongsResponse(topSongsResponseList, 'song');
      if (topSongsSearchedList.isNotEmpty)
        data['Top Songs'] = topSongsSearchedList;

      List topAlbumsSearchedList = await FormatResponse()
          .formatArtistTopAlbumsResponse(topAlbumsResponseList);
      if (topAlbumsSearchedList.isNotEmpty)
        data['Top Albums'] = topAlbumsSearchedList;

      // List latestReleaseSearchedList = await FormatResponse()
      // .formatSongsResponse(latestReleaseResponseList, 'songs');
      // if (latestReleaseSearchedList.isNotEmpty)
      // data['Latest Release'] = latestReleaseSearchedList;

      // List singlesSearchedList = await FormatResponse()
      // .formatSongsResponse(singlesResponseList, 'songs');
      // if (singlesSearchedList.isNotEmpty) data['Singles'] = singlesSearchedList;

      // List dedicatedArtistPlaylistSearchedList = await FormatResponse()
      //     .formatArtistDedicatedArtistPlaylistResponse(
      //         dedicatedArtistPlaylistResponseList);
      // if (dedicatedArtistPlaylistSearchedList.isNotEmpty)
      //   data['Dedicated Artist Playlist'] = dedicatedArtistPlaylistSearchedList;

      // List featuredArtistPlaylistSearchedList = await FormatResponse()
      //     .formatArtistFeaturedArtistPlaylistResponse(
      //         featuredArtistPlaylistResponseList);
      // if (featuredArtistPlaylistSearchedList.isNotEmpty)
      //   data['Featured Artist Playlist'] = featuredArtistPlaylistSearchedList;
    }
    return data;
  }

  Future<List> fetchPlaylistSongs(String playlistId) async {
    List searchedList = [];
    String params = "__call=playlist.getDetails&cc=in&listid=$playlistId";
    final res = await getResponse(params);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List responseList = getMain["list"];
      searchedList =
          await FormatResponse().formatSongsResponse(responseList, 'playlist');
    }
    return searchedList;
  }

  Future<List> fetchTopSearchResult(String searchQuery) async {
    List searchedList = [];
    String params = "p=1&q=$searchQuery&n=10&__call=search.getResults";
    final res = await getResponse(params, useProxy: true);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List responseList = getMain["results"];
      searchedList.add(
          await FormatResponse().formatSingleSongResponse(responseList[0]));
    }
    return searchedList;
  }

  Future<Map> fetchSongDetails(String songId) async {
    Map result;
    String params = "pids=$songId&__call=song.getDetails";
    try {
      final res = await getResponse(params);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        result =
            await FormatResponse().formatSingleSongResponse(data["songs"][0]);
      }
    } catch (err) {
      print(err);
    }
    return result;
  }
}
