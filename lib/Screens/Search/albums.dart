import 'dart:ui';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
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
          SaavnAPI().fetchAlbums(widget.query, 'playlist').then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
          break;
        case 'Albums':
          SaavnAPI().fetchAlbums(widget.query, 'album').then((value) {
            setState(() {
              searchedList = value;
              fetched = true;
            });
          });
          break;
        case 'Artists':
          SaavnAPI().fetchAlbums(widget.query, 'artist').then((value) {
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
              body: !fetched
                  ? Container(
                      child: Center(
                        child: Container(
                            height: MediaQuery.of(context).size.width / 7,
                            width: MediaQuery.of(context).size.width / 7,
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
                      : CustomScrollView(
                          physics: BouncingScrollPhysics(),
                          slivers: [
                            SliverAppBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              stretch: true,
                              pinned: false,
                              // floating: true,
                              expandedHeight:
                                  MediaQuery.of(context).size.height * 0.4,
                              flexibleSpace: FlexibleSpaceBar(
                                title: Text(
                                  widget.type,
                                  textAlign: TextAlign.center,
                                ),
                                centerTitle: true,
                                stretchModes: [StretchMode.zoomBackground],
                                background: ShaderMask(
                                    shaderCallback: (rect) {
                                      return LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black,
                                          Colors.transparent
                                        ],
                                      ).createShader(Rect.fromLTRB(
                                          0, 0, rect.width, rect.height));
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage(
                                            widget.type == 'Artists'
                                                ? 'assets/artist.png'
                                                : 'assets/album.png'))),
                              ),
                            ),
                            SliverList(
                                delegate:
                                    SliverChildListDelegate(searchedList.map(
                              (entry) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 7, 7, 5),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.only(left: 15.0),
                                    title: Text(
                                      '${entry["title"]}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    subtitle: Text(
                                      '${entry["subtitle"]}',
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
                                          image: AssetImage(
                                              widget.type == 'Artists'
                                                  ? 'assets/artist.png'
                                                  : 'assets/album.png'),
                                        ),
                                        imageUrl:
                                            '${entry["image"].replaceAll('http:', 'https:')}',
                                        placeholder: (context, url) => Image(
                                          image: AssetImage(
                                              widget.type == 'Artists'
                                                  ? 'assets/artist.png'
                                                  : 'assets/album.png'),
                                        ),
                                      ),
                                    ),
                                    trailing: widget.type != 'Albums'
                                        ? null
                                        : AlbumDownloadButton(
                                            albumName: entry['title'],
                                            albumId: entry['id'],
                                          ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          opaque: false,
                                          pageBuilder: (_, __, ___) => widget
                                                      .type ==
                                                  'Artists'
                                              ? ArtistSearchPage(
                                                  artistName: entry['title'],
                                                  artistToken:
                                                      entry['artistToken'],
                                                  artistImage: entry["image"])
                                              : SongsListPage(
                                                  listImage: entry["image"],
                                                  listItem: entry),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ).toList())),
                          ],
                        ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
