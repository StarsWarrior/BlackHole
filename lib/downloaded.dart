import 'package:blackhole/miniplayer.dart';
import 'package:blackhole/songs.dart';
import 'package:flutter/material.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audiotagger/audiotagger.dart';
import 'dart:io';

class DownloadedSongs extends StatefulWidget {
  @override
  _DownloadedSongsState createState() => _DownloadedSongsState();
}

class _DownloadedSongsState extends State<DownloadedSongs> {
  List<FileSystemEntity> _files;
  List _songs = [];
  bool added = false;

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
    var temp = await ExtStorage.getExternalStorageDirectory();
    Directory dir = Directory('$temp');
    try {
      _files = dir.listSync(recursive: true, followLinks: false);
    } catch (e) {
      var temp2 = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_MUSIC);
      Directory dir = Directory('$temp2');
      _files = dir.listSync(recursive: true, followLinks: false);
    }

    for (FileSystemEntity entity in _files) {
      if (entity.path.endsWith('.mp3') || entity.path.endsWith('.m4a')) {
        try {
          final tags = await tagger.readTags(path: entity.path);
          var xyz = await entity.stat();
          _songs.add({
            'id': entity.path,
            'image': await tagger.readArtwork(path: entity.path),
            'title': tags.title,
            'artist': tags.artist,
            'album': tags.album,
            'lastModified': xyz.modified,
          });
        } catch (e) {}
      }
      added = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!added) {
      getDownloaded();
    }
    return !added
        ? Container(
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
            child: Column(children: [
              Expanded(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    title: Text('Songs'),
                    actions: [
                      PopupMenuButton(
                          icon: Icon(Icons.sort_rounded),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(7.0))),
                          onSelected: (value) {},
                          itemBuilder: (context) => []),
                    ],
                    centerTitle: true,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.transparent
                            : Theme.of(context).accentColor,
                    elevation: 0,
                  ),
                  body: Container(
                    child: Center(
                      child: Container(
                          height: MediaQuery.of(context).size.width / 6,
                          width: MediaQuery.of(context).size.width / 6,
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                          )),
                    ),
                  ),
                ),
              ),
              MiniPlayer()
            ]))
        : SongsList(data: _songs);
  }
}
