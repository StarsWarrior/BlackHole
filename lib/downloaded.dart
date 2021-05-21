import 'package:blackhole/miniplayer.dart';
import 'package:blackhole/songs.dart';
import 'package:flutter/material.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audiotagger/audiotagger.dart';
import 'dart:io';

import 'audioplayer.dart';

class DownloadedSongs extends StatefulWidget {
  @override
  _DownloadedSongsState createState() => _DownloadedSongsState();
}

class _DownloadedSongsState extends State<DownloadedSongs> {
  List<FileSystemEntity> _files;
  List _songs = [];
  bool added = false;
  int sortValue = Hive.box('settings').get('sortValue');

  void getDownloaded() async {
    final tagger = Audiotagger();
    var status = await Permission.storage.status;
    if (status.isRestricted || status.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      debugPrint(statuses[Permission.storage].toString());
    }
    status = await Permission.storage.status;
    if (status.isGranted) {
      print('permission granted');
    } else {
      print('permission NOT granted');
    }
    try {
      String temp = await ExtStorage.getExternalStorageDirectory();
      Directory dir = Directory('$temp');
      _files = dir.listSync(recursive: true, followLinks: false);
    } catch (e) {
      String temp2 = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_MUSIC);
      Directory dir = Directory('$temp2');
      _files = dir.listSync(recursive: true, followLinks: false);
    }

    for (FileSystemEntity entity in _files) {
      if (entity.path.endsWith('.mp3') || entity.path.endsWith('.m4a')) {
        try {
          final tags = await tagger.readTags(path: entity.path);
          FileStat stats = await entity.stat();
          if (stats.size < 1048576) {
            print("Size of mediaItem found less than 1 MB");
            debugPrint("Ignoring media");
          } else {
            _songs.add({
              'id': entity.path,
              'image': await tagger.readArtwork(path: entity.path),
              'title': tags.title,
              'artist': tags.artist,
              'album': tags.album,
              'lastModified': stats.modified,
            });
          }
        } catch (e) {}
      }
    }

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

    added = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!added) {
      getDownloaded();
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
                          ]),
                ],
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).accentColor,
                elevation: 0,
              ),
              body: !added
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
                                trailing: PopupMenuButton(
                                  icon: Icon(Icons.more_vert_rounded),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0))),
                                  onSelected: (value) async {
                                    try {
                                      File(_songs[index]['id']).delete();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          elevation: 6,
                                          backgroundColor: Colors.grey[900],
                                          behavior: SnackBarBehavior.floating,
                                          content: Text(
                                            'Deleted ${_songs[index]['id']}',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          action: SnackBarAction(
                                            textColor:
                                                Theme.of(context).accentColor,
                                            label: 'Ok',
                                            onPressed: () {},
                                          ),
                                        ),
                                      );
                                      _songs.remove(_songs[index]);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          elevation: 6,
                                          backgroundColor: Colors.grey[900],
                                          behavior: SnackBarBehavior.floating,
                                          content: Text(
                                            'Failed to delete ${_songs[index]['id']}',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          action: SnackBarAction(
                                            textColor:
                                                Theme.of(context).accentColor,
                                            label: 'Ok',
                                            onPressed: () {},
                                          ),
                                        ),
                                      );
                                    }
                                    setState(() {});
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete),
                                          Spacer(),
                                          Text('Delete'),
                                          Spacer(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
