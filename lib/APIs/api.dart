import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:blackhole/Helpers/format.dart';

class Search {
  List preferredLanguage = Hive.box('settings')
      .get('preferredLanguage', defaultValue: ['Hindi'])?.toList();
  Map<String, String> headers = {};

  Future<Map> setHeader() async {
    preferredLanguage =
        preferredLanguage.map((email) => email.toLowerCase()).toList();
    String languageHeader = 'L=' + preferredLanguage.join('%2C');
    headers = {"cookie": languageHeader};
    return headers;
  }

  Future<List> fetchSongSearchResults(String searchQuery, String count) async {
    List searchedList = [];
    Uri searchUrl = Uri.https(
      "www.jiosaavn.com",
      "/api.php?p=1&q=$searchQuery&_format=json&_marker=0&api_version=4&ctx=wap6dot0&n=$count&__call=search.getResults",
    );
    await setHeader();
    try {
      final res = await get(searchUrl, headers: headers);
      if (res.statusCode == 200) {
        print(res.headers);
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

    await setHeader();

    Uri searchUrl = Uri.https("www.jiosaavn.com",
        "api.php?__call=autocomplete.get&_format=json&_marker=0&cc=in&includeMetaTags=1&query=$searchQuery");

    final res = await get(searchUrl, headers: headers);
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
    await setHeader();
    Uri searchUrl;
    if (type == 'playlist')
      searchUrl = Uri.https("www.jiosaavn.com",
          "/api.php?p=1&q=$searchQuery&_format=json&_marker=0&api_version=4&ctx=wap6dot0&n=20&__call=search.getPlaylistResults");
    if (type == 'album')
      searchUrl = Uri.https("www.jiosaavn.com",
          "/api.php?p=1&q=$searchQuery&_format=json&_marker=0&api_version=4&ctx=wap6dot0&n=20&__call=search.getAlbumResults");

    if (type == 'artist')
      searchUrl = Uri.https("www.jiosaavn.com",
          "/api.php?p=1&q=$searchQuery&_format=json&_marker=0&api_version=4&ctx=wap6dot0&n=20&__call=search.getArtistResults");

    final res = await get(searchUrl, headers: headers);
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
    Uri searchUrl = Uri.https(
      "www.jiosaavn.com",
      "/api.php?__call=content.getAlbumDetails&_format=json&cc=in&_marker=0%3F_marker=0&albumid=$albumId",
    );
    await setHeader();
    final res = await get(searchUrl, headers: headers);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List responseList = getMain["songs"];
      searchedList =
          await FormatResponse().formatSongsResponse(responseList, 'album');
    }
    return searchedList;
  }

  Future<Map> fetchArtistSongs(String artistToken) async {
    Map<String, List> data = {};
    Uri searchUrl = Uri.https("www.jiosaavn.com",
        "/api.php?__call=webapi.get&type=artist&p=&n_song=50&n_album=50&sub_type=&category=&sort_order=&includeMetaTags=0&ctx=wap6dot0&api_version=4&_format=json&_marker=0&token=$artistToken");
    await setHeader();
    final res = await get(searchUrl, headers: headers);
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
    Uri searchUrl = Uri.https(
      "www.jiosaavn.com",
      "/api.php?__call=playlist.getDetails&_format=json&cc=in&_marker=0%3F_marker%3D0&listid=$playlistId",
    );
    await setHeader();
    final res = await get(searchUrl, headers: headers);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List responseList = getMain["songs"];
      searchedList =
          await FormatResponse().formatSongsResponse(responseList, 'playlist');
    }
    return searchedList;
  }

  Future<List> fetchTopSearchResult(String searchQuery) async {
    List searchedList = [];
    Uri searchUrl = Uri.https(
      "www.jiosaavn.com",
      "/api.php?p=1&q=$searchQuery&_format=json&_marker=0&api_version=4&ctx=wap6dot0&n=10&__call=search.getResults",
    );
    await setHeader();
    final res = await get(searchUrl, headers: headers);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List responseList = getMain["results"];
      searchedList.add(
          await FormatResponse().formatSingleSongResponse(responseList[0]));
    }
    return searchedList;
  }
}

class Playlist {
  Future<Map> fetchPlaylistSongs(Map item) async {
    Uri playlistUrl = Uri.https("www.jiosaavn.com",
        "/api.php?__call=webapi.get&token=${item["id"]}&type=playlist&p=1&n=100&includeMetaTags=0&ctx=web6dot0&api_version=4&_format=json&_marker=0");
    final res = await get(playlistUrl, headers: {"Accept": "application/json"});
    final playlist = json.decode(res.body);
    if (res.statusCode == 200) {
      item["title"] = playlist["title"];
      item["image"] = playlist["image"];
      item["songsList"] =
          await FormatResponse().formatSongsResponse(playlist["list"], 'song');
    }
    return item;
  }
}
