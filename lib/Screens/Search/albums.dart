import 'dart:ui';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Screens/Search/album_songs.dart';
import 'package:blackhole/Screens/Search/artists.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/APIs/api.dart';

class AlbumSearchPage extends StatefulWidget {
  final String query;
  final String type;

  AlbumSearchPage({
    Key key,
    @required this.query,
    @required this.type,
  }) : super(key: key);

  @override
  _AlbumSearchPageState createState() => _AlbumSearchPageState();
}

class _AlbumSearchPageState extends State<AlbumSearchPage> {
  bool status = false;
  List searchedList = [];
  bool fetched = false;

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      switch (widget.type) {
        case 'Playlists':
          print(widget.query);
          Search().fetchAlbums(widget.query, 'playlist').then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
          break;
        case 'Albums':
          Search().fetchAlbums(widget.query, 'album').then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
          break;
        case 'Artists':
          Search().fetchAlbums(widget.query, 'artist').then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
          break;
        default:
          break;
      }
    }
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(widget.type),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                textTheme: Theme.of(context).textTheme,
                elevation: 0,
                iconTheme: Theme.of(context).iconTheme,
              ),
              body: !fetched
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
                  : searchedList.isEmpty
                      ? EmptyScreen().emptyScreen(context, 0, ":( ", 100,
                          "SORRY", 60, "Results Not Found", 20)
                      : ListView.builder(
                          itemCount: searchedList.length,
                          physics: BouncingScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.fromLTRB(5, 10, 5, 0),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(0, 7, 7, 5),
                              child: ListTile(
                                contentPadding: EdgeInsets.only(left: 15.0),
                                title: Text(
                                  '${searchedList[index]["title"]}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  '${searchedList[index]["subtitle"]}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                leading: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          widget.type == 'Artists'
                                              ? 50.0
                                              : 7.0)),
                                  clipBehavior: Clip.antiAlias,
                                  child: CachedNetworkImage(
                                    errorWidget: (context, _, __) => Image(
                                      image: AssetImage(widget.type == 'Artists'
                                          ? 'assets/artist.png'
                                          : 'assets/album.png'),
                                    ),
                                    imageUrl:
                                        '${searchedList[index]["image"].replaceAll('http:', 'https:')}',
                                    placeholder: (context, url) => Image(
                                      image: AssetImage(widget.type == 'Artists'
                                          ? 'assets/artist.png'
                                          : 'assets/album.png'),
                                    ),
                                  ),
                                ),
                                trailing: widget.type != 'Albums'
                                    ? null
                                    : AlbumDownloadButton(
                                        albumName: searchedList[index]['title'],
                                        albumId: searchedList[index]['id'],
                                      ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (_, __, ___) =>
                                          widget.type == 'Artists'
                                              ? ArtistSearchPage(
                                                  artistName:
                                                      searchedList[index]
                                                          ['title'],
                                                  artistToken:
                                                      searchedList[index]
                                                          ['artistToken'],
                                                )
                                              : AlbumSongsSearchPage(
                                                  albumName: searchedList[index]
                                                      ['title'],
                                                  albumId: searchedList[index]
                                                      ['id'],
                                                  type: widget.type,
                                                ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
