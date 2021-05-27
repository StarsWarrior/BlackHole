import 'package:des_plugin/des_plugin.dart';

class FormatResponse {
  formatResponse(responseList) async {
    List searchedList = [];
    for (int i = 0; i < responseList.length; i++) {
      try {
        List artist_names = [];
        if (responseList[i]['more_info']["artistMap"]['primary_artists'] ==
                null ||
            responseList[i]['more_info']["artistMap"]['primary_artists']
                    .length ==
                0) {
          if (responseList[i]['more_info']["artistMap"]['featured_artists'] ==
                  null ||
              responseList[i]['more_info']["artistMap"]['featured_artists']
                      .length ==
                  0) {
            if (responseList[i]['more_info']["artistMap"]['artists'] == null ||
                responseList[i]['more_info']["artistMap"]['artists'].length ==
                    0) {
              artist_names.add("Unknown");
            } else {
              responseList[i]['more_info']["artistMap"]['artists']
                  .forEach((element) {
                artist_names.add(element["name"]);
              });
            }
          } else {
            responseList[i]['more_info']["artistMap"]['featured_artists']
                .forEach((element) {
              artist_names.add(element["name"]);
            });
          }
        } else {
          responseList[i]['more_info']["artistMap"]['primary_artists']
              .forEach((element) {
            artist_names.add(element["name"]);
          });
        }

        Map temp = {
          "id": responseList[i]["id"],
          "album": responseList[i]["more_info"]["album"]
              .toString()
              .replaceAll("&amp;", "&")
              .replaceAll("&#039;", "'")
              .replaceAll("&quot;", "\"")
              .split('(')
              .first
              .trim(),
          "year": responseList[i]["year"],
          "duration": responseList[i]["more_info"]["duration"],
          "language": responseList[i]["language"],
          "320kbps": responseList[i]["more_info"]["320kbps"],
          "has_lyrics": responseList[i]["more_info"]["has_lyrics"],
          "lyrics_snippet": responseList[i]["more_info"]["lyrics_snippet"]
              .toString()
              .replaceAll("&amp;", "&")
              .replaceAll("&#039;", "'")
              .replaceAll("&quot;", "\""),
          "release_date": responseList[i]["more_info"]["release_date"],
          "album_id": responseList[i]["more_info"]["album_id"],
          "subtitle": responseList[i]['subtitle']
              .toString()
              .replaceAll("&amp;", "&")
              .replaceAll("&#039;", "'")
              .replaceAll("&quot;", "\""),
          "title": responseList[i]['title']
              .toString()
              .replaceAll("&amp;", "&")
              .replaceAll("&#039;", "'")
              .replaceAll("&quot;", "\"")
              .split('(')
              .first
              .trim(),
          "artist": artist_names
              .join(", ")
              .toString()
              .replaceAll("&amp;", "&")
              .replaceAll("&#039;", "'")
              .replaceAll("&quot;", "\"")
              .trim(),
          "image": responseList[i]["image"]
              .toString()
              .replaceAll("150x150", "500x500")
              .replaceAll('50x50', "500x500")
              .replaceAll('http:', 'https:'),
          "url": await DesPlugin.decrypt(
              "38346591", responseList[i]["more_info"]["encrypted_media_url"])
        };
        searchedList.add(temp);
      } catch (e) {
        print("Error at index $i inside FormatResponse: $e");
      }
    }
    return searchedList;
  }
}
