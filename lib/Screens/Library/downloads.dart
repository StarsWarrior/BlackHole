import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Screens/Library/show_songs.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

class Downloads extends StatefulWidget {
  const Downloads({Key? key}) : super(key: key);
  @override
  _DownloadsState createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads>
    with SingleTickerProviderStateMixin {
  Box downloadsBox = Hive.box('downloads');
  bool added = false;
  List _songs = [];
  final Map<String, List<Map>> _albums = {};
  final Map<String, List<Map>> _artists = {};
  final Map<String, List<Map>> _genres = {};
  List sortedAlbumKeysList = [];
  List sortedArtistKeysList = [];
  List sortedGenreKeysList = [];
  TabController? _tcontroller;
  int currentIndex = 0;
  int sortValue = Hive.box('settings').get('sortValue', defaultValue: 2) as int;
  int albumSortValue =
      Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;

  @override
  void initState() {
    _tcontroller = TabController(length: 4, vsync: this);
    _tcontroller!.addListener(changeTitle);
    getDownloads();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tcontroller!.dispose();
  }

  void changeTitle() {
    setState(() {
      currentIndex = _tcontroller!.index;
    });
  }

  Future<void> downImage(
      String imageFilePath, String songFilePath, String url) async {
    final File file = File(imageFilePath);

    try {
      await file.create();
      final image = await Audiotagger().readArtwork(path: songFilePath);
      if (image != null) {
        file.writeAsBytesSync(image);
      }
    } catch (e) {
      final HttpClientRequest request2 =
          await HttpClient().getUrl(Uri.parse(url));
      final HttpClientResponse response2 = await request2.close();
      final bytes2 = await consolidateHttpClientResponseBytes(response2);
      await file.writeAsBytes(bytes2);
    }
  }

  Future<void> getDownloads() async {
    _songs = downloadsBox.values.toList();
    setArtistAlbum();
  }

  void setArtistAlbum() {
    for (final element in _songs) {
      if (_albums.containsKey(element['album'])) {
        final List<Map> tempAlbum = _albums[element['album']]!;
        tempAlbum.add(element as Map);
        _albums.addEntries([MapEntry(element['album'].toString(), tempAlbum)]);
      } else {
        _albums.addEntries([
          MapEntry(element['album'].toString(), [element as Map])
        ]);
      }

      if (_artists.containsKey(element['artist'])) {
        final List<Map> tempArtist = _artists[element['artist']]!;
        tempArtist.add(element);
        _artists
            .addEntries([MapEntry(element['artist'].toString(), tempArtist)]);
      } else {
        _artists.addEntries([
          MapEntry(element['artist'].toString(), [element])
        ]);
      }

      if (_genres.containsKey(element['genre'])) {
        final List<Map> tempGenre = _genres[element['genre']]!;
        tempGenre.add(element);
        _genres.addEntries([MapEntry(element['genre'].toString(), tempGenre)]);
      } else {
        _genres.addEntries([
          MapEntry(element['genre'].toString(), [element])
        ]);
      }
    }

    sortSongs();

    sortedAlbumKeysList = _albums.keys.toList();
    sortedArtistKeysList = _artists.keys.toList();
    sortedGenreKeysList = _genres.keys.toList();

    sortAlbums();

    added = true;
    setState(() {});
  }

  void sortSongs() {
    if (sortValue == 0) {
      _songs.sort((a, b) => a['title']
          .toString()
          .toUpperCase()
          .compareTo(b['title'].toString().toUpperCase()));
    }
    if (sortValue == 1) {
      _songs.sort((b, a) => a['title']
          .toString()
          .toUpperCase()
          .compareTo(b['title'].toString().toUpperCase()));
    }
    if (sortValue == 2) {
      _songs = downloadsBox.values.toList();
      _songs.sort((b, a) => a['dateAdded']
          .toString()
          .toUpperCase()
          .compareTo(b['dateAdded'].toString().toUpperCase()));
    }
  }

  void sortAlbums() {
    if (albumSortValue == 0) {
      sortedAlbumKeysList.sort((a, b) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
      sortedArtistKeysList.sort((a, b) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
      sortedGenreKeysList.sort((a, b) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
    }
    if (albumSortValue == 1) {
      sortedAlbumKeysList.sort((b, a) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
      sortedArtistKeysList.sort((b, a) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
      sortedGenreKeysList.sort((b, a) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
    }
    if (albumSortValue == 2) {
      sortedAlbumKeysList
          .sort((b, a) => _albums[a]!.length.compareTo(_albums[b]!.length));
      sortedArtistKeysList
          .sort((b, a) => _artists[a]!.length.compareTo(_artists[b]!.length));
      sortedGenreKeysList
          .sort((b, a) => _genres[a]!.length.compareTo(_genres[b]!.length));
    }
    if (albumSortValue == 3) {
      sortedAlbumKeysList
          .sort((a, b) => _albums[a]!.length.compareTo(_albums[b]!.length));
      sortedArtistKeysList
          .sort((a, b) => _artists[a]!.length.compareTo(_artists[b]!.length));
      sortedGenreKeysList
          .sort((a, b) => _genres[a]!.length.compareTo(_genres[b]!.length));
    }
  }

  Future<void> deleteSong(int index) async {
    await downloadsBox.delete(_songs[index]['id']);
    final audioFile = File(_songs[index]['path'].toString());
    final imageFile = File(_songs[index]['image'].toString());
    if (_albums[_songs[index]['album']]!.length == 1) {
      sortedAlbumKeysList.remove(_songs[index]['album']);
    }
    _albums[_songs[index]['album']]!.remove(_songs[index]);

    if (_artists[_songs[index]['artist']]!.length == 1) {
      sortedArtistKeysList.remove(_songs[index]['artist']);
    }
    _artists[_songs[index]['artist']]!.remove(_songs[index]);

    if (_genres[_songs[index]['genre']]!.length == 1) {
      sortedGenreKeysList.remove(_songs[index]['genre']);
    }
    _genres[_songs[index]['genre']]!.remove(_songs[index]);

    _songs.remove(_songs[index]);
    try {
      audioFile.delete();
      if (await imageFile.exists()) {
        imageFile.delete();
      }
      ShowSnackBar().showSnackBar(
        context,
        '${AppLocalizations.of(context)!.deleted} ${_songs[index]['title']}',
      );
    } catch (e) {
      ShowSnackBar().showSnackBar(
        context,
        '${AppLocalizations.of(context)!.failedDelete}: ${audioFile.path}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.downs),
                  centerTitle: true,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Theme.of(context).colorScheme.secondary,
                  elevation: 0,
                  bottom: TabBar(controller: _tcontroller, tabs: [
                    Tab(
                      text: AppLocalizations.of(context)!.songs,
                    ),
                    Tab(
                      text: AppLocalizations.of(context)!.albums,
                    ),
                    Tab(
                      text: AppLocalizations.of(context)!.artists,
                    ),
                    Tab(
                      text: AppLocalizations.of(context)!.genres,
                    ),
                  ]),
                  actions: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.search),
                      tooltip: AppLocalizations.of(context)!.search,
                      onPressed: () {
                        showSearch(
                            context: context,
                            delegate: DownloadsSearch(
                              data: _songs,
                              isDowns: true,
                            ));
                      },
                    ),
                    if (_songs.isNotEmpty)
                      PopupMenuButton(
                          icon: const Icon(Icons.sort_rounded),
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15.0))),
                          onSelected: (currentIndex == 0)
                              ? (int value) {
                                  sortValue = value;
                                  Hive.box('settings').put('sortValue', value);
                                  sortSongs();
                                  setState(() {});
                                }
                              : (int value) {
                                  albumSortValue = value;
                                  Hive.box('settings')
                                      .put('albumSortValue', value);
                                  sortAlbums();
                                  setState(() {});
                                },
                          itemBuilder: (currentIndex == 0)
                              ? (context) => [
                                    PopupMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          if (sortValue == 0)
                                            Icon(
                                              Icons.check_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            )
                                          else
                                            const SizedBox(),
                                          const SizedBox(width: 10),
                                          Text(
                                            AppLocalizations.of(context)!.az,
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 1,
                                      child: Row(
                                        children: [
                                          if (sortValue == 1)
                                            Icon(
                                              Icons.check_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            )
                                          else
                                            const SizedBox(),
                                          const SizedBox(width: 10),
                                          Text(
                                            AppLocalizations.of(context)!.za,
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 2,
                                      child: Row(
                                        children: [
                                          if (sortValue == 2)
                                            Icon(
                                              Icons.check_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            )
                                          else
                                            const SizedBox(),
                                          const SizedBox(width: 10),
                                          Text(AppLocalizations.of(context)!
                                              .lastAdded),
                                        ],
                                      ),
                                    ),
                                  ]
                              : (context) => [
                                    PopupMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          if (albumSortValue == 0)
                                            Icon(
                                              Icons.check_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            )
                                          else
                                            const SizedBox(),
                                          const SizedBox(width: 10),
                                          Text(
                                            AppLocalizations.of(context)!.az,
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 1,
                                      child: Row(
                                        children: [
                                          if (albumSortValue == 1)
                                            Icon(
                                              Icons.check_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            )
                                          else
                                            const SizedBox(),
                                          const SizedBox(width: 10),
                                          Text(
                                            AppLocalizations.of(context)!.za,
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 2,
                                      child: Row(
                                        children: [
                                          if (albumSortValue == 2)
                                            Icon(
                                              Icons.check_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            )
                                          else
                                            const SizedBox(),
                                          const SizedBox(width: 10),
                                          Text(AppLocalizations.of(context)!
                                              .tenToOne),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 3,
                                      child: Row(
                                        children: [
                                          if (albumSortValue == 3)
                                            Icon(
                                              Icons.check_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            )
                                          else
                                            const SizedBox(),
                                          const SizedBox(width: 10),
                                          Text(AppLocalizations.of(context)!
                                              .oneToTen),
                                        ],
                                      ),
                                    ),
                                  ]),
                  ],
                ),
                body: !added
                    ? SizedBox(
                        child: Center(
                          child: SizedBox(
                              height: MediaQuery.of(context).size.width / 7,
                              width: MediaQuery.of(context).size.width / 7,
                              child: const CircularProgressIndicator()),
                        ),
                      )
                    : TabBarView(
                        physics: const CustomPhysics(),
                        controller: _tcontroller,
                        children: [
                          if (_songs.isEmpty)
                            EmptyScreen().emptyScreen(
                                context,
                                3,
                                AppLocalizations.of(context)!.nothingTo,
                                15.0,
                                AppLocalizations.of(context)!.showHere,
                                50,
                                AppLocalizations.of(context)!.downloadSomething,
                                23.0)
                          else
                            ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                shrinkWrap: true,
                                itemCount: _songs.length,
                                itemExtent: 70.0,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: Card(
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: SizedBox(
                                        height: 50.0,
                                        width: 50.0,
                                        child: Image(
                                          fit: BoxFit.cover,
                                          image: FileImage(File(_songs[index]
                                                  ['image']
                                              .toString())),
                                          errorBuilder: (_, __, ___) {
                                            if (_songs[index]['image'] !=
                                                    null &&
                                                _songs[index]['image_url'] !=
                                                    null) {
                                              downImage(
                                                  _songs[index]['image']
                                                      .toString(),
                                                  _songs[index]['path']
                                                      .toString(),
                                                  _songs[index]['image_url']
                                                      .toString());
                                            }
                                            return Image.asset(
                                                'assets/cover.jpg');
                                          },
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        PageRouteBuilder(
                                          opaque: false, // set to false
                                          pageBuilder: (_, __, ___) =>
                                              PlayScreen(
                                            data: {
                                              'index': index,
                                              'response': _songs,
                                              'offline': true,
                                              'downloaded': true,
                                            },
                                            fromMiniplayer: false,
                                          ),
                                        ),
                                      );
                                    },
                                    title: Text(
                                      '${_songs[index]['title']}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${_songs[index]['artist'] ?? 'Artist name'}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PopupMenuButton(
                                            icon: const Icon(
                                                Icons.more_vert_rounded),
                                            shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(15.0))),
                                            itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 0,
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                            Icons.edit_rounded),
                                                        const SizedBox(
                                                            width: 10.0),
                                                        Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .edit),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 1,
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons
                                                            .delete_rounded),
                                                        const SizedBox(
                                                            width: 10.0),
                                                        Text(
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .delete),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                            onSelected: (int? value) async {
                                              if (value == 0) {
                                                _songs[index] = await editTags(
                                                    _songs[index] as Map,
                                                    context);
                                                Hive.box('downloads').put(
                                                    _songs[index]['id'],
                                                    _songs[index]);
                                                setState(() {});
                                              }
                                              if (value == 1) {
                                                setState(() {
                                                  deleteSong(index);
                                                });
                                              }
                                            }),
                                      ],
                                    ),
                                  );
                                }),
                          albumsTab(),
                          artistsTab(),
                          genresTab()
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

  Widget albumsTab() {
    return sortedAlbumKeysList.isEmpty
        ? EmptyScreen().emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            50,
            AppLocalizations.of(context)!.downloadSomething,
            23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedAlbumKeysList.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              return ListTile(
                leading: OfflineCollage(
                  imageList: _albums[sortedAlbumKeysList[index]]!.length >= 4
                      ? _albums[sortedAlbumKeysList[index]]!.sublist(0, 4)
                      : _albums[sortedAlbumKeysList[index]]!.sublist(
                          0, _albums[sortedAlbumKeysList[index]]!.length),
                  placeholderImage: 'assets/album.png',
                ),
                title: Text(
                  '${sortedAlbumKeysList[index]}',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _albums[sortedAlbumKeysList[index]]!.length == 1
                      ? '${_albums[sortedAlbumKeysList[index]]!.length} ${AppLocalizations.of(context)!.song}'
                      : '${_albums[sortedAlbumKeysList[index]]!.length} ${AppLocalizations.of(context)!.songs}',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => SongsList(
                        data: _albums[sortedAlbumKeysList[index]]!,
                        offline: true,
                      ),
                    ),
                  );
                },
              );
            });
  }

