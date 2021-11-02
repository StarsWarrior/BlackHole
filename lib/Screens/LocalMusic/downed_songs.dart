// import 'dart:io';
// import 'dart:typed_data';

// import 'package:blackhole/CustomWidgets/collage.dart';
// import 'package:blackhole/CustomWidgets/custom_physics.dart';
// import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/audio_query.dart';
// import 'package:blackhole/CustomWidgets/snackbar.dart';
// import 'package:blackhole/Helpers/picker.dart';
// import 'package:blackhole/Screens/Library/show_songs.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
// import 'package:audiotagger/audiotagger.dart';
// import 'package:audiotagger/models/audiofile.dart';
// import 'package:audiotagger/models/tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';

class DownloadedSongs extends StatefulWidget {
  final List<SongModel>? cachedSongs;
  final String? title;
  final int? playlistId;
  const DownloadedSongs(
      {Key? key, this.cachedSongs, this.title, this.playlistId})
      : super(key: key);
  @override
  _DownloadedSongsState createState() => _DownloadedSongsState();
}

class _DownloadedSongsState extends State<DownloadedSongs>
    with AutomaticKeepAliveClientMixin {
  List<SongModel> _cachedSongs = [];
  List _cachedSongsMap =
      Hive.box('cache').get('offlineSongsData', defaultValue: []) as List;
  // List<AlbumModel> _cachedAlbums = [];
  // List<ArtistModel> _cachedArtists = [];
  // List<GenreModel> _cachedGenres = [];

  // List sortedCachedAlbumKeysList = [];
  // List sortedCachedArtistKeysList = [];
  // List sortedCachedGenreKeysList = [];

  // List _cachedVideos = [];
  bool added = false;
  int sortValue = Hive.box('settings').get('sortValue', defaultValue: 1) as int;
  int orderValue =
      Hive.box('settings').get('orderValue', defaultValue: 1) as int;
  int albumSortValue =
      Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;
  List dirPaths =
      Hive.box('settings').get('searchPaths', defaultValue: []) as List;
  int minDuration =
      Hive.box('settings').get('minDuration', defaultValue: 10) as int;
  List blackLists =
      Hive.box('settings').get('blacklistedPaths', defaultValue: []) as List;
  // TabController? _tcontroller;
  int currentIndex = 0;
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();

  final Map<int, SongSortType> songSortTypes = {
    0: SongSortType.DISPLAY_NAME,
    1: SongSortType.DATE_ADDED,
    2: SongSortType.ALBUM,
    3: SongSortType.ARTIST,
    4: SongSortType.DURATION,
    5: SongSortType.SIZE,
  };

  final Map<int, OrderType> songOrderTypes = {
    0: OrderType.ASC_OR_SMALLER,
    1: OrderType.DESC_OR_GREATER,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    // _tcontroller = TabController(length: 4, vsync: this);
    // _tcontroller!.addListener(changeTitle);
    getCached();
    // getDownloaded();
    super.initState();
  }

  // @override
  // void dispose() {
  //   super.dispose();
  // _tcontroller!.dispose();
  // }

  // void changeTitle() {
  //   setState(() {
  //     currentIndex = _tcontroller!.index;
  //   });
  // }

  Future<void> getCached() async {
    await offlineAudioQuery.requestPermission();
    if (widget.cachedSongs == null) {
      final List<SongModel> temp = await offlineAudioQuery.getSongs(
          sortType: songSortTypes[sortValue],
          orderType: songOrderTypes[orderValue]);
      _cachedSongs = temp
          .where((i) =>
              (i.duration ?? 60000) > 1000 * minDuration &&
              (i.isMusic! || i.isPodcast! || i.isAudioBook!))
          .toList();
    } else {
      _cachedSongs = widget.cachedSongs!;
    }
    // _cachedAlbums = await getAlbums();
    // _cachedArtists = await getArtists();
    // _cachedGenres = await getGenres();
    added = true;
    setState(() {});
    if (widget.cachedSongs == null) {
      _cachedSongsMap = await offlineAudioQuery.getArtwork(_cachedSongs,
          songsMap: _cachedSongsMap);
      Hive.box('cache').put('offlineSongsData', _cachedSongsMap);
    } else {
      _cachedSongsMap = await offlineAudioQuery.getArtwork(_cachedSongs,
          songsMap: _cachedSongsMap, artworkType: ArtworkType.PLAYLIST);
    }
  }

  Future<void> sortSongs(int sortVal, int order) async {
    switch (sortVal) {
      case 0:
        _cachedSongs.sort((a, b) =>
            a.displayName.toString().compareTo(b.displayName.toString()));
        break;
      case 1:
        _cachedSongs.sort(
            (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()));
        break;
      case 2:
        _cachedSongs
            .sort((a, b) => a.album.toString().compareTo(b.album.toString()));
        break;
      case 3:
        _cachedSongs
            .sort((a, b) => a.artist.toString().compareTo(b.artist.toString()));
        break;
      case 4:
        _cachedSongs.sort(
            (a, b) => a.duration.toString().compareTo(b.duration.toString()));
        break;
      case 5:
        _cachedSongs
            .sort((a, b) => a.size.toString().compareTo(b.size.toString()));
        break;
      default:
        _cachedSongs.sort(
            (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()));
        break;
    }

    if (order == 1) {
      _cachedSongs = _cachedSongs.reversed.toList();
    }
  }

  // Future<void> fetchDownloaded() async {
  //   final List _songs = [];
  //   final List _videos = [];
  //   List sortedAlbumKeysList = [];
  //   List sortedArtistKeysList = [];
  //   List sortedGenreKeysList = [];
  //   final List<FileSystemEntity> _files = [];
  //   final Map<String, List<Map>> _albums = {};
  //   final Map<String, List<Map>> _artists = {};
  //   final Map<String, List<Map>> _genres = {};
  //   final Audiotagger tagger = Audiotagger();

  //   for (final path in dirPaths) {
  //     try {
  //       final Directory dir = Directory(path.toString());
  //       _files.addAll(dir.listSync(recursive: true, followLinks: false));
  //     } catch (e) {
  //       // print('failed');
  //     }
  //   }

  //   for (final FileSystemEntity entity in _files) {
  //     if (entity.path.endsWith('.mp3') ||
  //         entity.path.endsWith('.m4a') ||
  //         entity.path.endsWith('.wav') ||
  //         entity.path.endsWith('.opus') ||
  //         entity.path.endsWith('.flac')) {
  //       try {
  //         final Tag? tags = await tagger.readTags(path: entity.path);
  //         final FileStat stats = await entity.stat();
  //         if (stats.size > 1024 * minSize) {
  //           if (widget.type != 'all' && tags?.comment != 'BlackHole') {
  //             continue;
  //           }
  //           final AudioFile? audioFile =
  //               await tagger.readAudioFile(path: entity.path);
  //           String albumTag = tags?.album ?? '';
  //           String artistTag = tags?.artist ?? '';
  //           String genreTag = tags?.genre ?? '';
  //           if (artistTag.trim() == '') artistTag = 'Unknown';

  //           if (albumTag.trim() == '') albumTag = 'Unknown';

  //           if (genreTag.trim() == '') genreTag = 'Unknown';

  //           final Map data = {
  //             'id': entity.path,
  //             'image': await tagger.readArtwork(path: entity.path),
  //             'title': tags?.title ?? '',
  //             'artist': artistTag,
  //             'albumArtist': tags?.albumArtist,
  //             'album': albumTag,
  //             'lastModified': stats.modified,
  //             'genre': genreTag,
  //             'year': tags?.year,
  //             'duration': audioFile?.length,
  //           };
  //           _songs.add(data);

  //           if (_albums.containsKey(albumTag)) {
  //             final List<Map> tempAlbum = _albums[albumTag]!;
  //             tempAlbum.add(data);
  //             _albums.addEntries([MapEntry(albumTag, tempAlbum)]);
  //           } else {
  //             _albums.addEntries([
  //               MapEntry(albumTag, [data])
  //             ]);
  //           }

  //           if (_artists.containsKey(artistTag)) {
  //             final List<Map> tempArtist = _artists[artistTag]!;
  //             tempArtist.add(data);
  //             _artists.addEntries([MapEntry(artistTag, tempArtist)]);
  //           } else {
  //             _artists.addEntries([
  //               MapEntry(artistTag, [data])
  //             ]);
  //           }

  //           if (_genres.containsKey(genreTag)) {
  //             final List<Map> tempGenre = _genres[genreTag]!;
  //             tempGenre.add(data);
  //             _genres.addEntries([MapEntry(genreTag, tempGenre)]);
  //           } else {
  //             _genres.addEntries([
  //               MapEntry(genreTag, [data])
  //             ]);
  //           }
  //         }
  //       } catch (e) {
  //         // print('Error: $e');
  //       }
  //     }

  //     if (widget.type == 'all' &&
  //         (entity.path.endsWith('.mp4') ||
  //             entity.path.endsWith('.mkv') ||
  //             entity.path.endsWith('.webm') ||
  //             entity.path.endsWith('.opus'))) {
  //       try {
  //         final FileStat stats = await entity.stat();
  //         if (stats.size > 1024 * minSize) {
  //           _videos.add({
  //             'id': entity.path,
  //             'image': null,
  //             'title': entity.path.split('/').last.toString(),
  //             'artist': '',
  //             'albumArtist': '',
  //             'album': '',
  //             'lastModified': stats.modified,
  //             'year': '',
  //             'genre': '',
  //           });
  //         }
  //       } catch (e) {
  //         // print('Error: $e');
  //       }
  //     }
  //   }
  // sortSongs(_songs, _videos);

  //   sortedAlbumKeysList = _albums.keys.toList();
  //   sortedArtistKeysList = _artists.keys.toList();
  //   sortedGenreKeysList = _genres.keys.toList();

  //   sortAlbums(sortedAlbumKeysList, sortedArtistKeysList, sortedGenreKeysList,
  //       _albums, _artists, _genres);

  //   if (widget.type == 'all') {
  //     Hive.box('cache').put('cachedSongs', _songs);
  //     Hive.box('cache').put('cachedVideos', _videos);
  //     Hive.box('cache').put('cachedAlbums', _albums);
  //     Hive.box('cache').put('cachedArtists', _artists);
  //     Hive.box('cache').put('cachedGenres', _genres);
  //   } else {
  //     Hive.box('cache').put('cachedDownloadedSongs', _songs);
  //     Hive.box('cache').put('cachedDownloadedAlbums', _albums);
  //     Hive.box('cache').put('cachedDownloadedArtists', _artists);
  //     Hive.box('cache').put('cachedDownloadedGenres', _genres);
  //   }

  //   _cachedSongs = _songs;
  //   _cachedVideos = _videos;
  //   _cachedAlbums = _albums;
  //   _cachedGenres = _genres;
  //   _cachedArtists = _artists;
  //   sortedCachedAlbumKeysList = sortedAlbumKeysList;
  //   sortedCachedArtistKeysList = sortedArtistKeysList;
  //   sortedCachedGenreKeysList = sortedGenreKeysList;
  // }

  // Future<void> getDownloaded() async {
  //   PermissionStatus status = await Permission.storage.status;
  //   if (status.isRestricted || status.isDenied) {
  //     final Map<Permission, PermissionStatus> statuses = await [
  //       Permission.storage,
  //     ].request();
  //     debugPrint(statuses[Permission.storage].toString());
  //   }
  //   status = await Permission.storage.status;
  //   if (status.isDenied || status.isPermanentlyDenied) {
  //     return;
  //   }
  //   if (dirPaths.isEmpty) {
  //     final String? path = await ExtStorage.getExternalStoragePublicDirectory(
  //         ExtStorage.DIRECTORY_MUSIC);
  //     dirPaths.add(path);
  //     final String? path2 = await ExtStorage.getExternalStoragePublicDirectory(
  //         ExtStorage.DIRECTORY_DOWNLOADS);
  //     dirPaths.add(path2);
  //     Hive.box('settings').put('searchPaths', dirPaths);
  //   }
  //   await fetchDownloaded();

  //   added = true;
  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            // child: DefaultTabController(
            // length: 4,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title:
                    Text(widget.title ?? AppLocalizations.of(context)!.myMusic),
                // bottom: TabBar(
                // controller: _tcontroller,
                // tabs:
                // widget.type == 'all'
                // ?
                //  [
                //     Tab(
                //       text: AppLocalizations.of(context)!.songs,
                //     ),
                //     Tab(
                //       text: AppLocalizations.of(context)!.albums,
                //     ),
                //     Tab(
                //       text: AppLocalizations.of(context)!.artists,
                //     ),
                //     Tab(
                //       text: AppLocalizations.of(context)!.genres,
                //     ),
                //     Tab(
                //       text: AppLocalizations.of(context)!.videos,
                //     )
                //   ]
                // :
                // [
                // Tab(
                //   text: AppLocalizations.of(context)!.songs,
                // ),
                // Tab(
                //   text: AppLocalizations.of(context)!.albums,
                // ),
                // Tab(
                //   text: AppLocalizations.of(context)!.artists,
                // ),
                // Tab(
                //   text: AppLocalizations.of(context)!.denres,
                // ),
                // ],
                // ),
                actions: [
                  IconButton(
                    icon: const Icon(CupertinoIcons.search),
                    tooltip: AppLocalizations.of(context)!.search,
                    onPressed: () {
                      showSearch(
                          context: context, delegate: DataSearch(_cachedSongs));
                    },
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.sort_rounded),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0))),
                    onSelected: (int value) async {
                      if (value < 6) {
                        sortValue = value;
                        Hive.box('settings').put('sortValue', value);
                      } else {
                        orderValue = value - 6;
                        Hive.box('settings').put('orderValue', orderValue);
                      }
                      await sortSongs(sortValue, orderValue);
                      setState(() {});
                    },
                    itemBuilder: (context) {
                      final List<String> sortTypes = [
                        AppLocalizations.of(context)!.displayName,
                        AppLocalizations.of(context)!.dateAdded,
                        AppLocalizations.of(context)!.album,
                        AppLocalizations.of(context)!.artist,
                        AppLocalizations.of(context)!.duration,
                        AppLocalizations.of(context)!.size,
                      ];
                      final List<String> orderTypes = [
                        AppLocalizations.of(context)!.inc,
                        AppLocalizations.of(context)!.dec,
                      ];
                      final menuList = <PopupMenuEntry<int>>[];
                      menuList.addAll(
                        sortTypes
                            .map(
                              (e) => PopupMenuItem(
                                value: sortTypes.indexOf(e),
                                child: Row(
                                  children: [
                                    if (sortValue == sortTypes.indexOf(e))
                                      Icon(
                                        Icons.check_rounded,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.grey[700],
                                      )
                                    else
                                      const SizedBox(),
                                    const SizedBox(width: 10),
                                    Text(
                                      e,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                      menuList.add(
                        const PopupMenuDivider(
                          height: 10,
                        ),
                      );
                      menuList.addAll(
                        orderTypes
                            .map(
                              (e) => PopupMenuItem(
                                value: sortTypes.length + orderTypes.indexOf(e),
                                child: Row(
                                  children: [
                                    if (orderValue == orderTypes.indexOf(e))
                                      Icon(
                                        Icons.check_rounded,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.grey[700],
                                      )
                                    else
                                      const SizedBox(),
                                    const SizedBox(width: 10),
                                    Text(
                                      e,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                      return menuList;
                    },
                  ),
                ],
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.secondary,
                elevation: 0,
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
                  :
                  // TabBarView(
                  //     physics: const CustomPhysics(),
                  //     controller: _tcontroller,
                  //     children:
                  //         //  widget.type == 'all'
                  //         //     ?
                  //         [
                  SongsTab(
                      cachedSongs: _cachedSongs,
                      cachedSongsMap: _cachedSongsMap,
                      playlistId: widget.playlistId,
                      playlistName: widget.title,
                    ),
              // if (_cachedAlbums.isEmpty)
              //   EmptyScreen().emptyScreen(
              //       context,
              //       3,
              //       'Nothing to ',
              //       15.0,
              //       'Show Here',
              //       45,
              //       'Download Something',
              //       23.0)
              // else
              //   AlbumsTab(
              //     type: 'album',
              //     cachedAlbums: _cachedAlbums,
              //   ),
              // if (_cachedArtists.isEmpty)
              //   EmptyScreen().emptyScreen(
              //       context,
              //       3,
              //       'Nothing to ',
              //       15.0,
              //       'Show Here',
              //       45,
              //       'Download Something',
              //       23.0)
              // else
              //   AlbumsTab(
              //     type: 'artist',
              //     cachedArtists: _cachedArtists,
              //   ),
              // if (_cachedGenres.isEmpty)
              //   EmptyScreen().emptyScreen(
              //       context,
              //       3,
              //       'Nothing to ',
              //       15.0,
              //       'Show Here',
              //       45,
              //       'Download Something',
              //       23.0)
              // else
              //   AlbumsTab(
              //     type: 'genre',
              //     cachedGenres: _cachedGenres,
              //   ),
              // videosTab(),
              // ]
              // : [
              //     songsTab(),
              //     // albumsTab(),
              //     // artistsTab(),
              //     // genresTab(),
              //   ]
              // ),
              // ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }

//   Widget videosTab() {
//     return _cachedVideos.isEmpty
//         ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15.0,
//             'Show Here', 45, 'Download Something', 23.0)
//         : ListView.builder(
//             physics: const BouncingScrollPhysics(),
//             padding: const EdgeInsets.only(top: 20, bottom: 10),
//             shrinkWrap: true,
//             itemExtent: 70.0,
//             itemCount: _cachedVideos.length,
//             itemBuilder: (context, index) {
//               return ListTile(
//                 leading: Card(
//                   elevation: 5,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(7.0),
//                   ),
//                   clipBehavior: Clip.antiAlias,
//                   child: Stack(
//                     children: [
//                       const Image(
//                         image: AssetImage('assets/cover.jpg'),
//                       ),
//                       if (_cachedVideos[index]['image'] == null)
//                         const SizedBox()
//                       else
//                         SizedBox(
//                           height: 50.0,
//                           width: 50.0,
//                           child: Image(
//                             fit: BoxFit.cover,
//                             image: MemoryImage(
//                                 _cachedVideos[index]['image'] as Uint8List),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//                 title: Text(
//                   '${_cachedVideos[index]['id'].split('/').last}',
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 2,
//                 ),
//                 trailing: PopupMenuButton(
//                   icon: const Icon(Icons.more_vert_rounded),
//                   shape: const RoundedRectangleBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(15.0))),
//                   onSelected: (dynamic value) async {
//                     if (value == 0) {
//                       showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           final String fileName = _cachedVideos[index]['id']
//                               .split('/')
//                               .last
//                               .toString();
//                           final List temp = fileName.split('.');
//                           temp.removeLast();
//                           final String videoName = temp.join('.');
//                           final controller =
//                               TextEditingController(text: videoName);
//                           return AlertDialog(
//                             content: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Text(
//                                       'Name',
//                                       style: TextStyle(
//                                           color: Theme.of(context).accentColor),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(
//                                   height: 10,
//                                 ),
//                                 TextField(
//                                     autofocus: true,
//                                     controller: controller,
//                                     onSubmitted: (value) async {
//                                       try {
//                                         Navigator.pop(context);
//                                         String newName = _cachedVideos[index]
//                                                 ['id']
//                                             .toString()
//                                             .replaceFirst(videoName, value);

//                                         while (await File(newName).exists()) {
//                                           newName = newName.replaceFirst(
//                                               value, '$value (1)');
//                                         }

//                                         File(_cachedVideos[index]['id']
//                                                 .toString())
//                                             .rename(newName);
//                                         _cachedVideos[index]['id'] = newName;
//                                         ShowSnackBar().showSnackBar(
//                                           context,
//                                           'Renamed to ${_cachedVideos[index]['id'].split('/').last}',
//                                         );
//                                       } catch (e) {
//                                         ShowSnackBar().showSnackBar(
//                                           context,
//                                           'Failed to Rename ${_cachedVideos[index]['id'].split('/').last}',
//                                         );
//                                       }
//                                       setState(() {});
//                                     }),
//                               ],
//                             ),
//                             actions: [
//                               TextButton(
//                                 style: TextButton.styleFrom(
//                                   primary: Theme.of(context).brightness ==
//                                           Brightness.dark
//                                       ? Colors.white
//                                       : Colors.grey[700],
//                                   //       backgroundColor: Theme.of(context).accentColor,
//                                 ),
//                                 onPressed: () {
//                                   Navigator.pop(context);
//                                 },
//                                 child: const Text(
//                                   'Cancel',
//                                 ),
//                               ),
//                               TextButton(
//                                 style: TextButton.styleFrom(
//                                   primary: Colors.white,
//                                   backgroundColor:
//                                       Theme.of(context).accentColor,
//                                 ),
//                                 onPressed: () async {
//                                   try {
//                                     Navigator.pop(context);
//                                     String newName = _cachedVideos[index]['id']
//                                         .toString()
//                                         .replaceFirst(
//                                             videoName, controller.text);

//                                     while (await File(newName).exists()) {
//                                       newName = newName.replaceFirst(
//                                           controller.text,
//                                           '${controller.text} (1)');
//                                     }

//                                     File(_cachedVideos[index]['id'].toString())
//                                         .rename(newName);
//                                     _cachedVideos[index]['id'] = newName;
//                                     ShowSnackBar().showSnackBar(
//                                       context,
//                                       'Renamed to ${_cachedVideos[index]['id'].split('/').last}',
//                                     );
//                                   } catch (e) {
//                                     ShowSnackBar().showSnackBar(
//                                       context,
//                                       'Failed to Rename ${_cachedVideos[index]['id'].split('/').last}',
//                                     );
//                                   }
//                                   setState(() {});
//                                 },
//                                 child: const Text(
//                                   'Ok',
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                               const SizedBox(
//                                 width: 5,
//                               ),
//                             ],
//                           );
//                         },
//                       );
//                     }
//                     if (value == 1) {
//                       try {
//                         File(_cachedVideos[index]['id'].toString()).delete();
//                         ShowSnackBar().showSnackBar(
//                           context,
//                           'Deleted ${_cachedVideos[index]['id'].split('/').last}',
//                         );
//                         _cachedVideos.remove(_cachedVideos[index]);
//                       } catch (e) {
//                         ShowSnackBar().showSnackBar(
//                           context,
//                           'Failed to delete ${_cachedVideos[index]['id']}',
//                         );
//                       }
//                       setState(() {});
//                     }
//                   },
//                   itemBuilder: (context) => [
//                     PopupMenuItem(
//                       value: 0,
//                       child: Row(
//                         children: const [
//                           Icon(Icons.edit_rounded),
//                           const SizedBox(width: 10.0),
//                           Text('Rename'),
//                         ],
//                       ),
//                     ),
//                     PopupMenuItem(
//                       value: 1,
//                       child: Row(
//                         children: const [
//                           Icon(Icons.delete_rounded),
//                           const SizedBox(width: 10.0),
//                           Text('Delete'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 onTap: () {
//                   Navigator.of(context).push(
//                     PageRouteBuilder(
//                       opaque: false, // set to false
//                       pageBuilder: (_, __, ___) => PlayScreen(
//                         data: {
//                           'response': _cachedVideos,
//                           'index': index,
//                           'offline': true
//                         },
//                         fromMiniplayer: false,
//                       ),
//                     ),
//                   );
//                 },
//               );
//             });
//   }
}

class SongsTab extends StatelessWidget {
  final List<SongModel> cachedSongs;
  final List cachedSongsMap;
  final int? playlistId;
  final String? playlistName;
  const SongsTab(
      {Key? key,
      required this.cachedSongs,
      required this.cachedSongsMap,
      this.playlistId,
      this.playlistName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return cachedSongs.isEmpty
        ? EmptyScreen().emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            45,
            AppLocalizations.of(context)!.downloadSomething,
            23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemExtent: 70.0,
            itemCount: cachedSongs.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: QueryArtworkWidget(
                    id: cachedSongs[index].id,
                    type: ArtworkType.AUDIO,
                    keepOldArtwork: true,
                    artworkBorder: BorderRadius.circular(7.0),
                    nullArtworkWidget: ClipRRect(
                      borderRadius: BorderRadius.circular(7.0),
                      child: const Image(
                        fit: BoxFit.cover,
                        height: 50.0,
                        width: 50.0,
                        image: AssetImage('assets/cover.jpg'),
                      ),
                    ),
                  ),
                ),
                // Card(
                //   elevation: 5,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(7.0),
                //   ),
                //   clipBehavior: Clip.antiAlias,
                //   child: FutureBuilder(
                //       future: audioQuery.queryArtwork(
                //           _cachedSongs[index].id, ArtworkType.AUDIO),
                //       builder: (BuildContext context,
                //           AsyncSnapshot<Uint8List?> snapshot) {
                //         if (snapshot.connectionState == ConnectionState.done &&
                //             snapshot.data != null) {
                //           return SizedBox(
                //             height: 50.0,
                //             width: 50.0,
                //             child: Image(
                //               fit: BoxFit.cover,
                //               image: MemoryImage(snapshot.data!),
                //             ),
                //           );
                //         }
                //         return const SizedBox(
                //           height: 50.0,
                //           width: 50.0,
                //           child: Image(
                //             image: AssetImage('assets/cover.jpg'),
                //           ),
                //         );
                //         // if (_cachedSongs[index]['image'] == null)
                //         // const SizedBox()
                //         // else
                //       }),
                // ),
                title: Text(
                  cachedSongs[index].title.trim() != ''
                      ? cachedSongs[index].title
                      : cachedSongs[index].displayNameWOExt,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  cachedSongs[index]
                          .artist
                          ?.replaceAll('<unknown>', 'Unknown') ??
                      AppLocalizations.of(context)!.unknown,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0))),
                  onSelected: (int? value) async {
                    if (value == 0) {
                      AddToOffPlaylist()
                          .addToOffPlaylist(context, cachedSongs[index].id);
                    }
                    if (value == 1) {
                      await OfflineAudioQuery().removeFromPlaylist(
                          playlistId: playlistId!,
                          audioId: cachedSongs[index].id);
                      ShowSnackBar().showSnackBar(context,
                          '${AppLocalizations.of(context)!.removedFrom} $playlistName');
                    }
                    // if (value == 0) {
                    // showDialog(
                    // context: context,
                    // builder: (BuildContext context) {
                    // final String fileName = _cachedSongs[index].uri!;
                    // final List temp = fileName.split('.');
                    // temp.removeLast();
                    //           final String songName = temp.join('.');
                    //           final controller =
                    //               TextEditingController(text: songName);
                    //           return AlertDialog(
                    //             content: Column(
                    //               mainAxisSize: MainAxisSize.min,
                    //               children: [
                    //                 Row(
                    //                   children: [
                    //                     Text(
                    //                       'Name',
                    //                       style: TextStyle(
                    //                           color: Theme.of(context).accentColor),
                    //                     ),
                    //                   ],
                    //                 ),
                    //                 const SizedBox(
                    //                   height: 10,
                    //                 ),
                    //                 TextField(
                    //                     autofocus: true,
                    //                     controller: controller,
                    //                     onSubmitted: (value) async {
                    //                       try {
                    //                         Navigator.pop(context);
                    //                         String newName = _cachedSongs[index]
                    //                                 ['id']
                    //                             .toString()
                    //                             .replaceFirst(songName, value);

                    //                         while (await File(newName).exists()) {
                    //                           newName = newName.replaceFirst(
                    //                               value, '$value (1)');
                    //                         }

                    //                         File(_cachedSongs[index]['id']
                    //                                 .toString())
                    //                             .rename(newName);
                    //                         _cachedSongs[index]['id'] = newName;
                    //                         ShowSnackBar().showSnackBar(
                    //                           context,
                    //                           'Renamed to ${_cachedSongs[index]['id'].split('/').last}',
                    //                         );
                    //                       } catch (e) {
                    //                         ShowSnackBar().showSnackBar(
                    //                           context,
                    //                           'Failed to Rename ${_cachedSongs[index]['id'].split('/').last}',
                    //                         );
                    //                       }
                    //                       setState(() {});
                    //                     }),
                    //               ],
                    //             ),
                    //             actions: [
                    //               TextButton(
                    //                 style: TextButton.styleFrom(
                    //                   primary: Theme.of(context).brightness ==
                    //                           Brightness.dark
                    //                       ? Colors.white
                    //                       : Colors.grey[700],
                    //                   //       backgroundColor: Theme.of(context).accentColor,
                    //                 ),
                    //                 onPressed: () {
                    //                   Navigator.pop(context);
                    //                 },
                    //                 child: const Text(
                    //                   'Cancel',
                    //                 ),
                    //               ),
                    //               TextButton(
                    //                 style: TextButton.styleFrom(
                    //                   primary: Colors.white,
                    //                   backgroundColor:
                    //                       Theme.of(context).accentColor,
                    //                 ),
                    //                 onPressed: () async {
                    //                   try {
                    //                     Navigator.pop(context);
                    //                     String newName = _cachedSongs[index]['id']
                    //                         .toString()
                    //                         .replaceFirst(
                    //                             songName, controller.text);

                    //                     while (await File(newName).exists()) {
                    //                       newName = newName.replaceFirst(
                    //                           controller.text,
                    //                           '${controller.text} (1)');
                    //                     }

                    //                     File(_cachedSongs[index]['id'].toString())
                    //                         .rename(newName);
                    //                     _cachedSongs[index]['id'] = newName;
                    //                     ShowSnackBar().showSnackBar(
                    //                       context,
                    //                       'Renamed to ${_cachedSongs[index]['id'].split('/').last}',
                    //                     );
                    //                   } catch (e) {
                    //                     ShowSnackBar().showSnackBar(
                    //                       context,
                    //                       'Failed to Rename ${_cachedSongs[index]['id'].split('/').last}',
                    //                     );
                    //                   }
                    //                   setState(() {});
                    //                 },
                    //                 child: const Text(
                    //                   'Ok',
                    //                   style: TextStyle(color: Colors.white),
                    //                 ),
                    //               ),
                    //               const SizedBox(
                    //                 width: 5,
                    //               ),
                    //             ],
                    //           );
                    //         },
                    //       );
                    //     }
                    //     if (value == 1) {
                    //       showDialog(
                    //         context: context,
                    //         builder: (BuildContext context) {
                    //           Uint8List? _imageByte =
                    //               _cachedSongs[index]['image'] as Uint8List?;
                    //           String _imagePath = '';
                    //           final _titlecontroller = TextEditingController(
                    //               text: _cachedSongs[index]['title'].toString());
                    //           final _albumcontroller = TextEditingController(
                    //               text: _cachedSongs[index]['album'].toString());
                    //           final _artistcontroller = TextEditingController(
                    //               text: _cachedSongs[index]['artist'].toString());
                    //           final _albumArtistController = TextEditingController(
                    //               text: _cachedSongs[index]['albumArtist']
                    //                   .toString());
                    //           final _genrecontroller = TextEditingController(
                    //               text: _cachedSongs[index]['genre'].toString());
                    //           final _yearcontroller = TextEditingController(
                    //               text: _cachedSongs[index]['year'].toString());
                    //           final tagger = Audiotagger();
                    //           return AlertDialog(
                    //             content: SizedBox(
                    //               height: 400,
                    //               width: 300,
                    //               child: SingleChildScrollView(
                    //                 physics: const BouncingScrollPhysics(),
                    //                 child: Column(
                    //                   mainAxisSize: MainAxisSize.min,
                    //                   children: [
                    //                     GestureDetector(
                    //                       onTap: () async {
                    //                         final String filePath = await Picker()
                    //                             .selectFile(
                    //                                 context,
                    //                                 ['png', 'jpg', 'jpeg'],
                    //                                 'Pick Image');
                    //                         if (filePath != '') {
                    //                           _imagePath = filePath;
                    //                           final Uri myUri = Uri.parse(filePath);
                    //                           final Uint8List imageBytes =
                    //                               await File.fromUri(myUri)
                    //                                   .readAsBytes();
                    //                           _imageByte = imageBytes;
                    //                           final Tag tag = Tag(
                    //                             artwork: _imagePath,
                    //                           );
                    //                           try {
                    //                             await [
                    //                               Permission.manageExternalStorage,
                    //                             ].request();
                    //                             await tagger.writeTags(
                    //                               path: _cachedSongs[index]['id']
                    //                                   .toString(),
                    //                               tag: tag,
                    //                             );
                    //                           } catch (e) {
                    //                             await tagger.writeTags(
                    //                               path: _cachedSongs[index]['id']
                    //                                   .toString(),
                    //                               tag: tag,
                    //                             );
                    //                           }
                    //                         }
                    //                       },
                    //                       child: Card(
                    //                         elevation: 5,
                    //                         shape: RoundedRectangleBorder(
                    //                           borderRadius:
                    //                               BorderRadius.circular(7.0),
                    //                         ),
                    //                         clipBehavior: Clip.antiAlias,
                    //                         child: SizedBox(
                    //                           height: MediaQuery.of(context)
                    //                                   .size
                    //                                   .width /
                    //                               2,
                    //                           width: MediaQuery.of(context)
                    //                                   .size
                    //                                   .width /
                    //                               2,
                    //                           child: _imageByte == null
                    //                               ? const Image(
                    //                                   fit: BoxFit.cover,
                    //                                   image: AssetImage(
                    //                                       'assets/cover.jpg'),
                    //                                 )
                    //                               : Image(
                    //                                   fit: BoxFit.cover,
                    //                                   image:
                    //                                       MemoryImage(_imageByte!)),
                    //                         ),
                    //                       ),
                    //                     ),
                    //                     const SizedBox(height: 20.0),
                    //                     Row(
                    //                       children: [
                    //                         Text(
                    //                           'Title',
                    //                           style: TextStyle(
                    //                               color: Theme.of(context)
                    //                                   .accentColor),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     TextField(
                    //                         autofocus: true,
                    //                         controller: _titlecontroller,
                    //                         onSubmitted: (value) {}),
                    //                     const SizedBox(
                    //                       height: 30,
                    //                     ),
                    //                     Row(
                    //                       children: [
                    //                         Text(
                    //                           'Artist',
                    //                           style: TextStyle(
                    //                               color: Theme.of(context)
                    //                                   .accentColor),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     TextField(
                    //                         autofocus: true,
                    //                         controller: _artistcontroller,
                    //                         onSubmitted: (value) {}),
                    //                     const SizedBox(
                    //                       height: 30,
                    //                     ),
                    //                     Row(
                    //                       children: [
                    //                         Text(
                    //                           'Album Artist',
                    //                           style: TextStyle(
                    //                               color: Theme.of(context)
                    //                                   .accentColor),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     TextField(
                    //                         autofocus: true,
                    //                         controller: _albumArtistController,
                    //                         onSubmitted: (value) {}),
                    //                     const SizedBox(
                    //                       height: 30,
                    //                     ),
                    //                     Row(
                    //                       children: [
                    //                         Text(
                    //                           'Album',
                    //                           style: TextStyle(
                    //                               color: Theme.of(context)
                    //                                   .accentColor),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     TextField(
                    //                         autofocus: true,
                    //                         controller: _albumcontroller,
                    //                         onSubmitted: (value) {}),
                    //                     const SizedBox(
                    //                       height: 30,
                    //                     ),
                    //                     Row(
                    //                       children: [
                    //                         Text(
                    //                           'Genre',
                    //                           style: TextStyle(
                    //                               color: Theme.of(context)
                    //                                   .accentColor),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     TextField(
                    //                         autofocus: true,
                    //                         controller: _genrecontroller,
                    //                         onSubmitted: (value) {}),
                    //                     const SizedBox(
                    //                       height: 30,
                    //                     ),
                    //                     Row(
                    //                       children: [
                    //                         Text(
                    //                           'Year',
                    //                           style: TextStyle(
                    //                               color: Theme.of(context)
                    //                                   .accentColor),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     TextField(
                    //                         autofocus: true,
                    //                         controller: _yearcontroller,
                    //                         onSubmitted: (value) {}),
                    //                   ],
                    //                 ),
                    //               ),
                    //             ),
                    //             actions: [
                    //               TextButton(
                    //                 style: TextButton.styleFrom(
                    //                   primary: Theme.of(context).brightness ==
                    //                           Brightness.dark
                    //                       ? Colors.white
                    //                       : Colors.grey[700],
                    //                 ),
                    //                 onPressed: () {
                    //                   Navigator.pop(context);
                    //                 },
                    //                 child: const Text('Cancel'),
                    //               ),
                    //               TextButton(
                    //                 style: TextButton.styleFrom(
                    //                   primary: Colors.white,
                    //                   backgroundColor:
                    //                       Theme.of(context).accentColor,
                    //                 ),
                    //                 onPressed: () async {
                    //                   Navigator.pop(context);
                    //                   _cachedSongs[index]['title'] =
                    //                       _titlecontroller.text;
                    //                   _cachedSongs[index]['album'] =
                    //                       _albumcontroller.text;
                    //                   _cachedSongs[index]['artist'] =
                    //                       _artistcontroller.text;
                    //                   _cachedSongs[index]['albumArtist'] =
                    //                       _albumArtistController.text;
                    //                   _cachedSongs[index]['genre'] =
                    //                       _genrecontroller.text;
                    //                   _cachedSongs[index]['year'] =
                    //                       _yearcontroller.text;
                    //                   final tag = Tag(
                    //                     title: _titlecontroller.text,
                    //                     artist: _artistcontroller.text,
                    //                     album: _albumcontroller.text,
                    //                     genre: _genrecontroller.text,
                    //                     year: _yearcontroller.text,
                    //                     albumArtist: _albumArtistController.text,
                    //                   );
                    //                   try {
                    //                     try {
                    //                       await [
                    //                         Permission.manageExternalStorage,
                    //                       ].request();
                    //                       tagger.writeTags(
                    //                         path: _cachedSongs[index]['id']
                    //                             .toString(),
                    //                         tag: tag,
                    //                       );
                    //                     } catch (e) {
                    //                       await tagger.writeTags(
                    //                         path: _cachedSongs[index]['id']
                    //                             .toString(),
                    //                         tag: tag,
                    //                       );
                    //                       ShowSnackBar().showSnackBar(
                    //                         context,
                    //                         'Successfully edited tags',
                    //                       );
                    //                     }
                    //                   } catch (e) {
                    //                     ShowSnackBar().showSnackBar(
                    //                       context,
                    //                       'Failed to edit tags',
                    //                     );
                    //                   }
                    //                 },
                    //                 child: const Text(
                    //                   'Ok',
                    //                   style: TextStyle(color: Colors.white),
                    //                 ),
                    //               ),
                    //               const SizedBox(
                    //                 width: 5,
                    //               ),
                    //             ],
                    //           );
                    //         },
                    //       );
                    //     }
                    //     if (value == 2) {
                    //       try {
                    //         File(_cachedSongs[index]['id'].toString()).delete();
                    //         ShowSnackBar().showSnackBar(
                    //           context,
                    //           'Deleted ${_cachedSongs[index]['id'].split('/').last}',
                    //         );
                    //         if (_cachedAlbums[_cachedSongs[index]['album']]
                    //                 .length ==
                    //             1) {
                    //           sortedCachedAlbumKeysList
                    //               .remove(_cachedSongs[index]['album']);
                    //         }
                    //         _cachedAlbums[_cachedSongs[index]['album']]
                    //             .remove(_cachedSongs[index]);

                    //         if (_cachedArtists[_cachedSongs[index]['artist']]
                    //                 .length ==
                    //             1) {
                    //           sortedCachedArtistKeysList
                    //               .remove(_cachedSongs[index]['artist']);
                    //         }
                    //         _cachedArtists[_cachedSongs[index]['artist']]
                    //             .remove(_cachedSongs[index]);

                    //         if (_cachedGenres[_cachedSongs[index]['genre']]
                    //                 .length ==
                    //             1) {
                    //           sortedCachedGenreKeysList
                    //               .remove(_cachedSongs[index]['genre']);
                    //         }
                    //         _cachedGenres[_cachedSongs[index]['genre']]
                    //             .remove(_cachedSongs[index]);

                    //         _cachedSongs.remove(_cachedSongs[index]);
                    //       } catch (e) {
                    //         ShowSnackBar().showSnackBar(
                    //           context,
                    //           'Failed to delete ${_cachedSongs[index]['id']}',
                    //         );
                    //       }
                    //       setState(() {});
                    // }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: [
                          const Icon(Icons.playlist_add_rounded),
                          const SizedBox(width: 10.0),
                          Text(AppLocalizations.of(context)!.addToPlaylist),
                        ],
                      ),
                    ),
                    if (playlistId != null)
                      PopupMenuItem(
                        value: 1,
                        child: Row(
                          children: [
                            const Icon(Icons.delete_rounded),
                            const SizedBox(width: 10.0),
                            Text(AppLocalizations.of(context)!.remove),
                          ],
                        ),
                      ),
                    // PopupMenuItem(
                    //       value: 0,
                    //       child: Row(
                    //         children: const [
                    //           Icon(Icons.edit_rounded),
                    //           const SizedBox(width: 10.0),
                    //           Text('Rename'),
                    //         ],
                    //       ),
                    //     ),
                    //     PopupMenuItem(
                    //       value: 1,
                    //       child: Row(
                    //         children: const [
                    //           Icon(
                    //               // CupertinoIcons.tag
                    //               Icons.local_offer_rounded),
                    //           const SizedBox(width: 10.0),
                    //           Text('Edit Tags'),
                    //         ],
                    //       ),
                    //     ),
                    //     PopupMenuItem(
                    //       value: 2,
                    //       child: Row(
                    //         children: const [
                    //           Icon(Icons.delete_rounded),
                    //           const SizedBox(width: 10.0),
                    //           Text('Delete'),
                    //         ],
                    //       ),
                    //     ),
                  ],
                ),
                onTap: () async {
                  final int playIndex = cachedSongsMap.indexWhere(
                      (element) => element['_id'] == cachedSongs[index].id);
                  if (playIndex == -1) {
                    final singleSongMap = await OfflineAudioQuery()
                        .getArtwork([cachedSongs[index]]);
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => PlayScreen(
                          data: {
                            'response': singleSongMap,
                            'index': 0,
                            'offline': true
                          },
                          fromMiniplayer: false,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => PlayScreen(
                          data: {
                            'response': cachedSongsMap,
                            'index': playIndex,
                            'offline': true
                          },
                          fromMiniplayer: false,
                        ),
                      ),
                    );
                  }
                },
              );
            });
  }
}

