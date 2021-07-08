import 'dart:ui';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/APIs/api.dart';
import 'package:html_unescape/html_unescape_small.dart';

class SongsListPage extends StatefulWidget {
  final Map listItem;
  final String listImage;

  SongsListPage({
    Key key,
    @required this.listItem,
    this.listImage,
  }) : super(key: key);

  @override
  _SongsListPageState createState() => _SongsListPageState();
}

class _SongsListPageState extends State<SongsListPage> {
  bool status = false;
  List songList = [];
  bool fetched = false;
  HtmlUnescape unescape = HtmlUnescape();

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      switch (widget.listItem['type']) {
        case 'songs':
          SaavnAPI()
              .fetchSongSearchResults(widget.listItem['id'], '20')
              .then((value) {
            setState(() {
              songList = value;
              fetched = true;
            });
          });
          break;
        case 'album':
          SaavnAPI().fetchAlbumSongs(widget.listItem['id']).then((value) {
            setState(() {
              songList = value;
              fetched = true;
            });
          });
          break;
        case 'playlist':
          SaavnAPI().fetchPlaylistSongs(widget.listItem['id']).then((value) {
            setState(() {
              songList = value;
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
                              height: MediaQuery.of(context).size.width / 6,
                              width: MediaQuery.of(context).size.width / 6,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).accentColor),
                                strokeWidth: 5,
                              )),
                        ),
                      )
                    : songList.isEmpty
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
                                      unescape.convert(
                                        widget.listItem['title'] ?? 'Songs',
                                      ),
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
                                      child: widget.listImage == null
                                          ? Image(
                                              fit: BoxFit.cover,
                                              image: AssetImage(
                                                  'assets/cover.jpg'))
                                          : CachedNetworkImage(
                                              fit: BoxFit.cover,
                                              errorWidget: (context, _, __) =>
                                                  Image(
                                                image: AssetImage(
                                                    'assets/album.png'),
                                              ),
                                              imageUrl: widget.listImage
                                                  .replaceAll('http:', 'https:')
                                                  .replaceAll(
                                                      '50x50', '500x500')
                                                  .replaceAll(
                                                      '150x150', '500x500'),
                                              placeholder: (context, url) =>
                                                  Image(
                                                image: AssetImage(
                                                    'assets/album.png'),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                SliverList(
                                    delegate: SliverChildListDelegate(
                                        songList.map((entry) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 7, 7, 5),
                                    child: ListTile(
                                      contentPadding:
                                          EdgeInsets.only(left: 15.0),
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
                                            borderRadius:
                                                BorderRadius.circular(7.0)),
                                        clipBehavior: Clip.antiAlias,
                                        child: CachedNetworkImage(
                                          errorWidget: (context, _, __) =>
                                              Image(
                                            image:
                                                AssetImage('assets/cover.jpg'),
                                          ),
                                          imageUrl:
                                              '${entry["image"].replaceAll('http:', 'https:')}',
                                          placeholder: (context, url) => Image(
                                            image:
                                                AssetImage('assets/cover.jpg'),
                                          ),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          DownloadButton(
                                            data: entry,
                                            icon: 'download',
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (_, __, ___) =>
                                                PlayScreen(
                                              data: {
                                                'response': songList,
                                                'index': songList.indexWhere(
                                                    (element) =>
                                                        element == entry),
                                                'offline': false,
                                              },
                                              fromMiniplayer: false,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // );
                                    // },
                                  );
                                }).toList()))
                              ])),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
