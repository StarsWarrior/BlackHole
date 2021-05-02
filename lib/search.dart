import 'dart:convert';
import 'dart:ui';
import 'package:blackhole/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'miniplayer.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
  bool status = false;
  List searchedList = [];
  // List searchedArtist = [];

  Future<List> fetchResults(searchQuery) async {
    var searchUrl = Uri.https(
        "www.jiosaavn.com",
        "/api.php?app_version=5.18.3&api_version=4&readable_version=5.18.3&v=79&_format=json&query=" +
            searchQuery +
            "&__call=autocomplete.get");
    var res = await get(searchUrl);
    var resEdited = (res.body).split("-->");
    var getMain = json.decode(resEdited[1]);
    searchedList = getMain["songs"]["data"];
    // searchedArtist = getMain["artists"]["data"];
    // print(searchedList);
    for (int i = 0; i < searchedList.length; i++) {
      searchedList[i]['title'] = searchedList[i]['title']
          .toString()
          .replaceAll("&amp;", "&")
          .replaceAll("&#039;", "'")
          .replaceAll("&quot;", "\"");

      searchedList[i]['more_info']['singers'] = searchedList[i]['more_info']
              ['singers']
          .toString()
          .replaceAll("&amp;", "&")
          .replaceAll("&#039;", "'")
          .replaceAll("&quot;", "\"");

      searchedList[i]['more_info']['primary_artists'] = searchedList[i]
              ['more_info']['primary_artists']
          .toString()
          .replaceAll("&amp;", "&")
          .replaceAll("&#039;", "'")
          .replaceAll("&quot;", "\"");
    }

    // for (int i = 0; i < searchedArtist.length; i++) {
    //   searchedArtist[i]['title'] = searchedArtist[i]['title']
    //       .toString()
    //       .replaceAll("&amp;", "&")
    //       .replaceAll("&#039;", "'")
    //       .replaceAll("&quot;", "\"");

    //   searchedArtist[i]['description'] = searchedArtist[i]['description']
    //       .toString()
    //       .replaceAll("&amp;", "&")
    //       .replaceAll("&#039;", "'")
    //       .replaceAll("&quot;", "\"");
    // }
    status = true;
    print(searchedList);
    return searchedList;
  }

  @override
  Widget build(BuildContext context) {
    query = ModalRoute.of(context).settings.arguments;
    if (!status) {
      fetchResults(query).then((value) => setState(() {}));
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.grey[850],
                  Colors.grey[900],
                  Colors.black,
                ]
              : [
                  Colors.white,
                  Theme.of(context).canvasColor,
                ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text('Results'),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                textTheme: Theme.of(context).textTheme,
                elevation: 0,
                iconTheme: Theme.of(context).iconTheme,
                toolbarHeight: 40,
              ),
              body: !status
                  ? Container(
                      child: Center(
                        child: Container(
                            height: MediaQuery.of(context).size.width / 6,
                            width: MediaQuery.of(context).size.width / 6,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                            )),
                      ),
                    )
                  : ListView.builder(
                      itemCount: searchedList.length,
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 7, 7, 5),
                          child: ListTile(
                            title: Text(
                              '${searchedList[index]["title"].split("(")[0]}',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            leading: Hero(
                              tag: index,
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7.0)),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      '${searchedList[index]["image"].replaceAll('http:', 'https:')}',
                                  placeholder: (context, url) => Image(
                                    image: AssetImage('assets/cover.jpg'),
                                  ),
                                ),
                              ),
                            ),
                            subtitle: Text(
                                '${searchedList[index]["more_info"]["primary_artists"].split("(")[0]}'),
                            onTap: () {
                              // print(searchedList);
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false, // set to false
                                  pageBuilder: (_, __, ___) => PlayScreen(
                                    data: {
                                      'response': searchedList,
                                      'index': index,
                                      'offline': false,
                                    },
                                    fromMiniplayer: false,
                                  ),
                                ),
                              );

                              // Navigator.pushNamed(context, '/play', arguments: {
                              //   'response': searchedList,
                              //   'index': index,
                              //   'offline': false,
                              // });
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
