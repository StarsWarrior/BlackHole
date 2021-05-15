import 'package:blackhole/audioplayer.dart';
import 'package:blackhole/miniplayer.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SongsList extends StatefulWidget {
  final List data;
  SongsList({Key key, @required this.data}) : super(key: key);
  @override
  _SongsListState createState() => _SongsListState();
}

class _SongsListState extends State<SongsList> {
  List _songs = [];
  bool added = false;
  bool processStatus = false;
  int sortValue = Hive.box('settings').get('sortValue');

  void getSongs() async {
    _songs = widget.data;
    sortValue ??= 2;
    if (sortValue == 0) {
      _songs.sort((a, b) => a["id"]
          .split('/')
          .last
          .toUpperCase()
          .compareTo(b["id"].split('/').last.toString().toUpperCase()));
    }
    if (sortValue == 1) {
      _songs.sort((b, a) => a["id"]
          .split('/')
          .last
          .toUpperCase()
          .compareTo(b["id"].split('/').last.toString().toUpperCase()));
    }
    if (sortValue == 2) {
      _songs.sort((b, a) => a["lastModified"].compareTo(b["lastModified"]));
    }
    if (sortValue == 3) {
      _songs.shuffle();
    }

    processStatus = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!added) {
      getSongs();
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
                title: Text('Songs'),
                actions: [
                  PopupMenuButton(
                      icon: Icon(Icons.sort_rounded),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(7.0))),
                      onSelected: (value) {
                        sortValue = value;
                        Hive.box('settings').put('sortValue', value);
                        if (sortValue == 0) {
                          _songs.sort((a, b) => a["id"]
                              .split('/')
                              .last
                              .toUpperCase()
                              .compareTo(b["id"].split('/').last));
                        }
                        if (sortValue == 1) {
                          _songs.sort((b, a) => a["id"]
                              .split('/')
                              .last
                              .toUpperCase()
                              .compareTo(b["id"].split('/').last));
                        }
                        if (sortValue == 2) {
                          _songs.sort((b, a) =>
                              a["lastModified"].compareTo(b["lastModified"]));
                        }
                        if (sortValue == 3) {
                          _songs.shuffle();
                        }
                        setState(() {});
                      },
                      itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 0,
                              child: Row(
                                children: [
                                  sortValue == 0
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )
                                      : SizedBox(),
                                  SizedBox(width: 10),
                                  Text(
                                    'A-Z',
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 1,
                              child: Row(
                                children: [
                                  sortValue == 1
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )
                                      : SizedBox(),
                                  SizedBox(width: 10),
                                  Text(
                                    'Z-A',
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 2,
                              child: Row(
                                children: [
                                  sortValue == 2
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )
                                      : SizedBox(),
                                  SizedBox(width: 10),
                                  Text('Last Modified'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 3,
                              child: Row(
                                children: [
                                  sortValue == 3
                                      ? Icon(
                                          Icons.shuffle_rounded,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )
                                      : SizedBox(),
                                  SizedBox(width: 10),
                                  Text(
                                    'Shuffle',
                                  ),
                                ],
                              ),
                            ),
                          ])
                ],
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).accentColor,
                elevation: 0,
              ),
              body: !processStatus
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
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      shrinkWrap: true,
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        return _songs.length == 0
                            ? SizedBox()
                            : ListTile(
                                leading: Card(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7.0),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      Image(
                                        image: AssetImage('assets/cover.jpg'),
                                      ),
                                      _songs[index]['image'] == null
                                          ? SizedBox()
                                          : Image(
                                              image: MemoryImage(
                                                  _songs[index]['image']),
                                            )
                                    ],
                                  ),
                                ),
                                title: Text(
                                    '${_songs[index]['id'].split('/').last}'),
                                onTap: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque: false, // set to false
                                      pageBuilder: (_, __, ___) => PlayScreen(
                                        data: {
                                          'response': _songs,
                                          'index': index,
                                          'offline': true
                                        },
                                        fromMiniplayer: false,
                                      ),
                                    ),
                                  );
                                },
                              );
                      }),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
