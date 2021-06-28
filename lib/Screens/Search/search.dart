import 'dart:ui';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Screens/Search/albums.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/APIs/api.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
  bool status = false;
  List searchedList = [];
  List searchedAlbumList = [];
  bool fetched = false;
  bool albumFetched = false;
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    query = ModalRoute.of(context).settings.arguments;
    if (!status) {
      status = true;
      Search().fetchSearchResults(query).then((value) {
        setState(() {
          searchedList = value;
          fetched = true;
        });
      });
      Search().fetchAlbumSearchResults(query).then((value) {
        setState(() {
          searchedAlbumList = value;
          albumFetched = true;
        });
      });
    }
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: NestedScrollView(
                physics: BouncingScrollPhysics(),
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      pinned: true,
                      floating: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      stretch: true,
                      toolbarHeight: 65,
                      title: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          padding: EdgeInsets.only(top: 4, bottom: 0),
                          margin: EdgeInsets.only(left: 8, right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: Theme.of(context).cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5.0,
                                spreadRadius: 0.0,
                                offset: Offset(0.0, 3.0),
                              )
                            ],
                          ),
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    width: 1.5, color: Colors.transparent),
                              ),
                              fillColor: Theme.of(context).accentColor,
                              prefixIcon: IconButton(
                                icon: Icon(Icons.arrow_back_rounded),
                                color: Theme.of(context).accentColor,
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              suffixIcon: Icon(
                                CupertinoIcons.search,
                                color: Theme.of(context).accentColor,
                              ),
                              border: InputBorder.none,
                              hintText: "Songs, artists or podcasts",
                            ),
                            autofocus: false,
                            onSubmitted: (_query) {
                              if (_query.trim() != '') {
                                Navigator.popAndPushNamed(context, '/search',
                                    arguments: _query);
                              }
                              controller.text = '';
                            },
                          ),
                        ),
                      ),
                    )
                  ];
                },
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
                    : (searchedList.isEmpty && searchedAlbumList.isEmpty)
                        ? EmptyScreen().emptyScreen(context, 0, ":( ", 100,
                            "SORRY", 60, "Results Not Found", 20)
                        : (searchedList.isEmpty)
                            ? SizedBox()
                            : SingleChildScrollView(
                                physics: BouncingScrollPhysics(),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          25, 10, 0, 0),
                                      child: Row(
                                        children: [
                                          Text(
                                            'Songs',
                                            style: TextStyle(
                                              color:
                                                  Theme.of(context).accentColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ListView.builder(
                                      itemCount: searchedList.length,
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 7, 7, 5),
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.only(left: 15.0),
                                            title: Text(
                                              '${searchedList[index]["title"]}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            subtitle: Text(
                                                '${searchedList[index]["subtitle"]}'),
                                            leading: Card(
                                              elevation: 8,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0)),
                                              clipBehavior: Clip.antiAlias,
                                              child: CachedNetworkImage(
                                                errorWidget: (context, _, __) =>
                                                    Image(
                                                  image: AssetImage(
                                                      'assets/cover.jpg'),
                                                ),
                                                imageUrl:
                                                    '${searchedList[index]["image"].replaceAll('http:', 'https:')}',
                                                placeholder: (context, url) =>
                                                    Image(
                                                  image: AssetImage(
                                                      'assets/cover.jpg'),
                                                ),
                                              ),
                                            ),
                                            trailing: DownloadButton(
                                              data: searchedList[index],
                                              icon: 'download',
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder: (_, __, ___) =>
                                                      PlayScreen(
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
                                    searchedAlbumList.isEmpty
                                        ? SizedBox()
                                        : Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                25, 30, 0, 0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  'Albums',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .accentColor,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                    ListView.builder(
                                      itemCount: searchedAlbumList.length,
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
                                      itemBuilder: (context, index) {
                                        int count =
                                            searchedAlbumList[index]["count"];
                                        String countText;
                                        (count > 1)
                                            ? countText = '$count Songs'
                                            : countText = '$count Song';
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 7, 7, 5),
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.only(left: 15.0),
                                            title: Text(
                                              '${searchedAlbumList[index]["title"]}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            subtitle: Text(
                                                '$countText\n${searchedAlbumList[index]["subtitle"]}'),
                                            isThreeLine: true,
                                            leading: Card(
                                              elevation: 8,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0)),
                                              clipBehavior: Clip.antiAlias,
                                              child: CachedNetworkImage(
                                                errorWidget: (context, _, __) =>
                                                    Image(
                                                  image: AssetImage(
                                                      'assets/album.png'),
                                                ),
                                                imageUrl:
                                                    '${searchedAlbumList[index]["image"].replaceAll('http:', 'https:')}',
                                                placeholder: (context, url) =>
                                                    Image(
                                                  image: AssetImage(
                                                      'assets/album.png'),
                                                ),
                                              ),
                                            ),
                                            trailing: AlbumDownloadButton(
                                                albumName:
                                                    searchedAlbumList[index]
                                                        ['title'],
                                                albumId:
                                                    searchedAlbumList[index]
                                                        ['id']),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder: (_, __, ___) =>
                                                      AlbumSearchPage(
                                                    albumName:
                                                        searchedAlbumList[index]
                                                            ['title'],
                                                    albumId:
                                                        searchedAlbumList[index]
                                                            ['id'],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