// class AlbumsTab extends StatelessWidget {
//   final List<AlbumModel>? cachedAlbums;
//   final List<ArtistModel>? cachedArtists;
//   final List<GenreModel>? cachedGenres;
//   final String type;
//   const AlbumsTab({
//     Key? key,
//     this.cachedAlbums,
//     this.cachedArtists,
//     this.cachedGenres,
//     required this.type,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.only(top: 20, bottom: 10),
//         shrinkWrap: true,
//         itemExtent: 70.0,
//         itemCount: type == 'album'
//             ? cachedAlbums!.length
//             : type == 'artist'
//                 ? cachedArtists!.length
//                 : cachedGenres!.length,
//         itemBuilder: (context, index) {
//           return ListTile(
//             leading: QueryArtworkWidget(
//               id: type == 'album'
//                   ? cachedAlbums![index].id
//                   : type == 'artist'
//                       ? cachedArtists![index].id
//                       : cachedGenres![index].id,
//               type: ArtworkType.ALBUM,
//               artworkBorder: BorderRadius.circular(7.0),
//               nullArtworkWidget: ClipRRect(
//                 borderRadius: BorderRadius.circular(7.0),
//                 child: Image(
//                   fit: BoxFit.cover,
//                   height: 50.0,
//                   width: 50.0,
//                   image: AssetImage(type == 'album'
//                       ? 'assets/album.png'
//                       : type == 'artist'
//                           ? 'assets/artist.png'
//                           : 'assets/cover.jpg'),
//                 ),
//               ),
//             ),
//             // OfflineCollage(
//             //   imageList: (_cachedAlbums[sortedCachedAlbumKeysList[index]]
//             //                   as List)
//             //               .length >=
//             //           4
//             //       ? (_cachedAlbums[sortedCachedAlbumKeysList[index]]
//             //               as List)
//             //           .sublist(0, 4)
//             //       : (_cachedAlbums[sortedCachedAlbumKeysList[index]]
//             //               as List)
//             //           .sublist(
//             //               0,
//             //               (_cachedAlbums[sortedCachedAlbumKeysList[index]]
//             //                       as List)
//             //                   .length),
//             //   placeholderImage: 'assets/album.png',
//             // ),
//             title: Text(
//               type == 'album'
//                   ? cachedAlbums![index].album
//                   : type == 'artist'
//                       ? cachedArtists![index].artist
//                       : cachedGenres![index].genre,
//               overflow: TextOverflow.ellipsis,
//             ),
//             subtitle: Text(
//               '${type == 'album' ? cachedAlbums![index].numOfSongs : type == 'artist' ? cachedArtists![index].numberOfTracks : ''} Songs',
//             ),
//             onTap: () {
//               // Navigator.of(context).push(
//               //   PageRouteBuilder(
//               //     opaque: false, // set to false
//               //     pageBuilder: (_, __, ___) => SongsList(
//               //       data: _cachedAlbums[sortedCachedAlbumKeysList[index]]
//               //           as List,
//               //       offline: true,
//               //     ),
//               //   ),
//               // );
//             },
//           );
//         });
//   }
// }
