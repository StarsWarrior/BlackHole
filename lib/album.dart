import 'package:blackhole/miniplayer.dart';
import 'package:blackhole/songs.dart';
import 'package:flutter/material.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audiotagger/audiotagger.dart';
import 'dart:io';

class AlbumSongs extends StatefulWidget {
  final String data;
  final String type;
  AlbumSongs({Key key, @required this.data, @required this.type})
      : super(key: key);
  @override
  _AlbumSongsState createState() => _AlbumSongsState();
}

class _AlbumSongsState extends State<AlbumSongs> {
  List<FileSystemEntity> _files;
  Map<String, List<Map>> _albums = {};
  List sortedAlbumKeysList;
  bool added = false;
  bool processStatus = false;
  int sortValue = Hive.box('settings').get('albumSortValue');

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
      String temp = widget.type == 'all'
          ? await ExtStorage.getExternalStorageDirectory()
          : await ExtStorage.getExternalStoragePublicDirectory(
              ExtStorage.DIRECTORY_MUSIC);
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
          var xyz = await entity.stat();
          var finalTag;
          if (widget.data == 'album') {
            finalTag = tags.album;
          }
          if (widget.data == 'artist') {
            finalTag = tags.artist;
          }
          (finalTag == null || finalTag.trim() == '')
              ? finalTag = 'Unknown'
              : finalTag = finalTag;
          if (_albums.containsKey(finalTag)) {
            List temp = _albums[finalTag];
            temp.add({
              'id': entity.path,
              'image': await tagger.readArtwork(path: entity.path),
              'title': tags.title,
              'artist': tags.artist,
              'album': tags.album,
              'lastModified': xyz.modified,
            });
            _albums.addEntries([MapEntry(finalTag, temp)]);
          } else {
            _albums.addEntries([
              MapEntry(finalTag, [
                {
                  'id': entity.path,
                  'image': await tagger.readArtwork(path: entity.path),
                  'title': tags.title,
                  'artist': tags.artist,
                  'album': tags.album,
                  'lastModified': xyz.modified,
                }
              ])
            ]);
          }
        } catch (e) {}
      }
      added = true;
    }
    sortValue ??= 2;
    if (sortValue == 0) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedAlbumKeysList.sort(
          (a, b) => a.toString().toUpperCase().compareTo(b.toUpperCase()));
    }
    if (sortValue == 1) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedAlbumKeysList.sort((b, a) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
    }
    if (sortValue == 2) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedAlbumKeysList
          .sort((b, a) => _albums[a].length.compareTo(_albums[b].length));
    }
    if (sortValue == 3) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedAlbumKeysList
          .sort((a, b) => _albums[a].length.compareTo(_albums[b].length));
    }
    if (sortValue == 4) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedAlbumKeysList.shuffle();
    }

    processStatus = true;
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
                title: Text(
                    '${(widget.data[0].toUpperCase() + widget.data.substring(1))}s'),
                actions: [
                  PopupMenuButton(
                      icon: Icon(Icons.sort_rounded),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(7.0))),
                      onSelected: (value) {
                        sortValue = value;
                        Hive.box('settings').put('albumSortValue', value);
                        if (sortValue == 0) {
                          sortedAlbumKeysList.sort((a, b) => a
                              .toString()
                              .toUpperCase()
                              .compareTo(b.toString().toUpperCase()));
                        }
                        if (sortValue == 1) {
                          sortedAlbumKeysList.sort((b, a) => a
                              .toString()
                              .toUpperCase()
                              .compareTo(b.toString().toUpperCase()));
                        }
                        if (sortValue == 2) {
                          sortedAlbumKeysList = _albums.keys.toList();
                          sortedAlbumKeysList.sort((b, a) =>
                              _albums[a].length.compareTo(_albums[b].length));
                        }
                        if (sortValue == 3) {
                          sortedAlbumKeysList = _albums.keys.toList();
                          sortedAlbumKeysList.sort((a, b) =>
                              _albums[a].length.compareTo(_albums[b].length));
                        }
                        if (sortValue == 4) {
                          sortedAlbumKeysList.shuffle();
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
                                  Text(
                                    '10-1',
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 3,
                              child: Row(
                                children: [
                                  sortValue == 3
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
                                    '1-10',
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 4,
                              child: Row(
                                children: [
                                  sortValue == 4
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).accentColor),
                              strokeWidth: 5,
                            )),
                      ),
                    )
                  : ListView.builder(
                      physics: BouncingScrollPhysics(),
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      shrinkWrap: true,
                      itemCount: _albums.keys.toList().length,
                      itemBuilder: (context, index) {
                        return sortedAlbumKeysList.length == 0
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
                                        image: AssetImage(
                                            'assets/${widget.data}.png'),
                                      ),
                                      _albums[sortedAlbumKeysList[index]][0]
                                                  ['image'] ==
                                              null
                                          ? SizedBox()
                                          : Image(
                                              image: MemoryImage(_albums[
                                                  sortedAlbumKeysList[
                                                      index]][0]['image']),
                                            )
                                    ],
                                  ),
                                ),
                                title: Text('${sortedAlbumKeysList[index]}'),
                                subtitle: Text(
                                  _albums[sortedAlbumKeysList[index]].length ==
                                          1
                                      ? '${_albums[sortedAlbumKeysList[index]].length} Song'
                                      : '${_albums[sortedAlbumKeysList[index]].length} Songs',
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque: false, // set to false
                                      pageBuilder: (_, __, ___) => SongsList(
                                        data:
                                            _albums[sortedAlbumKeysList[index]],
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
