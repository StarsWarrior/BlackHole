import 'package:blackhole/APIs/api.dart';
import 'package:des_plugin/des_plugin.dart';

class FormatResponse {
  String capitalize(String msg) {
    return "${msg[0].toUpperCase()}${msg.substring(1)}";
  }

  String formatString(String text) {
    return text
        .toString()
        .replaceAll("&amp;", "&")
        .replaceAll("&#039;", "'")
        .replaceAll("&quot;", "\"")
        .trim();
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
        "album": formatString(response["more_info"]["album"]),
        // .split('(')
        // .first
        "year": response["year"],
        "duration": response["more_info"]["duration"],
        "language": capitalize(response["language"].toString()),
        "genre": capitalize(response["language"].toString()),
        "320kbps": response["more_info"]["320kbps"],
        "has_lyrics": response["more_info"]["has_lyrics"],
        "lyrics_snippet": formatString(response["more_info"]["lyrics_snippet"]),
        "release_date": response["more_info"]["release_date"],
        "album_id": response["more_info"]["album_id"],
        "subtitle": formatString(response['subtitle']),
        "title": formatString(response['title']),
        // .split('(')
        // .first
        "artist": formatString(artistNames.join(", ")),
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
        "album": formatString(response["album"]),
        // .split('(')
        // .first
        "year": response["year"],
        "duration": response["duration"],
        "language": capitalize(response["language"].toString()),
        "genre": capitalize(response["language"].toString()),
        "320kbps": response["320kbps"],
        "has_lyrics": response["has_lyrics"],
        "lyrics_snippet": formatString(response["lyrics_snippet"]),
        "release_date": response["release_date"],
        "album_id": response["album_id"],
        "subtitle": formatString(
            "${response['primary_artists'].toString().trim()} - ${response['album'].toString().trim()}"),
        "title": formatString(response['song']),
        // .split('(')
        // .first
        "artist": formatString(artistNames.join(", ")),
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
        "album": formatString(response["title"]),
        // .split('(')
        // .first
        "year": response["more_info"]["year"] ?? response["year"],
        "language": capitalize(response["more_info"]["language"] == null
            ? response["language"].toString()
            : response["more_info"]["language"].toString()),
        "genre": capitalize(response["more_info"]["language"] == null
            ? response["language"].toString()
            : response["more_info"]["language"].toString()),
        "album_id": response["id"],
        "subtitle": response["description"] == null
            ? formatString(response["subtitle"])
            : formatString(response["description"]),
        "title": formatString(response['title']),
        // .split('(')
        // .first
        "artist": response["music"] == null
            ? response["more_info"]["music"] == null
                ? response["more_info"]["artistMap"]["primary_artists"] == null
                    ? ''
                    : formatString(response["more_info"]["artistMap"]
                        ["primary_artists"][0]["name"])
                : formatString(response["more_info"]["music"])
            : formatString(response["music"]),
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
        "album": formatString(response["title"]),
        "language": capitalize(response["language"] == null
            ? response["more_info"]["language"].toString()
            : response["language"].toString()),
        "genre": capitalize(response["language"] == null
            ? response["more_info"]["language"].toString()
            : response["language"].toString()),
        "playlistId": response["id"],
        "subtitle": response["description"] == null
            ? formatString(response["subtitle"])
            : formatString(response["description"]),
        "title": formatString(response['title']),
        // .split('(')
        // .first
        "artist": formatString(response["extra"]),
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
            ? formatString(response['name'])
            : formatString(response['title']),
        "language": capitalize(response["language"].toString()),
        "genre": capitalize(response["language"].toString()),
        "artistId": response["id"],
        "artistToken": response["url"] == null
            ? response["perma_url"].toString().split('/').last
            : response["url"].toString().split('/').last,
        "subtitle": response["description"] == null
            ? capitalize(response["role"])
            : formatString(response["description"]),
        "title": response['title'] == null
            ? formatString(response['name'])
            : formatString(response['title']),
        // .split('(')
        // .first

        "artist": formatString(response["title"]),
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
        "album": formatString(response["title"]),
        // .split('(')
        // .first
        "year": response["year"],
        "language": capitalize(response["language"].toString()),
        "genre": capitalize(response["language"].toString()),
        "album_id": response["id"],
        "subtitle": formatString(response["subtitle"]),
        "title": formatString(response['title']),
        // .split('(')
        // .first
        "artist": formatString(artistNames.join(", ")),
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
    try {
      data["new_trending"] =
          await formatSongsInList(data["new_trending"], false);
      List promoList = [];
      List promoListTemp = [];
      data["modules"].forEach((k, v) {
        if (k.startsWith('promo')) {
          if (data[k][0]['type'] == 'song' && data[k][0]['mini_obj'] ?? false)
            promoListTemp.add(k.toString());
          else
            promoList.add(k.toString());
        }
      });
      for (int i = 0; i < promoList.length; i++) {
        data[promoList[i]] = await formatSongsInList(data[promoList[i]], false);
      }
      data["collections"] = [
        "new_trending",
        "charts",
        "new_albums",
        "top_playlists",
        // "city_mod",
        // "artist_recos",
        ...promoList
      ];
      data['collections_temp'] = promoListTemp;
    } catch (err) {
      print(err);
    }
    return data;
  }

  Future<Map> formatPromoLists(Map data) async {
    try {
      List promoList = data['collections_temp'];
      for (int i = 0; i < promoList.length; i++) {
        data[promoList[i]] = await formatSongsInList(data[promoList[i]], true);
      }
      data['collections'].addAll(promoList);
      data['collections_temp'] = [];
    } catch (err) {
      print(err);
    }
    return data;
  }

  Future<List> formatSongsInList(List list, bool fetchDetails) async {
    if (list.isNotEmpty) {
      for (int i = 0; i < list.length; i++) {
        Map item = list[i];
        if (item["type"] == "song") {
          if (item["mini_obj"] ?? false) {
            if (fetchDetails)
              list[i] = await SaavnAPI().fetchSongDetails(item['id']);
            continue;
          }
          list[i] = await formatSingleSongResponse(item);
        }
      }
    }
    list.removeWhere((value) => value == null);
    return list;
  }
}
