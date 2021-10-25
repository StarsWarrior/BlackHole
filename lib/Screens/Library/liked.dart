import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Helpers/songs_count.dart';
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
    getLiked();
    super.initState();
  }

  void changeTitle() {
    setState(() {
      currentIndex = _tcontroller!.index;
    });
  }

  void getLiked() {
    likedBox = Hive.box(widget.playlistName);
    _songs = likedBox?.values.toList() ?? [];
    AddSongsCount().addSong(
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
      _songs = likedBox?.values.toList() ?? [];
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
    likedBox!.deleteAt(index);
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
    AddSongsCount().addSong(
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
                            delegate: DownloadsSearch(data: _songs));
                      },
                    ),
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
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
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .tenToOne,
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
                                        Text(
                                          AppLocalizations.of(context)!
                                              .oneToTen,
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
                                        Text(
                                          AppLocalizations.of(context)!.shuffle,
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
                                AppLocalizations.of(context)!.addSomething,
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
                                          child: CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            errorWidget: (context, _, __) =>
                                                const Image(
                                              image: AssetImage(
                                                  'assets/cover.jpg'),
                                            ),
                                            imageUrl: _songs[index]['image']
                                                .toString()
                                                .replaceAll('http:', 'https:'),
                                            placeholder: (context, url) =>
                                                const Image(
                                              image: AssetImage(
                                                  'assets/cover.jpg'),
                                            ),
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
                                                'offline': false,
                                              },
                                              fromMiniplayer: false,
                                              recommend: false,
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
                                          DownloadButton(
                                              data: _songs[index] as Map,
                                              icon: 'download'),
                                          PopupMenuButton(
                                              icon: const Icon(
                                                  Icons.more_vert_rounded),
                                              shape:
                                                  const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  15.0))),
                                              itemBuilder: (context) => [
                                                    PopupMenuItem(
                                                      value: 0,
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons
                                                              .delete_rounded),
                                                          const SizedBox(
                                                              width: 10.0),
                                                          Text(AppLocalizations
                                                                  .of(context)!
                                                              .remove),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 1,
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons
                                                              .playlist_add_rounded),
                                                          const SizedBox(
                                                              width: 10.0),
                                                          Text(AppLocalizations
                                                                  .of(context)!
                                                              .addToPlaylist),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                              onSelected: (int? value) async {
                                                if (value == 1) {
                                                  AddToPlaylist().addToPlaylist(
                                                      context,
                                                      MediaItemConverter()
                                                          .mapToMediaItem(
                                                              _songs[index]
                                                                  as Map));
                                                }
                                                if (value == 0) {
                                                  ShowSnackBar().showSnackBar(
                                                    context,
                                                    '${AppLocalizations.of(context)!.removed} ${_songs[index]["title"]} ${AppLocalizations.of(context)!.from} ${widget.playlistName}',
                                                  );
                                                  setState(() {
                                                    deleteLiked(index);
                                                  });
                                                }
                                              }),
                                        ],
                                      ));
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
            AppLocalizations.of(context)!.addSomething,
            23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedAlbumKeysList.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Collage(
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
                        offline: false,
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
            AppLocalizations.of(context)!.addSomething,
            23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedArtistKeysList.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Collage(
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
                        offline: false,
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
            AppLocalizations.of(context)!.addSomething,
            23.0)
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedGenreKeysList.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Collage(
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
                        offline: false,
                      ),
                    ),
                  );
                },
              );
            });
  }
}
