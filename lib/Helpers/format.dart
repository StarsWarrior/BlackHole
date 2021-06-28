import 'package:des_plugin/des_plugin.dart';

class FormatResponse {
  Future<List> formatResponse(List responseList) async {
    List searchedList = [];
    for (int i = 0; i < responseList.length; i++) {
      Map response = await formatSingleResponse(responseList[i]);
      if (response.containsKey('Error')) {
        print("Error at index $i inside FormatResponse: ${response['Error']}");
      } else {
        searchedList.add(response);
      }
    }
    return searchedList;
  }

  Future<List> formatAlbumSongsResponse(List responseList) async {
    List searchedList = [];
    for (int i = 0; i < responseList.length; i++) {
      Map response = await formatSingleAlbumSongResponse(responseList[i]);
      if (response.containsKey('Error')) {
        print(
            "Error at index $i inside FormatAlbumSongsResponse: ${response['Error']}");
      } else {
        searchedList.add(response);
      }
    }
    return searchedList;
  }

  Future<Map> formatSingleAlbumSongResponse(Map response) async {
    try {
      List artistNames = [];
      if (response['primary_artists'] == null ||
          response['primary_artists'].toString().trim() == '') {
        if (response['featured_artists'] == null ||
            response['featured_artists'].toString().trim() == '') {
          artistNames.add("Unknown");
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

  Future<List> formatAlbumResponse(List responseList) async {
    List searchedAlbumList = [];
    for (int i = 0; i < responseList.length; i++) {
      Map response = await formatSingleAlbumResponse(responseList[i]);
      if (response.containsKey('Error')) {
        print(
            "Error at index $i inside FormatAlbumResponse: ${response['Error']}");
      } else {
        searchedAlbumList.add(response);
      }
    }
    return searchedAlbumList;
  }

  String capitalize(String msg) {
    return "${msg[0].toUpperCase()}${msg.substring(1)}";
  }

  Future<Map> formatSingleResponse(Map response) async {
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
      return info;
    } catch (e) {
      return {"Error": e};
    }
  }

  Future<Map> formatSingleAlbumResponse(Map response) async {
    try {
      Map info = {
        "id": response["id"],
        "album": response["title"]
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"")
            // .split('(')
            // .first
            .trim(),
        "year": response["more_info"]["year"],
        "language": capitalize(response["more_info"]["language"].toString()),
        "genre": capitalize(response["more_info"]["language"].toString()),
        "album_id": response["id"],
        "subtitle": response["description"]
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
        "artist": response["music"]
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
        "count":
            response["more_info"]["song_pids"].toString().split(", ").length,
        "songs_pids": response["more_info"]["song_pids"].toString().split(", "),
      };
      return info;
    } catch (e) {
      return {"Error": e};
    }
  }
}
