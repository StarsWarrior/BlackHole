import 'package:blackhole/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'miniplayer.dart';

class LikedSongs extends StatefulWidget {
  final String playlistName;
  LikedSongs({Key key, @required this.playlistName}) : super(key: key);
  @override
  _LikedSongsState createState() => _LikedSongsState();
}

class _LikedSongsState extends State<LikedSongs> {
  Box likedBox;

  // @override
  // void initState() {
  //   super.initState();
  //   Hive.openBox(widget.playlistName);
  // }

  void getLiked() {
    // Future<Directory> document = getApplicationDocumentsDirectory();
    // document.then((value) => Hive.init(value.path));
    likedBox = Hive.box(widget.playlistName);
    // print(likedBox.values);
    // likedBox.deleteFromDisk();
    // setState(() {});
  }

  void deleteLiked(index) {
    likedBox.deleteAt(index);
  }

  @override
  Widget build(BuildContext context) {
    getLiked();
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
                title: Text(widget.playlistName[0].toUpperCase() +
                    widget.playlistName.substring(1)),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).accentColor,
                elevation: 0,
              ),
              body: ListView(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                // mainAxisSize: MainAxisSize.max,
                children: [
                  Dismissible(
                    key: Key('header'),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(30, 0, 30, 20),
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                      decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[700],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(13))),
                      child: Center(
                          child: Text(
                              "Swipe right to remove from ${widget.playlistName}")),
                    ),
                  ),
                  ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: likedBox.length,
                      itemBuilder: (context, index) {
                        return Dismissible(
                          direction: DismissDirection.startToEnd,
                          background: Container(
                            color: Colors.red,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 20.0, right: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    Icons.delete,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          key: Key(likedBox.getAt(index)['id']),
                          child: ListTile(
                            leading: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7.0),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: likedBox
                                    .getAt(index)['image']
                                    .replaceAll('http:', 'https:'),
                                placeholder: (context, url) => Image(
                                  image: AssetImage('assets/cover.jpg'),
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  opaque: false, // set to false
                                  pageBuilder: (_, __, ___) => PlayScreen(
                                    data: {
                                      'index': index,
                                      'response': likedBox.values.toList(),
                                      'offline': false,
                                    },
                                    fromMiniplayer: false,
                                  ),
                                ),
                              );

                              // Navigator.pushNamed(context, '/play', arguments: {
                              //   'index': index,
                              //   'response': likedBox.values.toList(),
                              //   'offline': false,
                              // }
                              // );
                            },
                            title: Text(
                              '${likedBox.getAt(index)['title'].split("(")[0]}',
                            ),
                            subtitle: Text(
                              '${likedBox.getAt(index)['artist'] != null ? likedBox.getAt(index)['artist'].split("(")[0] : 'Artist name'}',
                            ),
                          ),
                          onDismissed: (direction) {
                            setState(() {
                              deleteLiked(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                elevation: 6,
                                backgroundColor: Colors.grey[900],
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'Removed from ${widget.playlistName}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                action: SnackBarAction(
                                  textColor: Theme.of(context).accentColor,
                                  label: 'Ok',
                                  onPressed: () {},
                                ),
                              ),
                            );
                          },
                        );
                      }),
                ],
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