  Widget artistsTab() {
    return (sortedArtistKeysList.isEmpty)
        ? EmptyScreen().emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            50,
            AppLocalizations.of(context)!.downloadSomething,
            23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedArtistKeysList.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              return ListTile(
                leading: OfflineCollage(
                  imageList: _artists[sortedArtistKeysList[index]]!.length >= 4
                      ? _artists[sortedArtistKeysList[index]]!.sublist(0, 4)
                      : _artists[sortedArtistKeysList[index]]!.sublist(
                          0, _artists[sortedArtistKeysList[index]]!.length),
                  placeholderImage: 'assets/artist.png',
                ),
                title: Text('${sortedArtistKeysList[index]}',
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  _artists[sortedArtistKeysList[index]]!.length == 1
                      ? '${_artists[sortedArtistKeysList[index]]!.length} ${AppLocalizations.of(context)!.song}'
                      : '${_artists[sortedArtistKeysList[index]]!.length} ${AppLocalizations.of(context)!.songs}',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => SongsList(
                        data: _artists[sortedArtistKeysList[index]]!,
                        offline: true,
                      ),
                    ),
                  );
                },
              );
            });
  }

  Widget genresTab() {
    return (sortedGenreKeysList.isEmpty)
        ? EmptyScreen().emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            50,
            AppLocalizations.of(context)!.downloadSomething,
            23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedGenreKeysList.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              return ListTile(
                leading: OfflineCollage(
                  imageList: _genres[sortedGenreKeysList[index]]!.length >= 4
                      ? _genres[sortedGenreKeysList[index]]!.sublist(0, 4)
                      : _genres[sortedGenreKeysList[index]]!.sublist(
                          0, _genres[sortedGenreKeysList[index]]!.length),
                  placeholderImage: 'assets/album.png',
                ),
                title: Text(
                  '${sortedGenreKeysList[index]}',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _genres[sortedGenreKeysList[index]]!.length == 1
                      ? '${_genres[sortedGenreKeysList[index]]!.length} ${AppLocalizations.of(context)!.song}'
                      : '${_genres[sortedGenreKeysList[index]]!.length} ${AppLocalizations.of(context)!.songs}',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => SongsList(
                        data: _genres[sortedGenreKeysList[index]]!,
                        offline: true,
                      ),
                    ),
                  );
                },
              );
            });
  }
}

