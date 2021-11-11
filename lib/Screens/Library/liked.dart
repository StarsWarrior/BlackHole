import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/playlist_head.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Helpers/songs_count.dart' as songs_count;
import 'package:blackhole/Screens/Library/show_songs.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

class LikedSongs extends StatefulWidget {
  final String playlistName;
  final String? showName;
  const LikedSongs({Key? key, required this.playlistName, this.showName})
      : super(key: key);
  @override
  _LikedSongsState createState() => _LikedSongsState();
}

class _LikedSongsState extends State<LikedSongs>
    with SingleTickerProviderStateMixin {
  Box? likedBox;
  bool added = false;
  List _songs = [];
  final Map<String, List<Map>> _albums = {};
  final Map<String, List<Map>> _artists = {};
  final Map<String, List<Map>> _genres = {};
  List _sortedAlbumKeysList = [];
  List _sortedArtistKeysList = [];
  List _sortedGenreKeysList = [];
  TabController? _tcontroller;
  int currentIndex = 0;
  int sortValue = Hive.box('settings').get('sortValue', defaultValue: 2) as int;
  int albumSortValue =
      Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;

  @override
  void initState() {
    _tcontroller = TabController(length: 4, vsync: this);
    _tcontroller!.addListener(changeTitle);
    getLiked();
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

  void getLiked() {
    likedBox = Hive.box(widget.playlistName);
    _songs = likedBox?.values.toList() ?? [];
    songs_count.addSongsCount(
      widget.playlistName,
      _songs.length,
      _songs.length >= 4
          ? _songs.sublist(0, 4)
          : _songs.sublist(0, _songs.length),
    );
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

    _sortedAlbumKeysList = _albums.keys.toList();
    _sortedArtistKeysList = _artists.keys.toList();
    _sortedGenreKeysList = _genres.keys.toList();

    sortAlbums();

    added = true;
    setState(() {});
  }

  void sortSongs() {
    if (sortValue == 0) {
      _songs.sort(
        (a, b) => a['title']
            .toString()
            .toUpperCase()
            .compareTo(b['title'].toString().toUpperCase()),
      );
    }
    if (sortValue == 1) {
      _songs.sort(
        (b, a) => a['title']
            .toString()
            .toUpperCase()
            .compareTo(b['title'].toString().toUpperCase()),
      );
    }
    if (sortValue == 2) {
      _songs.sort(
        (b, a) => a['dateAdded']
            .toString()
            .toUpperCase()
            .compareTo(b['dateAdded'].toString().toUpperCase()),
      );
    }
    if (sortValue == 3) {
      _songs.shuffle();
    }
  }

  void sortAlbums() {
    if (albumSortValue == 0) {
      _sortedAlbumKeysList.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedArtistKeysList.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedGenreKeysList.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
    }
    if (albumSortValue == 1) {
      _sortedAlbumKeysList.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedArtistKeysList.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedGenreKeysList.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
    }
    if (albumSortValue == 2) {
      _sortedAlbumKeysList
          .sort((b, a) => _albums[a]!.length.compareTo(_albums[b]!.length));
      _sortedArtistKeysList
          .sort((b, a) => _artists[a]!.length.compareTo(_artists[b]!.length));
      _sortedGenreKeysList
          .sort((b, a) => _genres[a]!.length.compareTo(_genres[b]!.length));
    }
    if (albumSortValue == 3) {
      _sortedAlbumKeysList
          .sort((a, b) => _albums[a]!.length.compareTo(_albums[b]!.length));
      _sortedArtistKeysList
          .sort((a, b) => _artists[a]!.length.compareTo(_artists[b]!.length));
      _sortedGenreKeysList
          .sort((a, b) => _genres[a]!.length.compareTo(_genres[b]!.length));
    }
    if (albumSortValue == 4) {
      _sortedAlbumKeysList.shuffle();
      _sortedArtistKeysList.shuffle();
      _sortedGenreKeysList.shuffle();
    }
  }

  void deleteLiked(Map song) {
    likedBox!.delete(song['id']);
    if (_albums[song['album']]!.length == 1) {
      _sortedAlbumKeysList.remove(song['album']);
    }
    _albums[song['album']]!.remove(song);

    if (_artists[song['artist']]!.length == 1) {
      _sortedArtistKeysList.remove(song['artist']);
    }
    _artists[song['artist']]!.remove(song);

    if (_genres[song['genre']]!.length == 1) {
      _sortedGenreKeysList.remove(song['genre']);
    }
    _genres[song['genre']]!.remove(song);

    _songs.remove(song);
    songs_count.addSongsCount(
      widget.playlistName,
      _songs.length,
      _songs.length >= 4
          ? _songs.sublist(0, 4)
          : _songs.sublist(0, _songs.length),
    );
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
                  title: Text(
                    widget.showName == null
                        ? widget.playlistName[0].toUpperCase() +
                            widget.playlistName.substring(1)
                        : widget.showName![0].toUpperCase() +
                            widget.showName!.substring(1),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  centerTitle: true,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Theme.of(context).colorScheme.secondary,
                  elevation: 0,
                  bottom: TabBar(
                    controller: _tcontroller,
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
                    ],
                  ),
                  actions: [
                    if (_songs.isNotEmpty)
                      MultiDownloadButton(
                        data: _songs,
                        playlistName: widget.showName == null
                            ? widget.playlistName[0].toUpperCase() +
                                widget.playlistName.substring(1)
                            : widget.showName![0].toUpperCase() +
                                widget.showName!.substring(1),
                      ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.search),
                      tooltip: AppLocalizations.of(context)!.search,
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: DownloadsSearch(data: _songs),
                        );
                      },
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.sort_rounded),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15.0)),
                      ),
                      onSelected: (currentIndex == 0)
                          ? (int value) {
                              sortValue = value;
                              Hive.box('settings').put('sortValue', value);
                              sortSongs();
                              setState(() {});
                            }
                          : (int value) {
                              albumSortValue = value;
                              Hive.box('settings').put('albumSortValue', value);
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
                                          color: Theme.of(context).brightness ==
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
                                          color: Theme.of(context).brightness ==
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
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )
                                      else
                                        const SizedBox(),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(context)!.lastAdded,
                                      ),
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
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )
                                      else
                                        const SizedBox(),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(context)!.shuffle,
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
                                          color: Theme.of(context).brightness ==
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
                                          color: Theme.of(context).brightness ==
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
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )
                                      else
                                        const SizedBox(),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(context)!.tenToOne,
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
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )
                                      else
                                        const SizedBox(),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(context)!.oneToTen,
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
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.grey[700],
                                        )
                                      else
                                        const SizedBox(),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(context)!.shuffle,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                    ),
                  ],
                ),
                body: !added
                    ? SizedBox(
                        child: Center(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.width / 7,
                            width: MediaQuery.of(context).size.width / 7,
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                      )
                    : TabBarView(
                        physics: const CustomPhysics(),
                        controller: _tcontroller,
                        children: [
                          SongsTab(
                            songs: _songs,
                            onDelete: (Map item) {
                              deleteLiked(item);
                            },
                            playlistName: widget.playlistName,
                          ),
                          AlbumsTab(
                            albums: _albums,
                            offline: false,
                            sortedAlbumKeysList: _sortedAlbumKeysList,
                          ),
                          AlbumsTab(
                            albums: _artists,
                            artistTab: true,
                            offline: false,
                            sortedAlbumKeysList: _sortedArtistKeysList,
                          ),
                          AlbumsTab(
                            albums: _genres,
                            offline: false,
                            sortedAlbumKeysList: _sortedGenreKeysList,
                          ),
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
}

class SongsTab extends StatefulWidget {
  final List songs;
  final String playlistName;
  final Function(Map item) onDelete;
  const SongsTab({
    Key? key,
    required this.songs,
    required this.onDelete,
    required this.playlistName,
  }) : super(key: key);

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
    return (widget.songs.isEmpty)
        ? emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            50,
            AppLocalizations.of(context)!.addSomething,
            23.0,
          )
        : Column(
            children: [
              PlaylistHead(
                songsList: widget.songs,
                offline: false,
                fromDownloads: false,
                recommend: false,
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10),
                  shrinkWrap: true,
                  itemCount: widget.songs.length,
                  itemExtent: 70.0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          height: 50.0,
                          width: 50.0,
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            errorWidget: (context, _, __) => const Image(
                              fit: BoxFit.cover,
                              image: AssetImage(
                                'assets/cover.jpg',
                              ),
                            ),
                            imageUrl: widget.songs[index]['image']
                                .toString()
                                .replaceAll('http:', 'https:'),
                            placeholder: (context, url) => const Image(
                              fit: BoxFit.cover,
                              image: AssetImage(
                                'assets/cover.jpg',
                              ),
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => PlayScreen(
                              songsList: widget.songs,
                              index: index,
                              offline: false,
                              fromMiniplayer: false,
                              fromDownloads: false,
                              recommend: false,
                            ),
                          ),
                        );
                      },
                      title: Text(
                        '${widget.songs[index]['title']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${widget.songs[index]['artist'] ?? 'Artist name'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DownloadButton(
                            data: widget.songs[index] as Map,
                            icon: 'download',
                          ),
                          PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15.0),
                              ),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 0,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_rounded,
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!
                                          .remove,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.playlist_add_rounded,
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!
                                          .addToPlaylist,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (int? value) async {
                              if (value == 1) {
                                AddToPlaylist().addToPlaylist(
                                  context,
                                  MediaItemConverter.mapToMediaItem(
                                    widget.songs[index] as Map,
                                  ),
                                );
                              }
                              if (value == 0) {
                                ShowSnackBar().showSnackBar(
                                  context,
                                  '${AppLocalizations.of(context)!.removed} ${widget.songs[index]["title"]} ${AppLocalizations.of(context)!.from} ${widget.playlistName}',
                                );
                                setState(() {
                                  widget.onDelete(widget.songs[index] as Map);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}

class AlbumsTab extends StatefulWidget {
  final Map<String, List> albums;
  final List sortedAlbumKeysList;
  final bool artistTab;
  final bool offline;
  const AlbumsTab({
    Key? key,
    required this.albums,
    required this.offline,
    required this.sortedAlbumKeysList,
    this.artistTab = false,
  }) : super(key: key);

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.sortedAlbumKeysList.isEmpty
        ? emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            50,
            AppLocalizations.of(context)!.addSomething,
            23.0,
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 10),
            shrinkWrap: true,
            itemExtent: 70.0,
            itemCount: widget.sortedAlbumKeysList.length,
            itemBuilder: (context, index) {
              final List imageList = widget
                          .albums[widget.sortedAlbumKeysList[index]]!.length >=
                      4
                  ? widget.albums[widget.sortedAlbumKeysList[index]]!
                      .sublist(0, 4)
                  : widget.albums[widget.sortedAlbumKeysList[index]]!.sublist(
                      0,
                      widget.albums[widget.sortedAlbumKeysList[index]]!.length,
                    );
              return ListTile(
                leading: widget.offline
                    ? OfflineCollage(
                        imageList: imageList,
                        placeholderImage: widget.artistTab
                            ? 'assets/artist.png'
                            : 'assets/album.png',
                      )
                    : Collage(
                        imageList: imageList,
                        placeholderImage: widget.artistTab
                            ? 'assets/artist.png'
                            : 'assets/album.png',
                      ),
                title: Text(
                  '${widget.sortedAlbumKeysList[index]}',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  widget.albums[widget.sortedAlbumKeysList[index]]!.length == 1
                      ? '${widget.albums[widget.sortedAlbumKeysList[index]]!.length} ${AppLocalizations.of(context)!.song}'
                      : '${widget.albums[widget.sortedAlbumKeysList[index]]!.length} ${AppLocalizations.of(context)!.songs}',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false,
                      pageBuilder: (_, __, ___) => SongsList(
                        data: widget.albums[widget.sortedAlbumKeysList[index]]!,
                        offline: widget.offline,
                      ),
                    ),
                  );
                },
              );
            },
          );
  }
}
