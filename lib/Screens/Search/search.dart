import 'dart:ui';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/CustomWidgets/GradientContainers.dart';
import 'package:blackhole/Screens/Search/albums.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
        print(value);
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
                                    padding:
                                        const EdgeInsets.fromLTRB(25, 30, 0, 0),
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
                                            '${searchedList[index]["title"].split("(")[0]}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: Text(
                                              '${searchedList[index]["subtitle"]}'),
                                          leading: Card(
                                            elevation: 8,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7.0)),
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
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 7, 7, 5),
                                        child: ListTile(
                                          contentPadding:
                                              EdgeInsets.only(left: 15.0),
                                          title: Text(
                                            '${searchedAlbumList[index]["title"].split("(")[0]}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          ),
                                          subtitle: Text(
                                              '${searchedList[index]["subtitle"]}'),
                                          leading: Card(
                                            elevation: 8,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(7.0)),
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
          MiniPlayer(),
        ],
      ),
    );
  }
}
