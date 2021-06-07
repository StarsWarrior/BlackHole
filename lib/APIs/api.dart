import 'dart:convert';
import 'package:http/http.dart';
import 'package:blackhole/Helpers/format.dart';

class Search {
  Future<List> fetchSearchResults(String searchQuery) async {
    List searchedList = [];
    Uri searchUrl = Uri.https(
      "www.jiosaavn.com",
      "/api.php?p=1&q=" +
          searchQuery +
          "&_format=json&_marker=0&api_version=4&ctx=wap6dot0&n=10&__call=search.getResults",
    );
    final res = await get(searchUrl);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List responseList = getMain["results"];
      searchedList = await FormatResponse().formatResponse(responseList);
    }
    return searchedList;
  }

  Future<List> fetchTopSearchResult(String searchQuery) async {
    List searchedList = [];
    Uri searchUrl = Uri.https(
      "www.jiosaavn.com",
      "/api.php?p=1&q=" +
          searchQuery +
          "&_format=json&_marker=0&api_version=4&ctx=wap6dot0&n=10&__call=search.getResults",
    );
    final res = await get(searchUrl);
    if (res.statusCode == 200) {
      final getMain = json.decode(res.body);
      List responseList = getMain["results"];
      searchedList
          .add(await FormatResponse().formatSingleResponse(responseList[0]));
    }
    return searchedList;
  }
}

class Playlist {
  Future<Map> fetchPlaylistSongs(Map item) async {
    Uri playlistUrl = Uri.https("www.jiosaavn.com",
        "/api.php?__call=webapi.get&token=${item["id"]}&type=playlist&p=1&n=20&includeMetaTags=0&ctx=web6dot0&api_version=4&_format=json&_marker=0");
    // print(playlistUrl);
    final res = await get(playlistUrl, headers: {"Accept": "application/json"});
    final playlist = json.decode(res.body);
    if (res.statusCode == 200) {
      item["title"] = playlist["title"];
      item["image"] = playlist["image"];
      item["songsList"] =
          await FormatResponse().formatResponse(playlist["list"]);
    }
    return item;
  }
}
