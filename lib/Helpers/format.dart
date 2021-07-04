import 'package:des_plugin/des_plugin.dart';

class FormatResponse {
  String capitalize(String msg) {
    return "${msg[0].toUpperCase()}${msg.substring(1)}";
  }

  Future<List> formatSongsResponse(List responseList, String type) async {
    List searchedList = [];
    for (int i = 0; i < responseList.length; i++) {
      Map response;
      switch (type) {
        case 'song':
        case 'album':
        case 'playlist':
          response = await formatSingleSongResponse(responseList[i]);
          break;
        default:
          break;
      }

      if (response.containsKey('Error')) {
        print("Error at index $i inside FormatResponse: ${response['Error']}");
      } else {
        searchedList.add(response);
      }
    }
    return searchedList;
  }

  Future<Map> formatSingleSongResponse(Map response) async {
    try {
      List artistNames = [];
      if (response['more_info']["artistMap"]['primary_artists'] == null ||
          response['more_info']["artistMap"]['primary_artists'].length == 0) {
        if (response['more_info']["artistMap"]['featured_artists'] == null ||
            response['more_info']["artistMap"]['featured_artists'].length ==
                0) {
          if (response['more_info']["artistMap"]['artists'] == null ||
              response['more_info']["artistMap"]['artists'].length == 0) {
            artistNames.add("Unknown");
          } else {
            response['more_info']["artistMap"]['artists'].forEach((element) {
              artistNames.add(element["name"]);
            });
          }
        } else {
          response['more_info']["artistMap"]['featured_artists']
              .forEach((element) {
            artistNames.add(element["name"]);
          });
        }
      } else {
        response['more_info']["artistMap"]['primary_artists']
            .forEach((element) {
          artistNames.add(element["name"]);
        });
      }

      Map info = {
        "id": response["id"],
        "type": response["type"],
        "album": response["more_info"]["album"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "year": response["year"],
        "duration": response["more_info"]["duration"],
        "language": capitalize(response["language"].toString()),
        "genre": capitalize(response["language"].toString()),
        "320kbps": response["more_info"]["320kbps"],
        "has_lyrics": response["more_info"]["has_lyrics"],
        "lyrics_snippet": response["more_info"]["lyrics_snippet"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\""),
        "release_date": response["more_info"]["release_date"],
        "album_id": response["more_info"]["album_id"],
        "subtitle": response['subtitle']
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            .trim(),
        "title": response['title']
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "artist": artistNames
            .join(", ")
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            .trim(),
        "image": response["image"]
            .toString()
            .replaceAll("150x150", "500x500")
            .replaceAll('50x50', "500x500")
            .replaceAll('http:', 'https:'),
        "url": await DesPlugin.decrypt(
            "38346591", response["more_info"]["encrypted_media_url"])
      };
      info["url"] = info["url"].replaceAll("http:", "https:");
      return info;
    } catch (e) {
      return {"Error": e};
    }
  }

  Future<Map> formatSingleAlbumSongResponse(Map response) async {
    try {
      List artistNames = [];
      if (response['primary_artists'] == null ||
          response['primary_artists'].toString().trim() == '') {
        if (response['featured_artists'] == null ||
            response['featured_artists'].toString().trim() == '') {
          if (response['singers'] == null ||
              response['singer'].toString().trim() == '') {
            response['singers'].toString().split(', ').forEach((element) {
              artistNames.add(element);
            });
          } else {
            artistNames.add("Unknown");
          }
        } else {
          response['featured_artists']
              .toString()
              .split(', ')
              .forEach((element) {
            artistNames.add(element);
          });
        }
      } else {
        response['primary_artists'].toString().split(', ').forEach((element) {
          artistNames.add(element);
        });
      }

      Map info = {
        "id": response["id"],
        "type": response["type"],
        "album": response["album"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "year": response["year"],
        "duration": response["duration"],
        "language": capitalize(response["language"].toString()),
        "genre": capitalize(response["language"].toString()),
        "320kbps": response["320kbps"],
        "has_lyrics": response["has_lyrics"],
        "lyrics_snippet": response["lyrics_snippet"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\""),
        "release_date": response["release_date"],
        "album_id": response["album_id"],
        "subtitle":
            "${response['primary_artists'].toString().trim()} - ${response['album'].toString().trim()}"
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\""),
        "title": response['song']
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "artist": artistNames
            .join(", ")
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            .trim(),
        "image": response["image"]
            .toString()
            .replaceAll("150x150", "500x500")
            .replaceAll('50x50', "500x500")
            .replaceAll('http:', 'https:'),
        "url":
            await DesPlugin.decrypt("38346591", response["encrypted_media_url"])
      };
      return info;
    } catch (e) {
      return {"Error": e};
    }
  }

  Future<List> formatAlbumResponse(List responseList, String type) async {
    List searchedAlbumList = [];
    for (int i = 0; i < responseList.length; i++) {
      Map response;
      switch (type) {
        case 'album':
          response = await formatSingleAlbumResponse(responseList[i]);
          break;
        case 'artist':
          response = await formatSingleArtistResponse(responseList[i]);
          break;
        case 'playlist':
          response = await formatSinglePlaylistResponse(responseList[i]);
          break;
      }
      if (response.containsKey('Error')) {
        print(
            "Error at index $i inside FormatAlbumResponse: ${response['Error']}");
      } else {
        searchedAlbumList.add(response);
      }
    }
    return searchedAlbumList;
  }

  Future<Map> formatSingleAlbumResponse(Map response) async {
    try {
      Map info = {
        "id": response["id"],
        "type": response["type"],
        "album": response["title"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "year": response["more_info"]["year"] ?? response["year"],
        "language": capitalize(response["more_info"]["language"] == null
            ? response["language"].toString()
            : response["more_info"]["language"].toString()),
        "genre": capitalize(response["more_info"]["language"] == null
            ? response["language"].toString()
            : response["more_info"]["language"].toString()),
        "album_id": response["id"],
        "subtitle": response["description"] == null
            ? response["subtitle"]
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
                .trim()
            : response["description"]
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\""),
        "title": response['title']
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "artist": response["music"] == null
            ? (response["more_info"]["artistMap"]["primary_artists"] == null
                ? ''
                : response["more_info"]["artistMap"]["primary_artists"][0]
                    ["name"])
            : response["music"]
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
                .trim(),
        "image": response["image"]
            .toString()
            .replaceAll("150x150", "500x500")
            .replaceAll('50x50', "500x500")
            .replaceAll('http:', 'https:'),
        "count": response["more_info"]["song_pids"] == null
            ? 0
            : response["more_info"]["song_pids"].toString().split(", ").length,
        "songs_pids": response["more_info"]["song_pids"].toString().split(", "),
      };
      return info;
    } catch (e) {
      return {"Error": e};
    }
  }

  Future<Map> formatSinglePlaylistResponse(Map response) async {
    try {
      Map info = {
        "id": response["id"],
        "type": response["type"],
        "album": response["title"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            .trim(),
        "language": capitalize(response["language"] == null
            ? response["more_info"]["language"].toString()
            : response["language"].toString()),
        "genre": capitalize(response["language"] == null
            ? response["more_info"]["language"].toString()
            : response["language"].toString()),
        "playlistId": response["id"],
        "subtitle": response["description"] == null
            ? response["subtitle"]
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
                .trim()
            : response["description"]
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
                .trim(),
        "title": response['title']
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "artist": response["extra"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            .trim(),
        "image": response["image"]
            .toString()
            .replaceAll("150x150", "500x500")
            .replaceAll('50x50', "500x500")
            .replaceAll('http:', 'https:'),
      };
      return info;
    } catch (e) {
      return {"Error": e};
    }
  }

  Future<Map> formatSingleArtistResponse(Map response) async {
    try {
      Map info = {
        "id": response["id"],
        "type": response["type"],
        "album": response['title'] == null
            ? response['name']
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
            : response['title']
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\""),
        "language": capitalize(response["language"].toString()),
        "genre": capitalize(response["language"].toString()),
        "artistId": response["id"],
        "artistToken": response["url"] == null
            ? response["perma_url"].toString().split('/').last
            : response["url"].toString().split('/').last,
        "subtitle": response["description"] == null
            ? capitalize(response["role"])
            : response["description"]
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
                .trim(),
        "title": response['title'] == null
            ? response['name']
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
            : response['title']
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
                // .split('(')
                // .first
                .trim(),
        "artist": response["title"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            .trim(),
        "image": response["image"]
            .toString()
            .replaceAll("150x150", "500x500")
            .replaceAll('50x50', "500x500")
            .replaceAll('http:', 'https:'),
      };
      return info;
    } catch (e) {
      return {"Error": e};
    }
  }

  Future<List> formatArtistTopAlbumsResponse(List responseList) async {
    List result = [];
    for (int i = 0; i < responseList.length; i++) {
      Map response =
          await formatSingleArtistTopAlbumSongResponse(responseList[i]);
      if (response.containsKey('Error')) {
        print("Error at index $i inside FormatResponse: ${response['Error']}");
      } else {
        result.add(response);
      }
    }
    return result;
  }

  Future<Map> formatSingleArtistTopAlbumSongResponse(Map response) async {
    try {
      List artistNames = [];
      if (response['more_info']["artistMap"]['primary_artists'] == null ||
          response['more_info']["artistMap"]['primary_artists'].length == 0) {
        if (response['more_info']["artistMap"]['featured_artists'] == null ||
            response['more_info']["artistMap"]['featured_artists'].length ==
                0) {
          if (response['more_info']["artistMap"]['artists'] == null ||
              response['more_info']["artistMap"]['artists'].length == 0) {
            artistNames.add("Unknown");
          } else {
            response['more_info']["artistMap"]['artists'].forEach((element) {
              artistNames.add(element["name"]);
            });
          }
        } else {
          response['more_info']["artistMap"]['featured_artists']
              .forEach((element) {
            artistNames.add(element["name"]);
          });
        }
      } else {
        response['more_info']["artistMap"]['primary_artists']
            .forEach((element) {
          artistNames.add(element["name"]);
        });
      }

      Map info = {
        "id": response["id"],
        "type": response["type"],
        "album": response["title"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "year": response["year"],
        "language": capitalize(response["language"].toString()),
        "genre": capitalize(response["language"].toString()),
        "album_id": response["id"],
        "subtitle": "${response["subtitle"]}"
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\""),
        "title": response['title']
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "artist": artistNames
            .join(", ")
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            .trim(),
        "image": response["image"]
            .toString()
            .replaceAll("150x150", "500x500")
            .replaceAll('50x50', "500x500")
            .replaceAll('http:', 'https:'),
      };
      return info;
    } catch (e) {
      return {"Error": e};
    }
  }

  // Future<List> formatArtistSinglesResponse(List response) async {
  // List result = [];
  // return result;
  // }

  // Future<List> formatArtistLatestReleaseResponse(List response) async {
  //   List result = [];
  //   return result;
  // }

  // Future<List> formatArtistDedicatedArtistPlaylistResponse(
  //     List response) async {
  //   List result = [];
  //   return result;
  // }

  // Future<List> formatArtistFeaturedArtistPlaylistResponse(List response) async {
  //   List result = [];
  //   return result;
  // }

  Future<Map> formatHomePageData(Map data) async {
    final trendingData = data["new_trending"];
    if (trendingData.isNotEmpty) {
      for (int i = 0; i < trendingData.length; i++) {
        if (trendingData[i]["type"] == "song") {
          data["new_trending"][i] =
              await formatSingleSongResponse(trendingData[i]);
        }
      }
    }
    return data;
  }
}
