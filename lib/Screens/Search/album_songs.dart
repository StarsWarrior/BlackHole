import 'dart:ui';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/APIs/api.dart';

class AlbumSongsSearchPage extends StatefulWidget {
  final String albumName;
  final String albumId;
  final String type;

  AlbumSongsSearchPage({
    Key key,
    @required this.albumId,
    @required this.type,
    this.albumName,
  }) : super(key: key);

  @override
  _AlbumSongsSearchPageState createState() => _AlbumSongsSearchPageState();
}

class _AlbumSongsSearchPageState extends State<AlbumSongsSearchPage> {
  bool status = false;
  List searchedList = [];
  bool fetched = false;

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      switch (widget.type) {
        case 'Songs':
          SaavnAPI().fetchSongSearchResults(widget.albumId, '20').then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
          break;
        case 'Albums':
          SaavnAPI().fetchAlbumSongs(widget.albumId).then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
          break;
        case 'Playlists':
          SaavnAPI().fetchPlaylistSongs(widget.albumId).then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
          break;
        default:
          break;
      }
    }
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(widget.albumName ?? 'Songs'),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                textTheme: Theme.of(context).textTheme,
                elevation: 0,
                iconTheme: Theme.of(context).iconTheme,
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
                  : searchedList.isEmpty
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
                                contentPadding: EdgeInsets.only(left: 15.0),
                                title: Text(
                                  '${searchedList[index]["title"]}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '${searchedList[index]["subtitle"]}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                leading: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7.0)),
                                  clipBehavior: Clip.antiAlias,
                                  child: CachedNetworkImage(
                                    errorWidget: (context, _, __) => Image(
                                      image: AssetImage('assets/cover.jpg'),
                                    ),
                                    imageUrl:
                                        '${searchedList[index]["image"].replaceAll('http:', 'https:')}',
                                    placeholder: (context, url) => Image(
                                      image: AssetImage('assets/cover.jpg'),
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
