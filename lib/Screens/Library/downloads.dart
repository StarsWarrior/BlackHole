import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Screens/Library/show_songs.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';

class Downloads extends StatefulWidget {
  const Downloads({Key? key}) : super(key: key);
  @override
  _DownloadsState createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads>
    with SingleTickerProviderStateMixin {
  Box? downloadsBox;
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

  void changeTitle() {
    setState(() {
      currentIndex = _tcontroller!.index;
    });
  }

  Future<void> getDownloads() async {
    downloadsBox = Hive.box('downloads');
    _songs = downloadsBox?.values.toList() ?? [];
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
      _songs = downloadsBox?.values.toList() ?? [];
    }
    if (sortValue == 3) {
      _songs.shuffle();
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
    if (albumSortValue == 4) {
      sortedAlbumKeysList.shuffle();
      sortedArtistKeysList.shuffle();
      sortedGenreKeysList.shuffle();
    }
  }

  void deleteLiked(int index) {
    downloadsBox!.deleteAt(index);
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
                  title: const Text('Downloads'),
                  centerTitle: true,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Theme.of(context).accentColor,
                  elevation: 0,
                  bottom: TabBar(controller: _tcontroller, tabs: const [
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
                      text: 'Genres',
                    ),
                  ]),
                  actions: [
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
                                          const Text(
                                            'A-Z',
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
                                          const Text(
                                            'Z-A',
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
                                          const Text('Last Added'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 3,
                                      child: Row(
                                        children: [
                                          if (sortValue == 3)
                                            Icon(
                                              Icons.shuffle_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            )
                                          else
                                            const SizedBox(),
                                          const SizedBox(width: 10),
                                          const Text(
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
                                          const Text(
                                            'A-Z',
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
                                          const Text(
                                            'Z-A',
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
                                          const Text(
                                            '10-1',
                                          ),
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
                                          const Text(
                                            '1-10',
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 4,
                                      child: Row(
                                        children: [
                                          if (albumSortValue == 4)
                                            Icon(
                                              Icons.shuffle_rounded,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            )
                                          else
                                            const SizedBox(),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Shuffle',
                                          ),
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
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).accentColor),
                                strokeWidth: 5,
                              )),
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
                                'Nothing to ',
                                15.0,
                                'Show Here',
                                50,
                                'Download Something',
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
                                    // trailing: Row(
                                    // mainAxisSize: MainAxisSize.min,
                                    // children: [
                                    // PopupMenuButton(
                                    //     icon: const Icon(
                                    //         Icons.more_vert_rounded),
                                    //     shape:
                                    //         const RoundedRectangleBorder(
                                    //             borderRadius:
                                    //                 BorderRadius.all(
                                    //                     Radius.circular(
                                    //                         15.0))),
                                    //     itemBuilder: (context) => [
                                    //           PopupMenuItem(
                                    //             value: 0,
                                    //             child: Row(
                                    //               children: const [
                                    //                 Icon(Icons
                                    //                     .edit_rounded),
                                    //                 SizedBox(width: 10.0),
                                    //                 Text('Edit'),
                                    //               ],
                                    //             ),
                                    //           ),
                                    //         ],
                                    //     onSelected: (int? value) async {
                                    //       if (value == 0) {}
                                    //     }),
                                    // ],
                                    // ),
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
        ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15.0,
            'Show Here', 50, 'Download Something', 23.0)
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
                      ? '${_albums[sortedAlbumKeysList[index]]!.length} Song'
                      : '${_albums[sortedAlbumKeysList[index]]!.length} Songs',
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
        ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15.0,
            'Show Here', 50, 'Download Something', 23.0)
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
                      ? '${_artists[sortedArtistKeysList[index]]!.length} Song'
                      : '${_artists[sortedArtistKeysList[index]]!.length} Songs',
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
        ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15.0,
            'Show Here', 50, 'Download Something', 23.0)
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
                      ? '${_genres[sortedGenreKeysList[index]]!.length} Song'
                      : '${_genres[sortedGenreKeysList[index]]!.length} Songs',
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
