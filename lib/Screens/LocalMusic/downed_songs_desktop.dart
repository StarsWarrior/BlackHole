/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2022, Ankit Sangwan
 */

import 'dart:developer';
import 'dart:io';

// import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
// import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/playlist_head.dart';
// import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/audio_query.dart';
// import 'package:blackhole/Screens/LocalMusic/localplaylists.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class DownloadedSongsDesktop extends StatefulWidget {
  final List<Map>? cachedSongs;
  final String? title;
  final int? playlistId;
  // final bool showPlaylists;
  const DownloadedSongsDesktop({
    super.key,
    this.cachedSongs,
    this.title,
    this.playlistId,
    // this.showPlaylists = false,
  });
  @override
  _DownloadedSongsDesktopState createState() => _DownloadedSongsDesktopState();
}

class _DownloadedSongsDesktopState extends State<DownloadedSongsDesktop>
    with TickerProviderStateMixin {
  List<Map> _songs = [];
  String? tempPath = Hive.box('settings').get('tempDirPath')?.toString();
  final Map<String, List<Map>> _albums = {};
  final Map<String, List<Map>> _artists = {};
  final Map<String, List<Map>> _genres = {};

  final List<String> _sortedAlbumKeysList = [];
  final List<String> _sortedArtistKeysList = [];
  final List<String> _sortedGenreKeysList = [];
  // final List<String> _videos = [];

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
  bool includeOrExclude =
      Hive.box('settings').get('includeOrExclude', defaultValue: false) as bool;
  List includedExcludedPaths = Hive.box('settings')
      .get('includedExcludedPaths', defaultValue: []) as List;
  TabController? _tcontroller;
  OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
  List<Map> playlistDetails = [];

  @override
  void initState() {
    _tcontroller = TabController(length: 4, vsync: this);
    getData();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tcontroller!.dispose();
  }

  void getSongs() {
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    for (final path in includedExcludedPaths) {
      final dir = Directory(path.toString());
      try {
        final files = dir.listSync(recursive: true);
        for (final file in files) {
          if (file.path.endsWith('.mp3') || file.path.endsWith('.m4a')) {
            _songs.add({
              'id': file.path.replaceAll(avoid, '').replaceAll('  ', ' '),
              'title':
                  (file.path.split('\\').last.split('.')..removeLast()).join(),
              'artist': 'Unknown',
              'album': 'Unknown',
              'image': '',
              'year': '',
              'subtitle': file.path.split('\\').last,
              'quality': '',
              'genre': 'Unknown',
              'path': file.path,
            });
          }
        }
      } catch (e) {
        log('Failed to listSync "$path"');
      }
    }
  }

  Future<void> getData() async {
    // await offlineAudioQuery.requestPermission();
    tempPath ??= (await getTemporaryDirectory()).path;
    // playlistDetails = await offlineAudioQuery.getPlaylists();
    if (widget.cachedSongs == null) {
      getSongs();
    } else {
      _songs = widget.cachedSongs!;
    }
    added = true;
    setState(() {});
    // for (int i = 0; i < _songs.length; i++) {
    //   if (_albums.containsKey(_songs[i].album)) {
    //     _albums[_songs[i].album]!.add(_songs[i]);
    //   } else {
    //     _albums.addEntries([
    //       MapEntry(_songs[i].album!, [_songs[i]])
    //     ]);
    //     _sortedAlbumKeysList.add(_songs[i].album!);
    //   }

    //   if (_artists.containsKey(_songs[i].artist)) {
    //     _artists[_songs[i].artist]!.add(_songs[i]);
    //   } else {
    //     _artists.addEntries([
    //       MapEntry(_songs[i].artist!, [_songs[i]])
    //     ]);
    //     _sortedArtistKeysList.add(_songs[i].artist!);
    //   }

    //   if (_genres.containsKey(_songs[i].genre)) {
    //     _genres[_songs[i].genre]!.add(_songs[i]);
    //   } else {
    //     _genres.addEntries([
    //       MapEntry(_songs[i].genre!, [_songs[i]])
    //     ]);
    //     _sortedGenreKeysList.add(_songs[i].genre!);
    //   }
    // }
  }

  // Future<void> sortSongs(int sortVal, int order) async {
  //   switch (sortVal) {
  //     case 0:
  //       _songs.sort(
  //         (a, b) => a.displayName.compareTo(b.displayName),
  //       );
  //       break;
  //     case 1:
  //       _songs.sort(
  //         (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
  //       );
  //       break;
  //     case 2:
  //       _songs.sort(
  //         (a, b) => a.album.toString().compareTo(b.album.toString()),
  //       );
  //       break;
  //     case 3:
  //       _songs.sort(
  //         (a, b) => a.artist.toString().compareTo(b.artist.toString()),
  //       );
  //       break;
  //     case 4:
  //       _songs.sort(
  //         (a, b) => a.duration.toString().compareTo(b.duration.toString()),
  //       );
  //       break;
  //     case 5:
  //       _songs.sort(
  //         (a, b) => a.size.toString().compareTo(b.size.toString()),
  //       );
  //       break;
  //     default:
  //       _songs.sort(
  //         (a, b) => a.dateAdded.toString().compareTo(b.dateAdded.toString()),
  //       );
  //       break;
  //   }

  //   if (order == 1) {
  //     _songs = _songs.reversed.toList();
  //   }
  // }

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
                  title: Text(
                    widget.title ?? AppLocalizations.of(context)!.myMusic,
                  ),
                  bottom: TabBar(
                    // isScrollable: true,
                    controller: _tcontroller,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
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
                      // if (widget.showPlaylists)
                      //   Tab(
                      //     text: AppLocalizations.of(context)!.playlists,
                      //   ),
                      //     Tab(
                      //       text: AppLocalizations.of(context)!.videos,
                      //     )
                    ],
                  ),
                  // actions: [
                  // IconButton(
                  //   icon: const Icon(CupertinoIcons.search),
                  //   tooltip: AppLocalizations.of(context)!.search,
                  //   onPressed: () {
                  //     showSearch(
                  //       context: context,
                  //       delegate: DataSearch(
                  //         data: _songs,
                  //         tempPath: tempPath!,
                  //       ),
                  //     );
                  //   },
                  // ),
                  //   PopupMenuButton(
                  //     icon: const Icon(Icons.sort_rounded),
                  //     shape: const RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  //     ),
                  //     onSelected: (int value) async {
                  //       if (value < 6) {
                  //         sortValue = value;
                  //         Hive.box('settings').put('sortValue', value);
                  //       } else {
                  //         orderValue = value - 6;
                  //         Hive.box('settings').put('orderValue', orderValue);
                  //       }
                  //       // await sortSongs(sortValue, orderValue);
                  //       setState(() {});
                  //     },
                  //     itemBuilder: (context) {
                  //       final List<String> sortTypes = [
                  //         AppLocalizations.of(context)!.displayName,
                  //         AppLocalizations.of(context)!.dateAdded,
                  //         AppLocalizations.of(context)!.album,
                  //         AppLocalizations.of(context)!.artist,
                  //         AppLocalizations.of(context)!.duration,
                  //         AppLocalizations.of(context)!.size,
                  //       ];
                  //       final List<String> orderTypes = [
                  //         AppLocalizations.of(context)!.inc,
                  //         AppLocalizations.of(context)!.dec,
                  //       ];
                  //       final menuList = <PopupMenuEntry<int>>[];
                  //       menuList.addAll(
                  //         sortTypes
                  //             .map(
                  //               (e) => PopupMenuItem(
                  //                 value: sortTypes.indexOf(e),
                  //                 child: Row(
                  //                   children: [
                  //                     if (sortValue == sortTypes.indexOf(e))
                  //                       Icon(
                  //                         Icons.check_rounded,
                  //                         color: Theme.of(context).brightness ==
                  //                                 Brightness.dark
                  //                             ? Colors.white
                  //                             : Colors.grey[700],
                  //                       )
                  //                     else
                  //                       const SizedBox(),
                  //                     const SizedBox(width: 10),
                  //                     Text(
                  //                       e,
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             )
                  //             .toList(),
                  //       );
                  //       menuList.add(
                  //         const PopupMenuDivider(
                  //           height: 10,
                  //         ),
                  //       );
                  //       menuList.addAll(
                  //         orderTypes
                  //             .map(
                  //               (e) => PopupMenuItem(
                  //                 value:
                  //                     sortTypes.length + orderTypes.indexOf(e),
                  //                 child: Row(
                  //                   children: [
                  //                     if (orderValue == orderTypes.indexOf(e))
                  //                       Icon(
                  //                         Icons.check_rounded,
                  //                         color: Theme.of(context).brightness ==
                  //                                 Brightness.dark
                  //                             ? Colors.white
                  //                             : Colors.grey[700],
                  //                       )
                  //                     else
                  //                       const SizedBox(),
                  //                     const SizedBox(width: 10),
                  //                     Text(
                  //                       e,
                  //                     ),
                  //                   ],
                  //                 ),
                  //               ),
                  //             )
                  //             .toList(),
                  //       );
                  //       return menuList;
                  //     },
                  //   ),
                  // ],
                  centerTitle: true,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Theme.of(context).colorScheme.secondary,
                  elevation: 0,
                ),
                body: !added
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : TabBarView(
                        physics: const CustomPhysics(),
                        controller: _tcontroller,
                        children: [
                          SongsTab(
                            songs: _songs,
                            playlistId: widget.playlistId,
                            playlistName: widget.title,
                            tempPath: tempPath!,
                          ),
                          AlbumsTabDesktop(
                            albums: _albums,
                            albumsList: _sortedAlbumKeysList,
                            tempPath: tempPath!,
                          ),
                          AlbumsTabDesktop(
                            albums: _artists,
                            albumsList: _sortedArtistKeysList,
                            tempPath: tempPath!,
                          ),
                          AlbumsTabDesktop(
                            albums: _genres,
                            albumsList: _sortedGenreKeysList,
                            tempPath: tempPath!,
                          ),
                          // if (widget.showPlaylists)
                          //   LocalPlaylists(
                          //     playlistDetails: playlistDetails,
                          //     offlineAudioQuery: offlineAudioQuery,
                          //   ),
                          // videosTab(),
                        ],
                      ),
              ),
            ),
          ),
          const MiniPlayer(),
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

