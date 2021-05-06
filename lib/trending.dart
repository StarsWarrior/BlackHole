import 'package:blackhole/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'dart:convert';

List playlists = [
  {
    "id": "RecentlyPlayed",
    "title": "RecentlyPlayed",
    "image": "",
    "songsList": [],
    "type": ""
  }
];
bool fetched = false;

class TrendingPage extends StatefulWidget {
  @override
  _TrendingPageState createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  var recentList = Hive.box('recent').get('recentlyPlayed');
  List preferredLanguage =
      Hive.box('settings').get('preferredLanguage') ?? ['Hindi'];

  Future<List> trendingSongs(index) async {
    List topSongsList = [];
    var topSongsUrl = Uri.https("www.jiosaavn.com",
        "/api.php?__call=webapi.get&token=${playlists[index]["id"]}&type=playlist&p=1&n=20&includeMetaTags=0&ctx=web6dot0&api_version=4&_format=json&_marker=0");
    var songsListJSON =
        await get(topSongsUrl, headers: {"Accept": "application/json"});
    var songsList = json.decode(songsListJSON.body);
    // print(songsList);
    playlists[index]["title"] = songsList["title"];
    playlists[index]["image"] = songsList["image"];
    topSongsList = songsList["list"];
    for (int i = 0; i < topSongsList.length; i++) {
      try {
        topSongsList[i]['title'] = topSongsList[i]['title']
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"");
        try {
          if (topSongsList[i]["more_info"]["artistMap"]["primary_artists"]
                  .length ==
              0) {
            topSongsList[i]["more_info"]["artistMap"]["primary_artists"] =
                topSongsList[i]["more_info"]["artistMap"]["featured_artists"];
          }
          topSongsList[i]["more_info"]["artistMap"]["primary_artists"][0]
              ["name"] = topSongsList[i]["more_info"]["artistMap"]
                  ["primary_artists"][0]["name"]
              .toString()
              .replaceAll("&amp;", "&")
              .replaceAll("&#039;", "'")
              .replaceAll("&quot;", "\"");
        } catch (e) {
          topSongsList[i]["more_info"]["artistMap"]["primary_artists"] = [
            {"name": ""}
          ];
        }

        topSongsList[i]['image'] = topSongsList[i]['image']
            .toString()
            .replaceAll("150x150", "500x500");
        topSongsList[i]['subtitle'] = topSongsList[i]['subtitle']
            .toString()
            .replaceAll("&amp;", "&")
            .replaceAll("&#039;", "'")
            .replaceAll("&quot;", "\"");
      } catch (e) {
        print("Error in index $i : $e");
      }
    }
    // print(topSongsList);

    playlists[index]["songsList"] = topSongsList;
    setState(() {});
    return topSongsList;
  }

  fetchfun() async {
    final dbRef = FirebaseDatabase.instance.reference().child("Playlists");
    for (int a = 0; a < preferredLanguage.length; a++) {
      await dbRef
          .child(preferredLanguage[a])
          .once()
          .then((DataSnapshot snapshot) {
        playlists.addAll(snapshot.value);
      });
    }
  }

  fetchfun2() async {
    await fetchfun();
    for (int i = 1; i < playlists.length; i++) {
      try {
        await trendingSongs(i);
      } catch (e) {
        print("Error in Index $i in TrendingList: $e");
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!fetched) {
      fetchfun2();
      fetched = true;
    }
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.width,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  height: 250,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.width / 6,
                  width: MediaQuery.of(context).size.width / 6,
                  child: playlists.length == 0
                      ? CircularProgressIndicator(
                          strokeWidth: 5,
                        )
                      : SizedBox(),
                ),
              ],
            ),
          ),
        ),
        ListView.builder(
            physics: BouncingScrollPhysics(), //NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
            scrollDirection: Axis.vertical,
            itemCount: playlists.length,
            itemBuilder: (context, idx) {
              if (idx == 0) {
                return (recentList == null)
                    ? SizedBox()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 10, 0, 5),
                                child: Text(
                                  'Last Session',
                                  style: TextStyle(
                                    color: Theme.of(context).accentColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                              itemCount: recentList.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  child: SizedBox(
                                    width: 150,
                                    child: Column(
                                      children: [
                                        Card(
                                          elevation: 5,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: CachedNetworkImage(
                                            imageUrl: recentList[index]["image"]
                                                .replaceAll('http:', 'https:'),
                                            placeholder: (context, url) =>
                                                Image(
                                              image: AssetImage(
                                                  'assets/cover.jpg'),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${recentList[index]["title"].split("(")[0]}',
                                          textAlign: TextAlign.center,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${recentList[index]["artist"].split("(")[0]}',
                                          textAlign: TextAlign.center,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  .color),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (_, __, ___) =>
                                                PlayScreen(
                                                  data: {
                                                    'response': recentList,
                                                    'index': index,
                                                    'offline': false,
                                                  },
                                                  fromMiniplayer: false,
                                                )));
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                        child: Text(
                          '${(playlists[idx]["title"])}',
                          style: TextStyle(
                            color: Theme.of(context).accentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 200,
                    child: playlists[idx]["songsList"] == null
                        ? SizedBox()
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                            itemCount: playlists[idx]["songsList"].length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                child: SizedBox(
                                  width: 150,
                                  child: Column(
                                    children: [
                                      Card(
                                        elevation: 5,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: CachedNetworkImage(
                                          imageUrl: playlists[idx]["songsList"]
                                                  [index]["image"]
                                              .replaceAll('http:', 'https:'),
                                          placeholder: (context, url) => Image(
                                            image:
                                                AssetImage('assets/cover.jpg'),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${playlists[idx]["songsList"][index]["title"].split("(")[0]}',
                                        textAlign: TextAlign.center,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                        // style: TextStyle(
                                        //     color: Theme.of(context).accentColor),
                                      ),
                                      Text(
                                        '${playlists[idx]["songsList"][index]["more_info"]["artistMap"]["primary_artists"][0]["name"].split("(")[0]}',
                                        textAlign: TextAlign.center,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .caption
                                                .color),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (_, __, ___) => PlayScreen(
                                        data: {
                                          'response': playlists[idx]
                                              ["songsList"],
                                          'index': index,
                                          'offline': false,
                                        },
                                        fromMiniplayer: false,
                                      ),
                                    ),
                                  );

                                  // Navigator.pushNamed(
                                  //   context,
                                  //   '/play',
                                  //   arguments: {
                                  //     'response': playlists[tokens[idx]]["songsList"],
                                  //     'index': index,
                                  //     'offline': false,
                                  //   },
                                  // );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            }),
      ],
    );
  }
}
