import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/audiofile.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Screens/Library/show_songs.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';

class DownloadedSongs extends StatefulWidget {
  final String type;
  const DownloadedSongs({Key? key, required this.type}) : super(key: key);
  @override
  _DownloadedSongsState createState() => _DownloadedSongsState();
}

class _DownloadedSongsState extends State<DownloadedSongs>
    with SingleTickerProviderStateMixin {
  Map _cachedAlbums = {};
  Map _cachedArtists = {};
  Map _cachedGenres = {};

  List sortedCachedAlbumKeysList = [];
  List sortedCachedArtistKeysList = [];
  List sortedCachedGenreKeysList = [];

  List _cachedSongs = [];
  List _cachedVideos = [];
  bool added = false;
  int sortValue = Hive.box('settings').get('sortValue', defaultValue: 2) as int;
  int albumSortValue =
      Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;
  List dirPaths =
      Hive.box('settings').get('searchPaths', defaultValue: []) as List;
  TabController? _tcontroller;
  int currentIndex = 0;

  @override
  void initState() {
    _tcontroller =
        TabController(length: widget.type == 'all' ? 5 : 4, vsync: this);
    _tcontroller!.addListener(changeTitle);
    getCached();
    getDownloaded();
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

  Future<void> getCached() async {
    if (widget.type == 'all') {
      _cachedSongs =
          Hive.box('cache').get('cachedSongs', defaultValue: []) as List;
      _cachedVideos =
          Hive.box('cache').get('cachedVideos', defaultValue: []) as List;
      _cachedAlbums =
          Hive.box('cache').get('cachedAlbums', defaultValue: {}) as Map;
      _cachedArtists =
          Hive.box('cache').get('cachedArtists', defaultValue: {}) as Map;
      _cachedGenres =
          Hive.box('cache').get('cachedGenres', defaultValue: {}) as Map;
    } else {
      _cachedSongs = Hive.box('cache')
          .get('cachedDownloadedSongs', defaultValue: []) as List;
      _cachedAlbums = Hive.box('cache')
          .get('cachedDownloadedAlbums', defaultValue: {}) as Map;
      _cachedArtists = Hive.box('cache')
          .get('cachedDownloadedArtists', defaultValue: {}) as Map;
      _cachedGenres = Hive.box('cache')
          .get('cachedDownloadedGenres', defaultValue: {}) as Map;
    }
    if (_cachedSongs.isEmpty) return;
    sortSongs(_cachedSongs, _cachedVideos);
    sortedCachedAlbumKeysList = _cachedAlbums.keys.toList();
    sortedCachedArtistKeysList = _cachedArtists.keys.toList();
    sortedCachedGenreKeysList = _cachedGenres.keys.toList();
    sortAlbums(
        sortedCachedAlbumKeysList,
        sortedCachedArtistKeysList,
        sortedCachedGenreKeysList,
        _cachedAlbums,
        _cachedArtists,
        _cachedGenres);
    added = true;
    setState(() {});
  }

  void sortSongs(List songs, List videos) {
    if (sortValue == 0) {
      songs.sort((a, b) => a['id']
          .split('/')
          .last
          .toString()
          .toUpperCase()
          .compareTo(b['id'].split('/').last.toString().toUpperCase()));
      videos.sort((a, b) => a['id']
          .split('/')
          .last
          .toString()
          .toUpperCase()
          .compareTo(b['id'].split('/').last.toString().toUpperCase()));
    }
    if (sortValue == 1) {
      songs.sort((b, a) => a['id']
          .split('/')
          .last
          .toString()
          .toUpperCase()
          .compareTo(b['id'].split('/').last.toString().toUpperCase()));
      videos.sort((b, a) => a['id']
          .split('/')
          .last
          .toString()
          .toUpperCase()
          .compareTo(b['id'].split('/').last.toString().toUpperCase()));
    }
    if (sortValue == 2) {
      songs.sort((b, a) =>
          a['lastModified'].toString().compareTo(b['lastModified'].toString()));
      videos.sort((b, a) =>
          a['lastModified'].toString().compareTo(b['lastModified'].toString()));
    }
    if (sortValue == 3) {
      songs.shuffle();
      videos.shuffle();
    }
  }

  void sortAlbums(List _sortedAlbumKeysList, List _sortedArtistKeysList,
      List _sortedGenreKeysList, Map albums, Map artists, Map genres) {
    if (albumSortValue == 0) {
      _sortedAlbumKeysList.sort((a, b) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
      _sortedArtistKeysList.sort((a, b) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
      _sortedGenreKeysList.sort((a, b) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
    }
    if (albumSortValue == 1) {
      _sortedAlbumKeysList.sort((b, a) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
      _sortedArtistKeysList.sort((b, a) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
      _sortedGenreKeysList.sort((b, a) =>
          a.toString().toUpperCase().compareTo(b.toString().toUpperCase()));
    }
    if (albumSortValue == 2) {
      _sortedAlbumKeysList.sort((b, a) =>
          (albums[a] as List).length.compareTo((albums[b] as List).length));
      _sortedArtistKeysList.sort((b, a) =>
          (artists[a] as List).length.compareTo((artists[b] as List).length));
      _sortedGenreKeysList.sort((b, a) =>
          (genres[a] as List).length.compareTo((genres[b] as List).length));
    }
    if (albumSortValue == 3) {
      _sortedAlbumKeysList.sort((a, b) =>
          (albums[a] as List).length.compareTo((albums[b] as List).length));
      _sortedArtistKeysList.sort((a, b) =>
          (artists[a] as List).length.compareTo((artists[b] as List).length));
      _sortedGenreKeysList.sort((a, b) =>
          (genres[a] as List).length.compareTo((genres[b] as List).length));
    }
    if (albumSortValue == 4) {
      _sortedAlbumKeysList.shuffle();
      _sortedArtistKeysList.shuffle();
      _sortedGenreKeysList.shuffle();
    }
  }

  Future<void> fetchDownloaded() async {
    final List _songs = [];
    final List _videos = [];
    List sortedAlbumKeysList = [];
    List sortedArtistKeysList = [];
    List sortedGenreKeysList = [];
    final List<FileSystemEntity> _files = [];
    final Map<String, List<Map>> _albums = {};
    final Map<String, List<Map>> _artists = {};
    final Map<String, List<Map>> _genres = {};
    final Audiotagger tagger = Audiotagger();

    for (final path in dirPaths) {
      try {
        final Directory dir = Directory(path.toString());
        _files.addAll(dir.listSync(recursive: true, followLinks: false));
      } catch (e) {
        // print('failed');
      }
    }

    for (final FileSystemEntity entity in _files) {
      if (entity.path.endsWith('.mp3') ||
          entity.path.endsWith('.m4a') ||
          entity.path.endsWith('.wav') ||
          entity.path.endsWith('.flac')) {
        try {
          final Tag? tags = await tagger.readTags(path: entity.path);
          final FileStat stats = await entity.stat();
          if (stats.size < 1048576) {
            debugPrint('Size of mediaItem found less than 1 MB');
            debugPrint('Ignoring media: ${entity.path}');
          } else {
            if (widget.type != 'all' && tags?.comment != 'BlackHole') {
              continue;
            }
            final AudioFile? audioFile =
                await tagger.readAudioFile(path: entity.path);
            String albumTag = tags?.album ?? '';
            String artistTag = tags?.artist ?? '';
            String genreTag = tags?.genre ?? '';
            if (artistTag.trim() == '') artistTag = 'Unknown';

            if (albumTag.trim() == '') albumTag = 'Unknown';

            if (genreTag.trim() == '') genreTag = 'Unknown';

            final Map data = {
              'id': entity.path,
              'image': await tagger.readArtwork(path: entity.path),
              'title': tags?.title ?? '',
              'artist': artistTag,
              'albumArtist': tags?.albumArtist,
              'album': albumTag,
              'lastModified': stats.modified,
              'genre': genreTag,
              'year': tags?.year,
              'duration': audioFile?.length,
            };
            _songs.add(data);

            if (_albums.containsKey(albumTag)) {
              final List<Map> tempAlbum = _albums[albumTag]!;
              tempAlbum.add(data);
              _albums.addEntries([MapEntry(albumTag, tempAlbum)]);
            } else {
              _albums.addEntries([
                MapEntry(albumTag, [data])
              ]);
            }

            if (_artists.containsKey(artistTag)) {
              final List<Map> tempArtist = _artists[artistTag]!;
              tempArtist.add(data);
              _artists.addEntries([MapEntry(artistTag, tempArtist)]);
            } else {
              _artists.addEntries([
                MapEntry(artistTag, [data])
              ]);
            }

            if (_genres.containsKey(genreTag)) {
              final List<Map> tempGenre = _genres[genreTag]!;
              tempGenre.add(data);
              _genres.addEntries([MapEntry(genreTag, tempGenre)]);
            } else {
              _genres.addEntries([
                MapEntry(genreTag, [data])
              ]);
            }
          }
        } catch (e) {
          // print('Error: $e');
        }
      }

      if (widget.type == 'all' &&
          (entity.path.endsWith('.mp4') ||
              entity.path.endsWith('.mkv') ||
              entity.path.endsWith('.webm') ||
              entity.path.endsWith('.opus'))) {
        try {
          final FileStat stats = await entity.stat();
          if (stats.size < 1048576) {
            debugPrint('Size of mediaItem found less than 1 MB');
            debugPrint('Ignoring media: ${entity.path}');
          } else {
            _videos.add({
              'id': entity.path,
              'image': null,
              'title': entity.path.split('/').last.toString(),
              'artist': '',
              'albumArtist': '',
              'album': '',
              'lastModified': stats.modified,
              'year': '',
              'genre': '',
            });
          }
        } catch (e) {
          // print('Error: $e');
        }
      }
    }
    sortSongs(_songs, _videos);

    sortedAlbumKeysList = _albums.keys.toList();
    sortedArtistKeysList = _artists.keys.toList();
    sortedGenreKeysList = _genres.keys.toList();

    sortAlbums(sortedAlbumKeysList, sortedArtistKeysList, sortedGenreKeysList,
        _albums, _artists, _genres);

    if (widget.type == 'all') {
      Hive.box('cache').put('cachedSongs', _songs);
      Hive.box('cache').put('cachedVideos', _videos);
      Hive.box('cache').put('cachedAlbums', _albums);
      Hive.box('cache').put('cachedArtists', _artists);
      Hive.box('cache').put('cachedGenres', _genres);
    } else {
      Hive.box('cache').put('cachedDownloadedSongs', _songs);
      Hive.box('cache').put('cachedDownloadedAlbums', _albums);
      Hive.box('cache').put('cachedDownloadedArtists', _artists);
      Hive.box('cache').put('cachedDownloadedGenres', _genres);
    }

    _cachedSongs = _songs;
    _cachedVideos = _videos;
    _cachedAlbums = _albums;
    _cachedGenres = _genres;
    _cachedArtists = _artists;
    sortedCachedAlbumKeysList = sortedAlbumKeysList;
    sortedCachedArtistKeysList = sortedArtistKeysList;
    sortedCachedGenreKeysList = sortedGenreKeysList;
  }

  Future<void> getDownloaded() async {
    PermissionStatus status = await Permission.storage.status;
    if (status.isRestricted || status.isDenied) {
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      debugPrint(statuses[Permission.storage].toString());
    }
    status = await Permission.storage.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      return;
    }
    if (dirPaths.isEmpty) {
      final String? path = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_MUSIC);
      dirPaths.add(path);
      final String? path2 = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_DOWNLOADS);
      dirPaths.add(path2);
      Hive.box('settings').put('searchPaths', dirPaths);
    }
    await fetchDownloaded();

    added = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: DefaultTabController(
              length: widget.type == 'all' ? 5 : 4,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(widget.type == 'all' ? 'My Music' : 'Downloads'),
                  bottom: TabBar(
                    controller: _tcontroller,
                    tabs: widget.type == 'all'
                        ? [
                            const Tab(
                              text: 'Songs',
                            ),
                            const Tab(
                              text: 'Albums',
                            ),
                            const Tab(
                              text: 'Artists',
                            ),
                            const Tab(
                              text: 'Genres',
                            ),
                            const Tab(
                              text: 'Videos',
                            )
                          ]
                        : [
                            const Tab(
                              text: 'Songs',
                            ),
                            const Tab(
                              text: 'Albums',
                            ),
                            const Tab(
                              text: 'Artists',
                            ),
                            const Tab(
                              text: 'Genres',
                            ),
                          ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.search),
                      onPressed: () {
                        showSearch(
                            context: context,
                            delegate: DataSearch(_cachedSongs));
                      },
                    ),
                    PopupMenuButton(
                        icon: const Icon(Icons.sort_rounded),
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(7.0))),
                        onSelected: (currentIndex == 0 || currentIndex == 4)
                            ? (int value) {
                                sortValue = value;
                                Hive.box('settings').put('sortValue', value);
                                sortSongs(_cachedSongs, _cachedVideos);
                                setState(() {});
                              }
                            : (int value) {
                                albumSortValue = value;
                                Hive.box('settings')
                                    .put('albumSortValue', value);
                                sortAlbums(
                                    sortedCachedAlbumKeysList,
                                    sortedCachedArtistKeysList,
                                    sortedCachedGenreKeysList,
                                    _cachedAlbums,
                                    _cachedArtists,
                                    _cachedGenres);
                                setState(() {});
                              },
                        itemBuilder: (currentIndex == 0 || currentIndex == 4)
                            ? (context) => [
                                  PopupMenuItem(
                                    value: 0,
                                    child: Row(
                                      children: [
                                        if (sortValue == 0)
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        const Text('Last Modified'),
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                  centerTitle: true,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Theme.of(context).accentColor,
                  elevation: 0,
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
                        children: widget.type == 'all'
                            ? [
                                songsTab(),
                                albumsTab(),
                                artistsTab(),
                                genresTab(),
                                videosTab(),
                              ]
                            : [
                                songsTab(),
                                albumsTab(),
                                artistsTab(),
                                genresTab(),
                              ]),
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }

  Widget songsTab() {
    return _cachedSongs.isEmpty
        ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15.0,
            'Show Here', 45, 'Download Something', 23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemExtent: 70.0,
            itemCount: _cachedSongs.length,
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
                      const Image(
                        image: AssetImage('assets/cover.jpg'),
                      ),
                      if (_cachedSongs[index]['image'] == null)
                        const SizedBox()
                      else
                        SizedBox(
                          height: 50.0,
                          width: 50.0,
                          child: Image(
                            fit: BoxFit.cover,
                            image: MemoryImage(
                                _cachedSongs[index]['image'] as Uint8List),
                          ),
                        )
                    ],
                  ),
                ),
                title: Text(
                  _cachedSongs[index]['title'] != null &&
                          _cachedSongs[index]['title'].trim() != ''
                      ? _cachedSongs[index]['title'].toString()
                      : _cachedSongs[index]['id'].toString().split('/').last,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _cachedSongs[index]['artist']?.toString() ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(7.0))),
                  onSelected: (int? value) async {
                    if (value == 0) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final String fileName = _cachedSongs[index]['id']
                              .split('/')
                              .last
                              .toString();
                          final List temp = fileName.split('.');
                          temp.removeLast();
                          final String songName = temp.join('.');
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
                                const SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                    autofocus: true,
                                    controller: controller,
                                    onSubmitted: (value) async {
                                      try {
                                        Navigator.pop(context);
                                        String newName = _cachedSongs[index]
                                                ['id']
                                            .toString()
                                            .replaceFirst(songName, value);

                                        while (await File(newName).exists()) {
                                          newName = newName.replaceFirst(
                                              value, '$value (1)');
                                        }

                                        File(_cachedSongs[index]['id']
                                                .toString())
                                            .rename(newName);
                                        _cachedSongs[index]['id'] = newName;
                                        ShowSnackBar().showSnackBar(
                                          context,
                                          'Renamed to ${_cachedSongs[index]['id'].split('/').last}',
                                        );
                                      } catch (e) {
                                        ShowSnackBar().showSnackBar(
                                          context,
                                          'Failed to Rename ${_cachedSongs[index]['id'].split('/').last}',
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
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Cancel',
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.white,
                                  backgroundColor:
                                      Theme.of(context).accentColor,
                                ),
                                onPressed: () async {
                                  try {
                                    Navigator.pop(context);
                                    String newName = _cachedSongs[index]['id']
                                        .toString()
                                        .replaceFirst(
                                            songName, controller.text);

                                    while (await File(newName).exists()) {
                                      newName = newName.replaceFirst(
                                          controller.text,
                                          '${controller.text} (1)');
                                    }

                                    File(_cachedSongs[index]['id'].toString())
                                        .rename(newName);
                                    _cachedSongs[index]['id'] = newName;
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      'Renamed to ${_cachedSongs[index]['id'].split('/').last}',
                                    );
                                  } catch (e) {
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      'Failed to Rename ${_cachedSongs[index]['id'].split('/').last}',
                                    );
                                  }
                                  setState(() {});
                                },
                                child: const Text(
                                  'Ok',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(
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
                              text: _cachedSongs[index]['title'].toString());
                          final _albumcontroller = TextEditingController(
                              text: _cachedSongs[index]['album'].toString());
                          final _artistcontroller = TextEditingController(
                              text: _cachedSongs[index]['artist'].toString());
                          final _albumArtistController = TextEditingController(
                              text: _cachedSongs[index]['albumArtist']
                                  .toString());
                          final _genrecontroller = TextEditingController(
                              text: _cachedSongs[index]['genre'].toString());
                          final _yearcontroller = TextEditingController(
                              text: _cachedSongs[index]['year'].toString());
                          return AlertDialog(
                            content: SizedBox(
                              height: 400,
                              width: 300,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Title',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .accentColor),
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
                                          'Artist',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .accentColor),
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
                                          'Album Artist',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .accentColor),
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
                                          'Album',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .accentColor),
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
                                          'Genre',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .accentColor),
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
                                          'Year',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .accentColor),
                                        ),
                                      ],
                                    ),
                                    TextField(
                                        autofocus: true,
                                        controller: _yearcontroller,
                                        onSubmitted: (value) {}),
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.white,
                                  backgroundColor:
                                      Theme.of(context).accentColor,
                                ),
                                onPressed: () async {
                                  try {
                                    Navigator.pop(context);
                                    _cachedSongs[index]['title'] =
                                        _titlecontroller.text;
                                    _cachedSongs[index]['album'] =
                                        _albumcontroller.text;
                                    _cachedSongs[index]['artist'] =
                                        _artistcontroller.text;
                                    _cachedSongs[index]['albumArtist'] =
                                        _albumArtistController.text;
                                    _cachedSongs[index]['genre'] =
                                        _genrecontroller.text;
                                    _cachedSongs[index]['year'] =
                                        _yearcontroller.text;
                                    final tag = Tag(
                                      title: _titlecontroller.text,
                                      artist: _artistcontroller.text,
                                      album: _albumcontroller.text,
                                      genre: _genrecontroller.text,
                                      year: _yearcontroller.text,
                                      albumArtist: _albumArtistController.text,
                                    );

                                    final tagger = Audiotagger();
                                    await tagger.writeTags(
                                      path:
                                          _cachedSongs[index]['id'].toString(),
                                      tag: tag,
                                    );
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      'Successfully edited tags',
                                    );
                                  } catch (e) {
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      'Failed to edit tags',
                                    );
                                  }
                                },
                                child: const Text(
                                  'Ok',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (value == 2) {
                      try {
                        File(_cachedSongs[index]['id'].toString()).delete();
                        ShowSnackBar().showSnackBar(
                          context,
                          'Deleted ${_cachedSongs[index]['id'].split('/').last}',
                        );
                        if (_cachedAlbums[_cachedSongs[index]['album']]
                                .length ==
                            1) {
                          sortedCachedAlbumKeysList
                              .remove(_cachedSongs[index]['album']);
                        }
                        _cachedAlbums[_cachedSongs[index]['album']]
                            .remove(_cachedSongs[index]);

                        if (_cachedArtists[_cachedSongs[index]['artist']]
                                .length ==
                            1) {
                          sortedCachedArtistKeysList
                              .remove(_cachedSongs[index]['artist']);
                        }
                        _cachedArtists[_cachedSongs[index]['artist']]
                            .remove(_cachedSongs[index]);

                        if (_cachedGenres[_cachedSongs[index]['genre']]
                                .length ==
                            1) {
                          sortedCachedGenreKeysList
                              .remove(_cachedSongs[index]['genre']);
                        }
                        _cachedGenres[_cachedSongs[index]['genre']]
                            .remove(_cachedSongs[index]);

                        _cachedSongs.remove(_cachedSongs[index]);
                      } catch (e) {
                        ShowSnackBar().showSnackBar(
                          context,
                          'Failed to delete ${_cachedSongs[index]['id']}',
                        );
                      }
                      setState(() {});
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: const [
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
                        children: const [
                          Icon(
                              // CupertinoIcons.tag
                              Icons.local_offer_rounded),
                          Spacer(),
                          Text('Edit Tags'),
                          Spacer(),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Row(
                        children: const [
                          Icon(Icons.delete_rounded),
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
                          'response': _cachedSongs,
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

  Widget albumsTab() {
    return sortedCachedAlbumKeysList.isEmpty
        ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15.0,
            'Show Here', 45, 'Download Something', 23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemExtent: 70.0,
            itemCount: sortedCachedAlbumKeysList.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: OfflineCollage(
                  imageList: (_cachedAlbums[sortedCachedAlbumKeysList[index]]
                                  as List)
                              .length >=
                          4
                      ? (_cachedAlbums[sortedCachedAlbumKeysList[index]]
                              as List)
                          .sublist(0, 4)
                      : (_cachedAlbums[sortedCachedAlbumKeysList[index]]
                              as List)
                          .sublist(
                              0,
                              (_cachedAlbums[sortedCachedAlbumKeysList[index]]
                                      as List)
                                  .length),
                  placeholderImage: 'assets/album.png',
                ),
                title: Text(
                  '${sortedCachedAlbumKeysList[index]}',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _cachedAlbums[sortedCachedAlbumKeysList[index]].length == 1
                      ? '${_cachedAlbums[sortedCachedAlbumKeysList[index]].length} Song'
                      : '${_cachedAlbums[sortedCachedAlbumKeysList[index]].length} Songs',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => SongsList(
                        data: _cachedAlbums[sortedCachedAlbumKeysList[index]]
                            as List,
                        offline: true,
                      ),
                    ),
                  );
                },
              );
            });
  }

  Widget artistsTab() {
    return sortedCachedArtistKeysList.isEmpty
        ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15.0,
            'Show Here', 45, 'Download Something', 23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemExtent: 70.0,
            itemCount: sortedCachedArtistKeysList.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: OfflineCollage(
                  imageList: (_cachedArtists[sortedCachedArtistKeysList[index]]
                                  as List)
                              .length >=
                          4
                      ? (_cachedArtists[sortedCachedArtistKeysList[index]]
                              as List)
                          .sublist(0, 4)
                      : (_cachedArtists[sortedCachedArtistKeysList[index]]
                              as List)
                          .sublist(
                              0,
                              (_cachedArtists[sortedCachedArtistKeysList[index]]
                                      as List)
                                  .length),
                  placeholderImage: 'assets/artist.png',
                ),
                title: Text(
                  '${sortedCachedArtistKeysList[index]}',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _cachedArtists[sortedCachedArtistKeysList[index]].length == 1
                      ? '${_cachedArtists[sortedCachedArtistKeysList[index]].length} Song'
                      : '${_cachedArtists[sortedCachedArtistKeysList[index]].length} Songs',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => SongsList(
                        data: _cachedArtists[sortedCachedArtistKeysList[index]]
                            as List,
                        offline: true,
                      ),
                    ),
                  );
                },
              );
            });
  }

  Widget genresTab() {
    return sortedCachedGenreKeysList.isEmpty
        ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15.0,
            'Show Here', 45, 'Download Something', 23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemExtent: 70.0,
            itemCount: sortedCachedGenreKeysList.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: OfflineCollage(
                  imageList: (_cachedGenres[sortedCachedGenreKeysList[index]]
                                  as List)
                              .length >=
                          4
                      ? (_cachedGenres[sortedCachedGenreKeysList[index]]
                              as List)
                          .sublist(0, 4)
                      : (_cachedGenres[sortedCachedGenreKeysList[index]]
                              as List)
                          .sublist(
                              0,
                              (_cachedGenres[sortedCachedGenreKeysList[index]]
                                      as List)
                                  .length),
                  placeholderImage: 'assets/album.png',
                ),
                title: Text(
                  '${sortedCachedGenreKeysList[index]}',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  _cachedGenres[sortedCachedGenreKeysList[index]].length == 1
                      ? '${_cachedGenres[sortedCachedGenreKeysList[index]].length} Song'
                      : '${_cachedGenres[sortedCachedGenreKeysList[index]].length} Songs',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => SongsList(
                        data: _cachedGenres[sortedCachedGenreKeysList[index]]
                            as List,
                        offline: true,
                      ),
                    ),
                  );
                },
              );
            });
  }

  Widget videosTab() {
    return _cachedVideos.isEmpty
        ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15.0,
            'Show Here', 45, 'Download Something', 23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemExtent: 70.0,
            itemCount: _cachedVideos.length,
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
                      const Image(
                        image: AssetImage('assets/cover.jpg'),
                      ),
                      if (_cachedVideos[index]['image'] == null)
                        const SizedBox()
                      else
                        SizedBox(
                          height: 50.0,
                          width: 50.0,
                          child: Image(
                            fit: BoxFit.cover,
                            image: MemoryImage(
                                _cachedVideos[index]['image'] as Uint8List),
                          ),
                        ),
                    ],
                  ),
                ),
                title: Text(
                  '${_cachedVideos[index]['id'].split('/').last}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(7.0))),
                  onSelected: (dynamic value) async {
                    if (value == 0) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final String fileName = _cachedVideos[index]['id']
                              .split('/')
                              .last
                              .toString();
                          final List temp = fileName.split('.');
                          temp.removeLast();
                          final String videoName = temp.join('.');
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
                                const SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                    autofocus: true,
                                    controller: controller,
                                    onSubmitted: (value) async {
                                      try {
                                        Navigator.pop(context);
                                        String newName = _cachedVideos[index]
                                                ['id']
                                            .toString()
                                            .replaceFirst(videoName, value);

                                        while (await File(newName).exists()) {
                                          newName = newName.replaceFirst(
                                              value, '$value (1)');
                                        }

                                        File(_cachedVideos[index]['id']
                                                .toString())
                                            .rename(newName);
                                        _cachedVideos[index]['id'] = newName;
                                        ShowSnackBar().showSnackBar(
                                          context,
                                          'Renamed to ${_cachedVideos[index]['id'].split('/').last}',
                                        );
                                      } catch (e) {
                                        ShowSnackBar().showSnackBar(
                                          context,
                                          'Failed to Rename ${_cachedVideos[index]['id'].split('/').last}',
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
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Cancel',
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.white,
                                  backgroundColor:
                                      Theme.of(context).accentColor,
                                ),
                                onPressed: () async {
                                  try {
                                    Navigator.pop(context);
                                    String newName = _cachedVideos[index]['id']
                                        .toString()
                                        .replaceFirst(
                                            videoName, controller.text);

                                    while (await File(newName).exists()) {
                                      newName = newName.replaceFirst(
                                          controller.text,
                                          '${controller.text} (1)');
                                    }

                                    File(_cachedVideos[index]['id'].toString())
                                        .rename(newName);
                                    _cachedVideos[index]['id'] = newName;
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      'Renamed to ${_cachedVideos[index]['id'].split('/').last}',
                                    );
                                  } catch (e) {
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      'Failed to Rename ${_cachedVideos[index]['id'].split('/').last}',
                                    );
                                  }
                                  setState(() {});
                                },
                                child: const Text(
                                  'Ok',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                            ],
                          );
                        },
                      );
                    }
                    if (value == 1) {
                      try {
                        File(_cachedVideos[index]['id'].toString()).delete();
                        ShowSnackBar().showSnackBar(
                          context,
                          'Deleted ${_cachedVideos[index]['id'].split('/').last}',
                        );
                        _cachedVideos.remove(_cachedVideos[index]);
                      } catch (e) {
                        ShowSnackBar().showSnackBar(
                          context,
                          'Failed to delete ${_cachedVideos[index]['id']}',
                        );
                      }
                      setState(() {});
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 0,
                      child: Row(
                        children: const [
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
                        children: const [
                          Icon(Icons.delete_rounded),
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
                          'response': _cachedVideos,
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