class SongsTab extends StatefulWidget {
  final List<Map> songs;
  final int? playlistId;
  final String? playlistName;
  final String tempPath;
  const SongsTab({
    super.key,
    required this.songs,
    required this.tempPath,
    this.playlistId,
    this.playlistName,
  });

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.songs.isEmpty
        ? emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            45,
            AppLocalizations.of(context)!.downloadSomething,
            23.0,
          )
        : Column(
            children: [
              PlaylistHead(
                songsList: widget.songs,
                offline: true,
                fromDownloads: false,
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10),
                  shrinkWrap: true,
                  itemExtent: 70.0,
                  itemCount: widget.songs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: const Image(
                          fit: BoxFit.cover,
                          height: 50,
                          width: 50,
                          image: AssetImage('assets/cover.jpg'),
                        ),
                      ),
                      title: Text(
                        widget.songs[index]['title'].toString(),
                        // widget.songs[index].title.trim() != ''
                        // ? widget.songs[index].title
                        // : widget.songs[index].displayNameWOExt,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // subtitle: Text(
                      // '${widget.songs[index].artist?.replaceAll('<unknown>', 'Unknown') ?? AppLocalizations.of(context)!.unknown} - ${widget.songs[index].album?.replaceAll('<unknown>', 'Unknown') ?? AppLocalizations.of(context)!.unknown}',
                      // overflow: TextOverflow.ellipsis,
                      // ),
                      // trailing: PopupMenuButton(
                      //   icon: const Icon(Icons.more_vert_rounded),
                      //   shape: const RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      //   ),
                      //   onSelected: (int? value) async {
                      //     if (value == 0) {
                      //       AddToOffPlaylist().addToOffPlaylist(
                      //         context,
                      //         widget.songs[index].id,
                      //       );
                      //     }
                      //     if (value == 1) {
                      //       await OfflineAudioQuery().removeFromPlaylist(
                      //         playlistId: widget.playlistId!,
                      //         audioId: widget.songs[index].id,
                      //       );
                      //       ShowSnackBar().showSnackBar(
                      //         context,
                      //         '${AppLocalizations.of(context)!.removedFrom} ${widget.playlistName}',
                      //       );
                      //     }
                      //     // if (value == 0) {
                      //     // showDialog(
                      //     // context: context,
                      //     // builder: (BuildContext context) {
                      //     // final String fileName = _cachedSongs[index].uri!;
                      //     // final List temp = fileName.split('.');
                      //     // temp.removeLast();
                      //     //           final String songName = temp.join('.');
                      //     //           final controller =
                      //     //               TextEditingController(text: songName);
                      //     //           return AlertDialog(
                      //     //             content: Column(
                      //     //               mainAxisSize: MainAxisSize.min,
                      //     //               children: [
                      //     //                 Row(
                      //     //                   children: [
                      //     //                     Text(
                      //     //                       'Name',
                      //     //                       style: TextStyle(
                      //     //                           color: Theme.of(context).accentColor),
                      //     //                     ),
                      //     //                   ],
                      //     //                 ),
                      //     //                 const SizedBox(
                      //     //                   height: 10,
                      //     //                 ),
                      //     //                 TextField(
                      //     //                     autofocus: true,
                      //     //                     controller: controller,
                      //     //                     onSubmitted: (value) async {
                      //     //                       try {
                      //     //                         Navigator.pop(context);
                      //     //                         String newName = _cachedSongs[index]
                      //     //                                 ['id']
                      //     //                             .toString()
                      //     //                             .replaceFirst(songName, value);

                      //     //                         while (await File(newName).exists()) {
                      //     //                           newName = newName.replaceFirst(
                      //     //                               value, '$value (1)');
                      //     //                         }

                      //     //                         File(_cachedSongs[index]['id']
                      //     //                                 .toString())
                      //     //                             .rename(newName);
                      //     //                         _cachedSongs[index]['id'] = newName;
                      //     //                         ShowSnackBar().showSnackBar(
                      //     //                           context,
                      //     //                           'Renamed to ${_cachedSongs[index]['id'].split('/').last}',
                      //     //                         );
                      //     //                       } catch (e) {
                      //     //                         ShowSnackBar().showSnackBar(
                      //     //                           context,
                      //     //                           'Failed to Rename ${_cachedSongs[index]['id'].split('/').last}',
                      //     //                         );
                      //     //                       }
                      //     //                       setState(() {});
                      //     //                     }),
                      //     //               ],
                      //     //             ),
                      //     //             actions: [
                      //     //               TextButton(
                      //     //                 style: TextButton.styleFrom(
                      //     //                   primary: Theme.of(context).brightness ==
                      //     //                           Brightness.dark
                      //     //                       ? Colors.white
                      //     //                       : Colors.grey[700],
                      //     //                   //       backgroundColor: Theme.of(context).accentColor,
                      //     //                 ),
                      //     //                 onPressed: () {
                      //     //                   Navigator.pop(context);
                      //     //                 },
                      //     //                 child: const Text(
                      //     //                   'Cancel',
                      //     //                 ),
                      //     //               ),
                      //     //               TextButton(
                      //     //                 style: TextButton.styleFrom(
                      //     //                   primary: Colors.white,
                      //     //                   backgroundColor:
                      //     //                       Theme.of(context).accentColor,
                      //     //                 ),
                      //     //                 onPressed: () async {
                      //     //                   try {
                      //     //                     Navigator.pop(context);
                      //     //                     String newName = _cachedSongs[index]['id']
                      //     //                         .toString()
                      //     //                         .replaceFirst(
                      //     //                             songName, controller.text);

                      //     //                     while (await File(newName).exists()) {
                      //     //                       newName = newName.replaceFirst(
                      //     //                           controller.text,
                      //     //                           '${controller.text} (1)');
                      //     //                     }

                      //     //                     File(_cachedSongs[index]['id'].toString())
                      //     //                         .rename(newName);
                      //     //                     _cachedSongs[index]['id'] = newName;
                      //     //                     ShowSnackBar().showSnackBar(
                      //     //                       context,
                      //     //                       'Renamed to ${_cachedSongs[index]['id'].split('/').last}',
                      //     //                     );
                      //     //                   } catch (e) {
                      //     //                     ShowSnackBar().showSnackBar(
                      //     //                       context,
                      //     //                       'Failed to Rename ${_cachedSongs[index]['id'].split('/').last}',
                      //     //                     );
                      //     //                   }
                      //     //                   setState(() {});
                      //     //                 },
                      //     //                 child: const Text(
                      //     //                   'Ok',
                      //     //                   style: TextStyle(color: Colors.white),
                      //     //                 ),
                      //     //               ),
                      //     //               const SizedBox(
                      //     //                 width: 5,
                      //     //               ),
                      //     //             ],
                      //     //           );
                      //     //         },
                      //     //       );
                      //     //     }
                      //     //     if (value == 1) {
                      //     //       showDialog(
                      //     //         context: context,
                      //     //         builder: (BuildContext context) {
                      //     //           Uint8List? _imageByte =
                      //     //               _cachedSongs[index]['image'] as Uint8List?;
                      //     //           String _imagePath = '';
                      //     //           final _titlecontroller = TextEditingController(
                      //     //               text: _cachedSongs[index]['title'].toString());
                      //     //           final _albumcontroller = TextEditingController(
                      //     //               text: _cachedSongs[index]['album'].toString());
                      //     //           final _artistcontroller = TextEditingController(
                      //     //               text: _cachedSongs[index]['artist'].toString());
                      //     //           final _albumArtistController = TextEditingController(
                      //     //               text: _cachedSongs[index]['albumArtist']
                      //     //                   .toString());
                      //     //           final _genrecontroller = TextEditingController(
                      //     //               text: _cachedSongs[index]['genre'].toString());
                      //     //           final _yearcontroller = TextEditingController(
                      //     //               text: _cachedSongs[index]['year'].toString());
                      //     //           final tagger = Audiotagger();
                      //     //           return AlertDialog(
                      //     //             content: SizedBox(
                      //     //               height: 400,
                      //     //               width: 300,
                      //     //               child: SingleChildScrollView(
                      //     //                 physics: const BouncingScrollPhysics(),
                      //     //                 child: Column(
                      //     //                   mainAxisSize: MainAxisSize.min,
                      //     //                   children: [
                      //     //                     GestureDetector(
                      //     //                       onTap: () async {
                      //     //                         final String filePath = await Picker()
                      //     //                             .selectFile(
                      //     //                                 context,
                      //     //                                 ['png', 'jpg', 'jpeg'],
                      //     //                                 'Pick Image');
                      //     //                         if (filePath != '') {
                      //     //                           _imagePath = filePath;
                      //     //                           final Uri myUri = Uri.parse(filePath);
                      //     //                           final Uint8List imageBytes =
                      //     //                               await File.fromUri(myUri)
                      //     //                                   .readAsBytes();
                      //     //                           _imageByte = imageBytes;
                      //     //                           final Tag tag = Tag(
                      //     //                             artwork: _imagePath,
                      //     //                           );
                      //     //                           try {
                      //     //                             await [
                      //     //                               Permission.manageExternalStorage,
                      //     //                             ].request();
                      //     //                             await tagger.writeTags(
                      //     //                               path: _cachedSongs[index]['id']
                      //     //                                   .toString(),
                      //     //                               tag: tag,
                      //     //                             );
                      //     //                           } catch (e) {
                      //     //                             await tagger.writeTags(
                      //     //                               path: _cachedSongs[index]['id']
                      //     //                                   .toString(),
                      //     //                               tag: tag,
                      //     //                             );
                      //     //                           }
                      //     //                         }
                      //     //                       },
                      //     //                       child: Card(
                      //     //                         elevation: 5,
                      //     //                         shape: RoundedRectangleBorder(
                      //     //                           borderRadius:
                      //     //                               BorderRadius.circular(7.0),
                      //     //                         ),
                      //     //                         clipBehavior: Clip.antiAlias,
                      //     //                         child: SizedBox(
                      //     //                           height: MediaQuery.of(context)
                      //     //                                   .size
                      //     //                                   .width /
                      //     //                               2,
                      //     //                           width: MediaQuery.of(context)
                      //     //                                   .size
                      //     //                                   .width /
                      //     //                               2,
                      //     //                           child: _imageByte == null
                      //     //                               ? const Image(
                      //     //                                   fit: BoxFit.cover,
                      //     //                                   image: AssetImage(
                      //     //                                       'assets/cover.jpg'),
                      //     //                                 )
                      //     //                               : Image(
                      //     //                                   fit: BoxFit.cover,
                      //     //                                   image:
                      //     //                                       MemoryImage(_imageByte!)),
                      //     //                         ),
                      //     //                       ),
                      //     //                     ),
                      //     //                     const SizedBox(height: 20.0),
                      //     //                     Row(
                      //     //                       children: [
                      //     //                         Text(
                      //     //                           'Title',
                      //     //                           style: TextStyle(
                      //     //                               color: Theme.of(context)
                      //     //                                   .accentColor),
                      //     //                         ),
                      //     //                       ],
                      //     //                     ),
                      //     //                     TextField(
                      //     //                         autofocus: true,
                      //     //                         controller: _titlecontroller,
                      //     //                         onSubmitted: (value) {}),
                      //     //                     const SizedBox(
                      //     //                       height: 30,
                      //     //                     ),
                      //     //                     Row(
                      //     //                       children: [
                      //     //                         Text(
                      //     //                           'Artist',
                      //     //                           style: TextStyle(
                      //     //                               color: Theme.of(context)
                      //     //                                   .accentColor),
                      //     //                         ),
                      //     //                       ],
                      //     //                     ),
                      //     //                     TextField(
                      //     //                         autofocus: true,
                      //     //                         controller: _artistcontroller,
                      //     //                         onSubmitted: (value) {}),
                      //     //                     const SizedBox(
                      //     //                       height: 30,
                      //     //                     ),
                      //     //                     Row(
                      //     //                       children: [
                      //     //                         Text(
                      //     //                           'Album Artist',
                      //     //                           style: TextStyle(
                      //     //                               color: Theme.of(context)
                      //     //                                   .accentColor),
                      //     //                         ),
                      //     //                       ],
                      //     //                     ),
                      //     //                     TextField(
                      //     //                         autofocus: true,
                      //     //                         controller: _albumArtistController,
                      //     //                         onSubmitted: (value) {}),
                      //     //                     const SizedBox(
                      //     //                       height: 30,
                      //     //                     ),
                      //     //                     Row(
                      //     //                       children: [
                      //     //                         Text(
                      //     //                           'Album',
                      //     //                           style: TextStyle(
                      //     //                               color: Theme.of(context)
                      //     //                                   .accentColor),
                      //     //                         ),
                      //     //                       ],
                      //     //                     ),
                      //     //                     TextField(
                      //     //                         autofocus: true,
                      //     //                         controller: _albumcontroller,
                      //     //                         onSubmitted: (value) {}),
                      //     //                     const SizedBox(
                      //     //                       height: 30,
                      //     //                     ),
                      //     //                     Row(
                      //     //                       children: [
                      //     //                         Text(
                      //     //                           'Genre',
                      //     //                           style: TextStyle(
                      //     //                               color: Theme.of(context)
                      //     //                                   .accentColor),
                      //     //                         ),
                      //     //                       ],
                      //     //                     ),
                      //     //                     TextField(
                      //     //                         autofocus: true,
                      //     //                         controller: _genrecontroller,
                      //     //                         onSubmitted: (value) {}),
                      //     //                     const SizedBox(
                      //     //                       height: 30,
                      //     //                     ),
                      //     //                     Row(
                      //     //                       children: [
                      //     //                         Text(
                      //     //                           'Year',
                      //     //                           style: TextStyle(
                      //     //                               color: Theme.of(context)
                      //     //                                   .accentColor),
                      //     //                         ),
                      //     //                       ],
                      //     //                     ),
                      //     //                     TextField(
                      //     //                         autofocus: true,
                      //     //                         controller: _yearcontroller,
                      //     //                         onSubmitted: (value) {}),
                      //     //                   ],
                      //     //                 ),
                      //     //               ),
                      //     //             ),
                      //     //             actions: [
                      //     //               TextButton(
                      //     //                 style: TextButton.styleFrom(
                      //     //                   primary: Theme.of(context).brightness ==
                      //     //                           Brightness.dark
                      //     //                       ? Colors.white
                      //     //                       : Colors.grey[700],
                      //     //                 ),
                      //     //                 onPressed: () {
                      //     //                   Navigator.pop(context);
                      //     //                 },
                      //     //                 child: const Text('Cancel'),
                      //     //               ),
                      //     //               TextButton(
                      //     //                 style: TextButton.styleFrom(
                      //     //                   primary: Colors.white,
                      //     //                   backgroundColor:
                      //     //                       Theme.of(context).accentColor,
                      //     //                 ),
                      //     //                 onPressed: () async {
                      //     //                   Navigator.pop(context);
                      //     //                   _cachedSongs[index]['title'] =
                      //     //                       _titlecontroller.text;
                      //     //                   _cachedSongs[index]['album'] =
                      //     //                       _albumcontroller.text;
                      //     //                   _cachedSongs[index]['artist'] =
                      //     //                       _artistcontroller.text;
                      //     //                   _cachedSongs[index]['albumArtist'] =
                      //     //                       _albumArtistController.text;
                      //     //                   _cachedSongs[index]['genre'] =
                      //     //                       _genrecontroller.text;
                      //     //                   _cachedSongs[index]['year'] =
                      //     //                       _yearcontroller.text;
                      //     //                   final tag = Tag(
                      //     //                     title: _titlecontroller.text,
                      //     //                     artist: _artistcontroller.text,
                      //     //                     album: _albumcontroller.text,
                      //     //                     genre: _genrecontroller.text,
                      //     //                     year: _yearcontroller.text,
                      //     //                     albumArtist: _albumArtistController.text,
                      //     //                   );
                      //     //                   try {
                      //     //                     try {
                      //     //                       await [
                      //     //                         Permission.manageExternalStorage,
                      //     //                       ].request();
                      //     //                       tagger.writeTags(
                      //     //                         path: _cachedSongs[index]['id']
                      //     //                             .toString(),
                      //     //                         tag: tag,
                      //     //                       );
                      //     //                     } catch (e) {
                      //     //                       await tagger.writeTags(
                      //     //                         path: _cachedSongs[index]['id']
                      //     //                             .toString(),
                      //     //                         tag: tag,
                      //     //                       );
                      //     //                       ShowSnackBar().showSnackBar(
                      //     //                         context,
                      //     //                         'Successfully edited tags',
                      //     //                       );
                      //     //                     }
                      //     //                   } catch (e) {
                      //     //                     ShowSnackBar().showSnackBar(
                      //     //                       context,
                      //     //                       'Failed to edit tags',
                      //     //                     );
                      //     //                   }
                      //     //                 },
                      //     //                 child: const Text(
                      //     //                   'Ok',
                      //     //                   style: TextStyle(color: Colors.white),
                      //     //                 ),
                      //     //               ),
                      //     //               const SizedBox(
                      //     //                 width: 5,
                      //     //               ),
                      //     //             ],
                      //     //           );
                      //     //         },
                      //     //       );
                      //     //     }
                      //     //     if (value == 2) {
                      //     //       try {
                      //     //         File(_cachedSongs[index]['id'].toString()).delete();
                      //     //         ShowSnackBar().showSnackBar(
                      //     //           context,
                      //     //           'Deleted ${_cachedSongs[index]['id'].split('/').last}',
                      //     //         );
                      //     //         if (_cachedAlbums[_cachedSongs[index]['album']]
                      //     //                 .length ==
                      //     //             1) {
                      //     //           sortedCachedAlbumKeysList
                      //     //               .remove(_cachedSongs[index]['album']);
                      //     //         }
                      //     //         _cachedAlbums[_cachedSongs[index]['album']]
                      //     //             .remove(_cachedSongs[index]);

                      //     //         if (_cachedArtists[_cachedSongs[index]['artist']]
                      //     //                 .length ==
                      //     //             1) {
                      //     //           sortedCachedArtistKeysList
                      //     //               .remove(_cachedSongs[index]['artist']);
                      //     //         }
                      //     //         _cachedArtists[_cachedSongs[index]['artist']]
                      //     //             .remove(_cachedSongs[index]);

                      //     //         if (_cachedGenres[_cachedSongs[index]['genre']]
                      //     //                 .length ==
                      //     //             1) {
                      //     //           sortedCachedGenreKeysList
                      //     //               .remove(_cachedSongs[index]['genre']);
                      //     //         }
                      //     //         _cachedGenres[_cachedSongs[index]['genre']]
                      //     //             .remove(_cachedSongs[index]);

                      //     //         _cachedSongs.remove(_cachedSongs[index]);
                      //     //       } catch (e) {
                      //     //         ShowSnackBar().showSnackBar(
                      //     //           context,
                      //     //           'Failed to delete ${_cachedSongs[index]['id']}',
                      //     //         );
                      //     //       }
                      //     //       setState(() {});
                      //     // }
                      //   },
                      //   itemBuilder: (context) => [
                      //     PopupMenuItem(
                      //       value: 0,
                      //       child: Row(
                      //         children: [
                      //           const Icon(Icons.playlist_add_rounded),
                      //           const SizedBox(width: 10.0),
                      //           Text(
                      //             AppLocalizations.of(context)!.addToPlaylist,
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //     if (widget.playlistId != null)
                      //       PopupMenuItem(
                      //         value: 1,
                      //         child: Row(
                      //           children: [
                      //             const Icon(Icons.delete_rounded),
                      //             const SizedBox(width: 10.0),
                      //             Text(AppLocalizations.of(context)!.remove),
                      //           ],
                      //         ),
                      //       ),
                      //     // PopupMenuItem(
                      //     //       value: 0,
                      //     //       child: Row(
                      //     //         children: const [
                      //     //           Icon(Icons.edit_rounded),
                      //     //           const SizedBox(width: 10.0),
                      //     //           Text('Rename'),
                      //     //         ],
                      //     //       ),
                      //     //     ),
                      //     //     PopupMenuItem(
                      //     //       value: 1,
                      //     //       child: Row(
                      //     //         children: const [
                      //     //           Icon(
                      //     //               // CupertinoIcons.tag
                      //     //               Icons.local_offer_rounded),
                      //     //           const SizedBox(width: 10.0),
                      //     //           Text('Edit Tags'),
                      //     //         ],
                      //     //       ),
                      //     //     ),
                      //     //     PopupMenuItem(
                      //     //       value: 2,
                      //     //       child: Row(
                      //     //         children: const [
                      //     //           Icon(Icons.delete_rounded),
                      //     //           const SizedBox(width: 10.0),
                      //     //           Text('Delete'),
                      //     //         ],
                      //     //       ),
                      //     //     ),
                      //   ],
                      // ),
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => PlayScreen(
                              songsList: widget.songs,
                              index: index,
                              offline: true,
                              fromDownloads: false,
                              fromMiniplayer: false,
                              recommend: false,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
  }
}

class AlbumsTabDesktop extends StatefulWidget {
  final Map<String, List<Map>> albums;
  final List<String> albumsList;
  final String tempPath;
  const AlbumsTabDesktop({
    super.key,
    required this.albums,
    required this.albumsList,
    required this.tempPath,
  });

  @override
  State<AlbumsTabDesktop> createState() => _AlbumsTabDesktopState();
}

class _AlbumsTabDesktopState extends State<AlbumsTabDesktop>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      shrinkWrap: true,
      itemExtent: 70.0,
      itemCount: widget.albumsList.length,
      itemBuilder: (context, index) {
        return ListTile(
          // leading: OfflineAudioQuery.offlineArtworkWidget(
          //   id: widget.albums[widget.albumsList[index]]![0].id,
          //   type: ArtworkType.AUDIO,
          //   tempPath: widget.tempPath,
          //   fileName:
          //       widget.albums[widget.albumsList[index]]![0].displayNameWOExt,
          // ),
          title: Text(
            widget.albumsList[index],
            overflow: TextOverflow.ellipsis,
          ),
          // subtitle: Text(
          //   '${widget.albums[widget.albumsList[index]]!.length} ${AppLocalizations.of(context)!.songs}',
          // ),
          onTap: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) => DownloadedSongs(
            //         title: widget.albumsList[index],
            //         cachedSongs: widget.albums[widget.albumsList[index]],
            //       ),
            //     ),
            //   );
          },
        );
      },
    );
  }
}
