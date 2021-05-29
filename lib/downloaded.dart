import 'package:audiotagger/models/tag.dart';
import 'package:blackhole/emptyScreen.dart';
import 'package:blackhole/miniplayer.dart';
import 'package:flutter/material.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audiotagger/audiotagger.dart';
import 'dart:io';
import 'audioplayer.dart';
import 'songs.dart';

class DownloadedSongs extends StatefulWidget {
  final String type;
  DownloadedSongs({Key key, @required this.type}) : super(key: key);
  @override
  _DownloadedSongsState createState() => _DownloadedSongsState();
}

class _DownloadedSongsState extends State<DownloadedSongs>
    with SingleTickerProviderStateMixin {
  List<FileSystemEntity> _files;
  Map<String, List<Map>> _albums = {};
  Map<String, List<Map>> _artists = {};
  List sortedAlbumKeysList;
  List sortedArtistKeysList;
  List _songs = [];
  List _videos = [];
  bool added = false;
  int sortValue = Hive.box('settings').get('sortValue');
  int albumSortValue = Hive.box('settings').get('albumSortValue');
  TabController _tcontroller;
  int currentIndex = 0;

  @override
  void initState() {
    _tcontroller =
        TabController(length: widget.type == 'all' ? 4 : 3, vsync: this);
    _tcontroller.addListener(changeTitle); // Registering listener
    super.initState();
  }

  void changeTitle() {
    setState(() {
      currentIndex = _tcontroller.index;
    });
  }

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
            debugPrint("Ignoring media: ${entity.path}");
          } else {
            if (widget.type != 'all' && tags.comment != 'BlackHole') {
              continue;
            }

            String albumTag = tags.album;
            String artistTag = tags.artist;
            (artistTag == null || artistTag.trim() == '')
                ? artistTag = 'Unknown'
                : artistTag = artistTag;

            (albumTag == null || albumTag.trim() == '')
                ? albumTag = 'Unknown'
                : albumTag = albumTag;
            Map data = {
              'id': entity.path,
              'image': await tagger.readArtwork(path: entity.path),
              'title': tags.title,
              'artist': artistTag,
              'album': albumTag,
              'lastModified': stats.modified,
              'genre': tags.genre,
              'year': tags.year,
            };
            _songs.add(data);

            if (_albums.containsKey(albumTag)) {
              List tempAlbum = _albums[albumTag];
              tempAlbum.add(data);
              _albums.addEntries([MapEntry(albumTag, tempAlbum)]);
            } else {
              _albums.addEntries([
                MapEntry(albumTag, [data])
              ]);
            }

            if (_artists.containsKey(artistTag)) {
              List tempArtist = _artists[artistTag];
              tempArtist.add(data);
              _artists.addEntries([MapEntry(artistTag, tempArtist)]);
            } else {
              _artists.addEntries([
                MapEntry(artistTag, [data])
              ]);
            }
          }
        } catch (e) {}
      }

      if (widget.type == 'all' &&
          (entity.path.endsWith('.mp4') ||
              entity.path.endsWith('.mkv') ||
              entity.path.endsWith('.webm'))) {
        try {
          FileStat stats = await entity.stat();
          if (stats.size < 1048576) {
            print("Size of mediaItem found less than 1 MB");
            debugPrint("Ignoring media: ${entity.path}");
          } else {
            Map data = {
              'id': entity.path,
              'image': null,
              'title': entity.path.split('/').last.toString(),
              'artist': '',
              'album': '',
              'lastModified': stats.modified,
              'year': '',
              'genre': '',
            };
            _videos.add(data);
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
      _videos.sort((a, b) => a["id"]
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
      _videos.sort((b, a) => a["id"]
          .split('/')
          .last
          .toUpperCase()
          .compareTo(b["id"].split('/').last.toString().toUpperCase()));
    }
    if (sortValue == 2) {
      _songs.sort((b, a) => a["lastModified"].compareTo(b["lastModified"]));
      _videos.sort((b, a) => a["lastModified"].compareTo(b["lastModified"]));
    }
    if (sortValue == 3) {
      _songs.shuffle();
      _videos.shuffle();
    }
    albumSortValue ??= 2;
    if (albumSortValue == 0) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedArtistKeysList = _artists.keys.toList();
      sortedAlbumKeysList.sort(
          (a, b) => a.toString().toUpperCase().compareTo(b.toUpperCase()));
      sortedArtistKeysList.sort(
          (a, b) => a.toString().toUpperCase().compareTo(b.toUpperCase()));
    }
    if (albumSortValue == 1) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedArtistKeysList = _artists.keys.toList();
      sortedAlbumKeysList.sort((b, a) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
      sortedArtistKeysList.sort((b, a) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
    }
    if (albumSortValue == 2) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedArtistKeysList = _artists.keys.toList();
      sortedAlbumKeysList
          .sort((b, a) => _albums[a].length.compareTo(_albums[b].length));
      sortedArtistKeysList
          .sort((b, a) => _artists[a].length.compareTo(_artists[b].length));
    }
    if (albumSortValue == 3) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedArtistKeysList = _artists.keys.toList();
      sortedAlbumKeysList
          .sort((a, b) => _albums[a].length.compareTo(_albums[b].length));
      sortedArtistKeysList
          .sort((a, b) => _artists[a].length.compareTo(_artists[b].length));
    }
    if (albumSortValue == 4) {
      sortedAlbumKeysList = _albums.keys.toList();
      sortedArtistKeysList = _artists.keys.toList();
      sortedAlbumKeysList.shuffle();
      sortedArtistKeysList.shuffle();
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
            child: DefaultTabController(
              length: widget.type == 'all' ? 4 : 3,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(widget.type == 'all' ? 'My Music' : 'Downloads'),
                  bottom: TabBar(
                    controller: _tcontroller,
                    tabs: widget.type == 'all'
                        ? [
                            Tab(
                              text: 'Songs',
                            ),
                            Tab(
                              text: 'Albums',
                            ),
                            Tab(
                              text: 'Artists',
                            ),
                            Tab(
                              text: 'Videos',
                            )
                          ]
                        : [
                            Tab(
                              text: 'Songs',
                            ),
                            Tab(
                              text: 'Albums',
                            ),
                            Tab(
                              text: 'Artists',
                            ),
                          ],
                  ),
                  actions: [
                    PopupMenuButton(
                        icon: Icon(Icons.sort_rounded),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(7.0))),
                        onSelected: (currentIndex == 0 || currentIndex == 3)
                            ? (value) {
                                sortValue = value;
                                Hive.box('settings').put('sortValue', value);
                                if (sortValue == 0) {
                                  _songs.sort((a, b) => a["id"]
                                      .split('/')
                                      .last
                                      .toUpperCase()
                                      .compareTo(b["id"].split('/').last));
                                  _videos.sort((a, b) => a["id"]
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
                                  _videos.sort((b, a) => a["id"]
                                      .split('/')
                                      .last
                                      .toUpperCase()
                                      .compareTo(b["id"].split('/').last));
                                }
                                if (sortValue == 2) {
                                  _songs.sort((b, a) => a["lastModified"]
                                      .compareTo(b["lastModified"]));
                                  _videos.sort((b, a) => a["lastModified"]
                                      .compareTo(b["lastModified"]));
                                }
                                if (sortValue == 3) {
                                  _songs.shuffle();
                                  _videos.shuffle();
                                }
                                setState(() {});
                              }
                            : (value) {
                                albumSortValue = value;
                                Hive.box('settings')
                                    .put('albumSortValue', value);
                                if (albumSortValue == 0) {
                                  sortedAlbumKeysList.sort((a, b) => a
                                      .toString()
                                      .toUpperCase()
                                      .compareTo(b.toUpperCase()));
                                  sortedArtistKeysList.sort((a, b) => a
                                      .toString()
                                      .toUpperCase()
                                      .compareTo(b.toUpperCase()));
                                }
                                if (albumSortValue == 1) {
                                  sortedAlbumKeysList.sort((b, a) => a
                                      .toString()
                                      .toUpperCase()
                                      .compareTo(b.toString().toUpperCase()));
                                  sortedArtistKeysList.sort((b, a) => a
                                      .toString()
                                      .toUpperCase()
                                      .compareTo(b.toString().toUpperCase()));
                                }
                                if (albumSortValue == 2) {
                                  sortedAlbumKeysList.sort((b, a) => _albums[a]
                                      .length
                                      .compareTo(_albums[b].length));
                                  sortedArtistKeysList.sort((b, a) =>
                                      _artists[a]
                                          .length
                                          .compareTo(_artists[b].length));
                                }
                                if (albumSortValue == 3) {
                                  sortedAlbumKeysList.sort((a, b) => _albums[a]
                                      .length
                                      .compareTo(_albums[b].length));
                                  sortedArtistKeysList.sort((a, b) =>
                                      _artists[a]
                                          .length
                                          .compareTo(_artists[b].length));
                                }
                                if (albumSortValue == 4) {
                                  sortedAlbumKeysList.shuffle();
                                  sortedArtistKeysList.shuffle();
                                }
                                setState(() {});
                              },
                        itemBuilder: (currentIndex == 0 || currentIndex == 3)
                            ? (context) => [
                                  PopupMenuItem(
                                    value: 0,
                                    child: Row(
                                      children: [
                                        sortValue == 0
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
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
                                                color: Theme.of(context)
                                                            .brightness ==
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
                                                color: Theme.of(context)
                                                            .brightness ==
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
                                                color: Theme.of(context)
                                                            .brightness ==
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
                                ]
                            : (context) => [
                                  PopupMenuItem(
                                    value: 0,
                                    child: Row(
                                      children: [
                                        albumSortValue == 0
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
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
                                        albumSortValue == 1
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
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
                                        albumSortValue == 2
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
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
                                        albumSortValue == 3
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
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
                                        albumSortValue == 4
                                            ? Icon(
                                                Icons.shuffle_rounded,
                                                color: Theme.of(context)
                                                            .brightness ==
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
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).accentColor),
                                strokeWidth: 5,
                              )),
                        ),
                      )
                    : TabBarView(
                        controller: _tcontroller,
                        children: widget.type == 'all'
                            ? [
                                songsTab(),
                                albumsTab(),
                                artistsTab(),
                                videosTab(),
                              ]
                            : [
                                songsTab(),
                                albumsTab(),
                                artistsTab(),
                              ]),
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }

  songsTab() {
    return _songs.length == 0
        ? EmptyScreen().emptyScreen(context, 3, "Nothing to ", 15.0,
            "Show Here", 45, "Download Something", 23.0)
        : ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: _songs.length,
            itemBuilder: (context, index) {
              return ListTile(
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
                              image: MemoryImage(_songs[index]['image']),
                            )
                    ],
                  ),
                ),
                title: Text('${_songs[index]['id'].split('/').last}'),
                trailing: PopupMenuButton(
                  icon: Icon(Icons.more_vert_rounded),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(7.0))),
                  onSelected: (value) async {
                    if (value == 0) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          String fileName =
                              _songs[index]['id'].split('/').last.toString();
                          List temp = fileName.split('.');
                          String ext = temp.removeLast();
                          String songName = temp.join('.');
                          final controller =
                              TextEditingController(text: songName);
                          return AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Name',
                                      style: TextStyle(
                                          color: Theme.of(context).accentColor),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                    autofocus: true,
                                    controller: controller,
                                    onSubmitted: (value) async {
                                      try {
                                        Navigator.pop(context);
                                        String newName = _songs[index]['id']
                                            .toString()
                                            .replaceFirst(songName, value);

                                        while (await File(newName).exists()) {
                                          newName = newName.replaceFirst(
                                              value, value + ' (1)');
                                        }

                                        File(_songs[index]['id'])
                                            .rename(newName);
                                        _songs[index]['id'] = newName;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            elevation: 6,
                                            backgroundColor: Colors.grey[900],
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                              'Renamed to ${_songs[index]['id'].split('/').last}',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            action: SnackBarAction(
                                              textColor:
                                                  Theme.of(context).accentColor,
                                              label: 'Ok',
                                              onPressed: () {},
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            elevation: 6,
                                            backgroundColor: Colors.grey[900],
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                              'Failed to Rename ${_songs[index]['id'].split('/').last}',
                                              style: TextStyle(
                                                  color: Colors.white),
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
                                    }),
                              ],
                            ),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[700],
                                  //       backgroundColor: Theme.of(context).accentColor,
                                ),
                                child: Text(
                                  "Cancel",
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.white,
                                  backgroundColor:
                                      Theme.of(context).accentColor,
                                ),
                                child: Text(
                                  "Ok",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  try {
                                    Navigator.pop(context);
                                    String newName = _songs[index]['id']
                                        .toString()
                                        .replaceFirst(
                                            songName, controller.text);

                                    while (await File(newName).exists()) {
                                      newName = newName.replaceFirst(
                                          controller.text,
                                          controller.text + ' (1)');
                                    }

                                    File(_songs[index]['id']).rename(newName);
                                    _songs[index]['id'] = newName;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        elevation: 6,
                                        backgroundColor: Colors.grey[900],
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Renamed to ${_songs[index]['id'].split('/').last}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        action: SnackBarAction(
                                          textColor:
                                              Theme.of(context).accentColor,
                                          label: 'Ok',
                                          onPressed: () {},
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        elevation: 6,
                                        backgroundColor: Colors.grey[900],
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Failed to Rename ${_songs[index]['id'].split('/').last}',
                                          style: TextStyle(color: Colors.white),
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
                              ),
                              SizedBox(
                                width: 5,
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (value == 1) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final _titlecontroller = TextEditingController(
                              text: _songs[index]['title']);
                          final _albumcontroller = TextEditingController(
                              text: _songs[index]['album']);
                          final _artistcontroller = TextEditingController(
                              text: _songs[index]['artist']);
                          return AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Title',
                                      style: TextStyle(
                                          color: Theme.of(context).accentColor),
                                    ),
                                  ],
                                ),
                                TextField(
                                    autofocus: true,
                                    controller: _titlecontroller,
                                    onSubmitted: (value) {}),
                                SizedBox(
                                  height: 30,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Artist',
                                      style: TextStyle(
                                          color: Theme.of(context).accentColor),
                                    ),
                                  ],
                                ),
                                TextField(
                                    autofocus: true,
                                    controller: _artistcontroller,
                                    onSubmitted: (value) {}),
                                SizedBox(
                                  height: 30,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Album',
                                      style: TextStyle(
                                          color: Theme.of(context).accentColor),
                                    ),
                                  ],
                                ),
                                TextField(
                                    autofocus: true,
                                    controller: _albumcontroller,
                                    onSubmitted: (value) {}),
                              ],
                            ),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                                child: Text("Cancel"),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.white,
                                  backgroundColor:
                                      Theme.of(context).accentColor,
                                ),
                                child: Text(
                                  "Ok",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  try {
                                    Navigator.pop(context);
                                    _songs[index]['title'] =
                                        _titlecontroller.text;
                                    _songs[index]['album'] =
                                        _albumcontroller.text;
                                    _songs[index]['artist'] =
                                        _artistcontroller.text;
                                    final tag = Tag(
                                      title: _titlecontroller.text,
                                      artist: _artistcontroller.text,
                                      album: _albumcontroller.text,
                                    );

                                    final tagger = Audiotagger();
                                    await tagger.writeTags(
                                      path: _songs[index]['id'],
                                      tag: tag,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        elevation: 6,
                                        backgroundColor: Colors.grey[900],
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Successfully edited tags',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        action: SnackBarAction(
                                          textColor:
                                              Theme.of(context).accentColor,
                                          label: 'Ok',
                                          onPressed: () {},
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        elevation: 6,
                                        backgroundColor: Colors.grey[900],
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Failed to edit tags',
                                          style: TextStyle(color: Colors.white),
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
                                },
                              ),
                              SizedBox(
                                width: 5,
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (value == 2) {
                      try {
                        File(_songs[index]['id']).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            elevation: 6,
                            backgroundColor: Colors.grey[900],
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Deleted ${_songs[index]['id'].split('/').last}',
                              style: TextStyle(color: Colors.white),
                            ),
                            action: SnackBarAction(
                              textColor: Theme.of(context).accentColor,
                              label: 'Ok',
                              onPressed: () {},
                            ),
                          ),
                        );
                        if (_albums[_songs[index]['album']].length == 1) {
                          sortedAlbumKeysList.remove(_songs[index]['album']);
                        }

                        _albums[_songs[index]['album']].remove(_songs[index]);
                        if (_artists[_songs[index]['artist']].length == 1) {
                          sortedArtistKeysList.remove(_songs[index]['artist']);
                        }

                        _artists[_songs[index]['artist']].remove(_songs[index]);
                        _songs.remove(_songs[index]);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            elevation: 6,
                            backgroundColor: Colors.grey[900],
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Failed to delete ${_songs[index]['id']}',
                              style: TextStyle(color: Colors.white),
                            ),
                            action: SnackBarAction(
                              textColor: Theme.of(context).accentColor,
                              label: 'Ok',
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                      setState(() {});
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded),
                          Spacer(),
                          Text('Rename'),
                          Spacer(),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(Icons.tag_rounded),
                          Spacer(),
                          Text('Edit Tags'),
                          Spacer(),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
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
            });
  }

  albumsTab() {
    return sortedAlbumKeysList.length == 0
        ? EmptyScreen().emptyScreen(context, 3, "Nothing to ", 15.0,
            "Show Here", 45, "Download Something", 23.0)
        : ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedAlbumKeysList.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Image(
                        image: AssetImage('assets/album.png'),
                      ),
                      _albums[sortedAlbumKeysList[index]][0]['image'] == null
                          ? SizedBox()
                          : Image(
                              image: MemoryImage(
                                  _albums[sortedAlbumKeysList[index]][0]
                                      ['image']),
                            )
                    ],
                  ),
                ),
                title: Text('${sortedAlbumKeysList[index]}'),
                subtitle: Text(
                  _albums[sortedAlbumKeysList[index]].length == 1
                      ? '${_albums[sortedAlbumKeysList[index]].length} Song'
                      : '${_albums[sortedAlbumKeysList[index]].length} Songs',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => SongsList(
                        data: _albums[sortedAlbumKeysList[index]],
                      ),
                    ),
                  );
                },
              );
            });
  }

  artistsTab() {
    return sortedArtistKeysList.length == 0
        ? EmptyScreen().emptyScreen(context, 3, "Nothing to ", 15.0,
            "Show Here", 45, "Download Something", 23.0)
        : ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedArtistKeysList.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Image(
                        image: AssetImage('assets/artist.png'),
                      ),
                      _artists[sortedArtistKeysList[index]][0]['image'] == null
                          ? SizedBox()
                          : Image(
                              image: MemoryImage(
                                  _artists[sortedArtistKeysList[index]][0]
                                      ['image']),
                            )
                    ],
                  ),
                ),
                title: Text('${sortedArtistKeysList[index]}'),
                subtitle: Text(
                  _artists[sortedArtistKeysList[index]].length == 1
                      ? '${_artists[sortedArtistKeysList[index]].length} Song'
                      : '${_artists[sortedArtistKeysList[index]].length} Songs',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => SongsList(
                        data: _artists[sortedArtistKeysList[index]],
                      ),
                    ),
                  );
                },
              );
            });
  }

  videosTab() {
    return _videos.length == 0
        ? EmptyScreen().emptyScreen(context, 3, "Nothing to ", 15.0,
            "Show Here", 45, "Download Something", 23.0)
        : ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              return ListTile(
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
                      _videos[index]['image'] == null
                          ? SizedBox()
                          : Image(
                              image: MemoryImage(_videos[index]['image']),
                            )
                    ],
                  ),
                ),
                title: Text('${_videos[index]['id'].split('/').last}'),
                trailing: PopupMenuButton(
                  icon: Icon(Icons.more_vert_rounded),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(7.0))),
                  onSelected: (value) async {
                    if (value == 0) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          String fileName =
                              _videos[index]['id'].split('/').last.toString();
                          List temp = fileName.split('.');
                          String ext = temp.removeLast();
                          String videoName = temp.join('.');
                          final controller =
                              TextEditingController(text: videoName);
                          return AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Name',
                                      style: TextStyle(
                                          color: Theme.of(context).accentColor),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                    autofocus: true,
                                    controller: controller,
                                    onSubmitted: (value) async {
                                      try {
                                        Navigator.pop(context);
                                        String newName = _videos[index]['id']
                                            .toString()
                                            .replaceFirst(videoName, value);

                                        while (await File(newName).exists()) {
                                          newName = newName.replaceFirst(
                                              value, value + ' (1)');
                                        }

                                        File(_videos[index]['id'])
                                            .rename(newName);
                                        _videos[index]['id'] = newName;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            elevation: 6,
                                            backgroundColor: Colors.grey[900],
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                              'Renamed to ${_videos[index]['id'].split('/').last}',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            action: SnackBarAction(
                                              textColor:
                                                  Theme.of(context).accentColor,
                                              label: 'Ok',
                                              onPressed: () {},
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            elevation: 6,
                                            backgroundColor: Colors.grey[900],
                                            behavior: SnackBarBehavior.floating,
                                            content: Text(
                                              'Failed to Rename ${_videos[index]['id'].split('/').last}',
                                              style: TextStyle(
                                                  color: Colors.white),
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
                                    }),
                              ],
                            ),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[700],
                                  //       backgroundColor: Theme.of(context).accentColor,
                                ),
                                child: Text(
                                  "Cancel",
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.white,
                                  backgroundColor:
                                      Theme.of(context).accentColor,
                                ),
                                child: Text(
                                  "Ok",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () async {
                                  try {
                                    Navigator.pop(context);
                                    String newName = _videos[index]['id']
                                        .toString()
                                        .replaceFirst(
                                            videoName, controller.text);

                                    while (await File(newName).exists()) {
                                      newName = newName.replaceFirst(
                                          controller.text,
                                          controller.text + ' (1)');
                                    }

                                    File(_videos[index]['id']).rename(newName);
                                    _videos[index]['id'] = newName;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        elevation: 6,
                                        backgroundColor: Colors.grey[900],
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Renamed to ${_videos[index]['id'].split('/').last}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        action: SnackBarAction(
                                          textColor:
                                              Theme.of(context).accentColor,
                                          label: 'Ok',
                                          onPressed: () {},
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        elevation: 6,
                                        backgroundColor: Colors.grey[900],
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Failed to Rename ${_videos[index]['id'].split('/').last}',
                                          style: TextStyle(color: Colors.white),
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
                              ),
                              SizedBox(
                                width: 5,
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (value == 1) {
                      try {
                        File(_videos[index]['id']).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            elevation: 6,
                            backgroundColor: Colors.grey[900],
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Deleted ${_videos[index]['id'].split('/').last}',
                              style: TextStyle(color: Colors.white),
                            ),
                            action: SnackBarAction(
                              textColor: Theme.of(context).accentColor,
                              label: 'Ok',
                              onPressed: () {},
                            ),
                          ),
                        );
                        _videos.remove(_videos[index]);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            elevation: 6,
                            backgroundColor: Colors.grey[900],
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Failed to delete ${_videos[index]['id']}',
                              style: TextStyle(color: Colors.white),
                            ),
                            action: SnackBarAction(
                              textColor: Theme.of(context).accentColor,
                              label: 'Ok',
                              onPressed: () {},
                            ),
                          ),
                        );
                      }
                      setState(() {});
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded),
                          Spacer(),
                          Text('Rename'),
                          Spacer(),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 1,
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
                          'response': _videos,
                          'index': index,
                          'offline': true
                        },
                        fromMiniplayer: false,
                      ),
                    ),
                  );
                },
              );
            });
  }
}
