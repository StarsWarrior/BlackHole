import 'dart:convert';
import 'dart:ui';
import 'package:blackhole/audioplayer.dart';
import 'package:blackhole/format.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'emptyScreen.dart';
import 'miniplayer.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
  bool status = false;
  List searchedList = [];
  bool fetched = false;

  Future<List> fetchResults(searchQuery) async {
    status = true;
    var searchUrl = Uri.https(
      "www.jiosaavn.com",
      "/api.php?p=1&q=" +
          searchQuery +
          "&_format=json&_marker=0&api_version=4&ctx=wap6dot0&n=10&__call=search.getResults",
    );
    var res = await get(searchUrl);
    if (res.statusCode == 200) {
      var getMain = json.decode(res.body);
      List responseList = getMain["results"];
      searchedList = await FormatResponse().formatResponse(responseList);
    }
    fetched = true;
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
              body: !fetched
                  ? Container(
                      child: Center(
                        child: Container(
                            height: MediaQuery.of(context).size.width / 6,
                            width: MediaQuery.of(context).size.width / 6,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).accentColor),
                              strokeWidth: 5,
                            )),
                      ),
                    )
                  : searchedList.length == 0
                      ? EmptyScreen().emptyScreen(context, 0, ":( ", 100,
                          "SORRY", 60, "Results Not Found", 20)
                      : ListView.builder(
                          itemCount: searchedList.length,
                          physics: BouncingScrollPhysics(),
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
                                        borderRadius:
                                            BorderRadius.circular(7.0)),
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
                                subtitle:
                                    Text('${searchedList[index]["subtitle"]}'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque: false,
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
