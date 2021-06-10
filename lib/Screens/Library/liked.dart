import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/GradientContainers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/Screens/Library/showSongs.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Helpers/songs_count.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class LikedSongs extends StatefulWidget {
  final String playlistName;
  LikedSongs({Key key, @required this.playlistName}) : super(key: key);
  @override
  _LikedSongsState createState() => _LikedSongsState();
}

class _LikedSongsState extends State<LikedSongs>
    with SingleTickerProviderStateMixin {
  Box likedBox;
  bool added = false;
  List _songs = [];
  Map<String, List<Map>> _albums = {};
  Map<String, List<Map>> _artists = {};
  Map<String, List<Map>> _genres = {};
  List sortedAlbumKeysList = [];
  List sortedArtistKeysList = [];
  List sortedGenreKeysList = [];
  TabController _tcontroller;
  int currentIndex = 0;
  int sortValue =
      Hive.box('settings').get('playlistSortValue', defaultValue: 2);
  int albumSortValue =
      Hive.box('settings').get('albumSortValue', defaultValue: 2);

  @override
  void initState() {
    _tcontroller = TabController(length: 4, vsync: this);
    _tcontroller.addListener(changeTitle);
    getLiked();
    super.initState();
  }

  void changeTitle() {
    setState(() {
      currentIndex = _tcontroller.index;
    });
  }

  void getLiked() {
    likedBox = Hive.box(widget.playlistName);
    _songs = likedBox?.values?.toList() ?? [];
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
    for (Map element in _songs) {
      if (_albums.containsKey(element['album'])) {
        List tempAlbum = _albums[element['album']];
        tempAlbum.add(element);
        _albums.addEntries([MapEntry(element['album'], tempAlbum)]);
      } else {
        _albums.addEntries([
          MapEntry(element['album'], [element])
        ]);
      }

      if (_artists.containsKey(element['artist'])) {
        List tempArtist = _artists[element['artist']];
        tempArtist.add(element);
        _artists.addEntries([MapEntry(element['artist'], tempArtist)]);
      } else {
        _artists.addEntries([
          MapEntry(element['artist'], [element])
        ]);
      }

      if (_genres.containsKey(element['genre'])) {
        List tempGenre = _genres[element['genre']];
        tempGenre.add(element);
        _genres.addEntries([MapEntry(element['genre'], tempGenre)]);
      } else {
        _genres.addEntries([
          MapEntry(element['genre'], [element])
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

  sortSongs() {
    if (sortValue == 0) {
      _songs.sort((a, b) => a["title"]
          .toString()
          .toUpperCase()
          .compareTo(b["title"].toString().toUpperCase()));
    }
    if (sortValue == 1) {
      _songs.sort((b, a) => a["title"]
          .toString()
          .toUpperCase()
          .compareTo(b["title"].toString().toUpperCase()));
    }
    if (sortValue == 2) {
      _songs = likedBox.values.toList();
    }
    if (sortValue == 3) {
      _songs.shuffle();
    }
  }

  sortAlbums() {
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
          .sort((b, a) => _albums[a].length.compareTo(_albums[b].length));
      sortedArtistKeysList
          .sort((b, a) => _artists[a].length.compareTo(_artists[b].length));
      sortedGenreKeysList
          .sort((b, a) => _genres[a].length.compareTo(_genres[b].length));
    }
    if (albumSortValue == 3) {
      sortedAlbumKeysList
          .sort((a, b) => _albums[a].length.compareTo(_albums[b].length));
      sortedArtistKeysList
          .sort((a, b) => _artists[a].length.compareTo(_artists[b].length));
      sortedGenreKeysList
          .sort((a, b) => _genres[a].length.compareTo(_genres[b].length));
    }
    if (albumSortValue == 4) {
      sortedAlbumKeysList.shuffle();
      sortedArtistKeysList.shuffle();
      sortedGenreKeysList.shuffle();
    }
  }

  void deleteLiked(index) {
    likedBox.deleteAt(index);
    if (_albums[_songs[index]['album']].length == 1)
      sortedAlbumKeysList.remove(_songs[index]['album']);
    _albums[_songs[index]['album']].remove(_songs[index]);

    if (_artists[_songs[index]['artist']].length == 1)
      sortedArtistKeysList.remove(_songs[index]['artist']);
    _artists[_songs[index]['artist']].remove(_songs[index]);

    if (_genres[_songs[index]['genre']].length == 1)
      sortedGenreKeysList.remove(_songs[index]['genre']);
    _genres[_songs[index]['genre']].remove(_songs[index]);

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
                  title: Text(widget.playlistName[0].toUpperCase() +
                      widget.playlistName.substring(1)),
                  centerTitle: true,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Theme.of(context).accentColor,
                  elevation: 0,
                  bottom: TabBar(controller: _tcontroller, tabs: [
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
                    PopupMenuButton(
                        icon: Icon(Icons.sort_rounded),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(7.0))),
                        onSelected: (currentIndex == 0)
                            ? (value) {
                                sortValue = value;
                                Hive.box('settings').put('sortValue', value);
                                sortSongs();
                                setState(() {});
                              }
                            : (value) {
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
                                        Text('Last Added'),
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
                        children: [
                          _songs.length == 0
                              ? EmptyScreen().emptyScreen(
                                  context,
                                  3,
                                  "Nothing to ",
                                  15.0,
                                  "Show Here",
                                  50,
                                  "Go and Add Something",
                                  23.0)
                              : ListView.builder(
                                  physics: BouncingScrollPhysics(),
                                  padding: EdgeInsets.only(top: 10, bottom: 10),
                                  shrinkWrap: true,
                                  itemCount: _songs.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                        leading: Card(
                                          elevation: 5,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(7.0),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: CachedNetworkImage(
                                            errorWidget: (context, _, __) =>
                                                Image(
                                              image: AssetImage(
                                                  'assets/cover.jpg'),
                                            ),
                                            imageUrl: _songs[index]['image']
                                                .replaceAll('http:', 'https:'),
                                            placeholder: (context, url) =>
                                                Image(
                                              image: AssetImage(
                                                  'assets/cover.jpg'),
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
                                              ),
                                            ),
                                          );
                                        },
                                        title: Text(
                                          '${_songs[index]['title'].split("(")[0]}',
                                        ),
                                        subtitle: Text(
                                          '${_songs[index]['artist'] ?? 'Artist name'}',
                                        ),
                                        trailing: PopupMenuButton(
                                            icon: Icon(Icons.more_vert_rounded),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(7.0))),
                                            itemBuilder: (context) => [
                                                  PopupMenuItem(
                                                    value: 0,
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons
                                                            .delete_rounded),
                                                        Spacer(),
                                                        Text('Remove'),
                                                        Spacer(),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                            onSelected: (value) async {
                                              if (value == 0) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    elevation: 6,
                                                    backgroundColor:
                                                        Colors.grey[900],
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    content: Text(
                                                      'Removed ${_songs[index]["title"]} from ${widget.playlistName}',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    action: SnackBarAction(
                                                      textColor:
                                                          Theme.of(context)
                                                              .accentColor,
                                                      label: 'Ok',
                                                      onPressed: () {},
                                                    ),
                                                  ),
                                                );
                                                setState(() {
                                                  deleteLiked(index);
                                                });
                                              }
                                            }));
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

  albumsTab() {
    return sortedAlbumKeysList.length == 0
        ? EmptyScreen().emptyScreen(context, 3, "Nothing to ", 15.0,
            "Show Here", 50, "Go and Add Something", 23.0)
        : ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedAlbumKeysList.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Collage(
                  imageList: _albums[sortedAlbumKeysList[index]].length >= 4
                      ? _albums[sortedAlbumKeysList[index]].sublist(0, 4)
                      : _albums[sortedAlbumKeysList[index]].sublist(
                          0, _albums[sortedAlbumKeysList[index]].length),
                  placeholderImage: 'assets/album.png',
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
                        offline: false,
                      ),
                    ),
                  );
                },
              );
            });
  }

  artistsTab() {
    return (sortedArtistKeysList.isEmpty)
        ? EmptyScreen().emptyScreen(context, 3, "Nothing to ", 15.0,
            "Show Here", 50, "Go and Add Something", 23.0)
        : ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedArtistKeysList.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Collage(
                  imageList: _artists[sortedArtistKeysList[index]].length >= 4
                      ? _artists[sortedArtistKeysList[index]].sublist(0, 4)
                      : _artists[sortedArtistKeysList[index]].sublist(
                          0, _artists[sortedArtistKeysList[index]].length),
                  placeholderImage: 'assets/artist.png',
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
                        offline: false,
                      ),
                    ),
                  );
                },
              );
            });
  }

  genresTab() {
    return (sortedGenreKeysList.isEmpty)
        ? EmptyScreen().emptyScreen(context, 3, "Nothing to ", 15.0,
            "Show Here", 50, "Go and Add Something", 23.0)
        : ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 20, bottom: 10),
            shrinkWrap: true,
            itemCount: sortedGenreKeysList.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Collage(
                  imageList: _genres[sortedGenreKeysList[index]].length >= 4
                      ? _genres[sortedGenreKeysList[index]].sublist(0, 4)
                      : _genres[sortedGenreKeysList[index]].sublist(
                          0, _genres[sortedGenreKeysList[index]].length),
                  placeholderImage: 'assets/album.png',
                ),
                title: Text('${sortedGenreKeysList[index]}'),
                subtitle: Text(
                  _genres[sortedGenreKeysList[index]].length == 1
                      ? '${_genres[sortedGenreKeysList[index]].length} Song'
                      : '${_genres[sortedGenreKeysList[index]].length} Songs',
                ),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      opaque: false, // set to false
                      pageBuilder: (_, __, ___) => SongsList(
                        data: _genres[sortedGenreKeysList[index]],
                        offline: false,
                      ),
                    ),
                  );
                },
              );
            });
  }
}
