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
            .split('(')
            .first
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
            .split('(')
            .first
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
      print('Error: $e');
      return {"Error": e};
    }
  }
}