Future<Map> editTags(Map song, BuildContext context) async {
  await showDialog(
      context: context,
      builder: (BuildContext context) {
        final tagger = Audiotagger();

        FileImage songImage = FileImage(File(song['image'].toString()));

        final _titlecontroller =
            TextEditingController(text: song['title'].toString());
        final _albumcontroller =
            TextEditingController(text: song['album'].toString());
        final _artistcontroller =
            TextEditingController(text: song['artist'].toString());
        final _albumArtistController =
            TextEditingController(text: song['albumArtist'].toString());
        final _genrecontroller =
            TextEditingController(text: song['genre'].toString());
        final _yearcontroller =
            TextEditingController(text: song['year'].toString());
        final _pathcontroller =
            TextEditingController(text: song['path'].toString());

        return AlertDialog(
          content: SizedBox(
            height: 400,
            width: 300,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final String filePath = await Picker().selectFile(
                          context, ['png', 'jpg', 'jpeg'], 'Pick Image');
                      if (filePath != '') {
                        final _imagePath = filePath;
                        File(_imagePath).copy(song['image'].toString());

                        songImage = FileImage(File(_imagePath));

                        final Tag tag = Tag(
                          artwork: _imagePath,
                        );
                        try {
                          await [
                            Permission.manageExternalStorage,
                          ].request();
                          await tagger.writeTags(
                            path: song['path'].toString(),
                            tag: tag,
                          );
                        } catch (e) {
                          await tagger.writeTags(
                            path: song['path'].toString(),
                            tag: tag,
                          );
                        }
                      }
                    },
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.width / 2,
                        width: MediaQuery.of(context).size.width / 2,
                        child: Image(
                          fit: BoxFit.cover,
                          image: songImage,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.title,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  TextField(
                      autofocus: true,
                      controller: _titlecontroller,
                      onSubmitted: (value) {}),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.artist,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  TextField(
                      autofocus: true,
                      controller: _artistcontroller,
                      onSubmitted: (value) {}),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.albumArtist,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  TextField(
                      autofocus: true,
                      controller: _albumArtistController,
                      onSubmitted: (value) {}),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.album,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  TextField(
                      autofocus: true,
                      controller: _albumcontroller,
                      onSubmitted: (value) {}),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.genre,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  TextField(
                      autofocus: true,
                      controller: _genrecontroller,
                      onSubmitted: (value) {}),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.year,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  TextField(
                      autofocus: true,
                      controller: _yearcontroller,
                      onSubmitted: (value) {}),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.songPath,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                  TextField(
                      autofocus: true,
                      controller: _pathcontroller,
                      onSubmitted: (value) {}),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                primary: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey[700],
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () async {
                Navigator.pop(context);
                song['title'] = _titlecontroller.text;
                song['album'] = _albumcontroller.text;
                song['artist'] = _artistcontroller.text;
                song['albumArtist'] = _albumArtistController.text;
                song['genre'] = _genrecontroller.text;
                song['year'] = _yearcontroller.text;
                song['path'] = _pathcontroller.text;
                final tag = Tag(
                  title: _titlecontroller.text,
                  artist: _artistcontroller.text,
                  album: _albumcontroller.text,
                  genre: _genrecontroller.text,
                  year: _yearcontroller.text,
                  albumArtist: _albumArtistController.text,
                );
                try {
                  try {
                    await [
                      Permission.manageExternalStorage,
                    ].request();
                    tagger.writeTags(
                      path: song['path'].toString(),
                      tag: tag,
                    );
                  } catch (e) {
                    await tagger.writeTags(
                      path: song['path'].toString(),
                      tag: tag,
                    );
                    ShowSnackBar().showSnackBar(
                      context,
                      AppLocalizations.of(context)!.successTagEdit,
                    );
                  }
                } catch (e) {
                  ShowSnackBar().showSnackBar(
                    context,
                    AppLocalizations.of(context)!.failedTagEdit,
                  );
                }
              },
              child: Text(
                AppLocalizations.of(context)!.ok,
                style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.secondary == Colors.white
                            ? Colors.black
                            : null),
              ),
            ),
            const SizedBox(
              width: 5,
            ),
          ],
        );
      });
  return song;
}
