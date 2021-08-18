import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/add_list_queue.dart';
import 'package:blackhole/CustomWidgets/add_queue.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';

class SongsListPage extends StatefulWidget {
  final Map listItem;
  final String? listImage;

  const SongsListPage({
    Key? key,
    required this.listItem,
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
      switch (widget.listItem['type'].toString()) {
        case 'songs':
          SaavnAPI()
              .fetchSongSearchResults(widget.listItem['id'].toString(), '20')
              .then((value) {
            setState(() {
              songList = value;
              fetched = true;
            });
          });
          break;
        case 'album':
          SaavnAPI()
              .fetchAlbumSongs(widget.listItem['id'].toString())
              .then((value) {
            setState(() {
              songList = value;
              fetched = true;
            });
          });
          break;
        case 'playlist':
          SaavnAPI()
              .fetchPlaylistSongs(widget.listItem['id'].toString())
              .then((value) {
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
                    : songList.isEmpty
                        ? EmptyScreen().emptyScreen(context, 0, ':( ', 100,
                            'SORRY', 60, 'Results Not Found', 20)
                        : CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                                SliverAppBar(
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  stretch: true,
                                  // floating: true,
                                  expandedHeight:
                                      MediaQuery.of(context).size.height * 0.4,
                                  actions: [
                                    AddListToQueueButton(
                                        data: songList,
                                        title: widget.listItem['title']
                                                as String? ??
                                            'Songs')
                                  ],
                                  flexibleSpace: FlexibleSpaceBar(
                                    title: Text(
                                      unescape.convert(
                                        widget.listItem['title'] as String? ??
                                            'Songs',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    centerTitle: true,
                                    background: ShaderMask(
                                      shaderCallback: (rect) {
                                        return const LinearGradient(
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
                                          ? const Image(
                                              fit: BoxFit.cover,
                                              image: AssetImage(
                                                  'assets/cover.jpg'))
                                          : CachedNetworkImage(
                                              fit: BoxFit.cover,
                                              errorWidget: (context, _, __) =>
                                                  const Image(
                                                image: AssetImage(
                                                    'assets/album.png'),
                                              ),
                                              imageUrl: widget.listImage!
                                                  .replaceAll('http:', 'https:')
                                                  .replaceAll(
                                                      '50x50', '500x500')
                                                  .replaceAll(
                                                      '150x150', '500x500'),
                                              placeholder: (context, url) =>
                                                  const Image(
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
                                          const EdgeInsets.only(left: 15.0),
                                      title: Text(
                                        '${entry["title"]}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
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
                                              const Image(
                                            image:
                                                AssetImage('assets/cover.jpg'),
                                          ),
                                          imageUrl:
                                              '${entry["image"].replaceAll('http:', 'https:')}',
                                          placeholder: (context, url) =>
                                              const Image(
                                            image:
                                                AssetImage('assets/cover.jpg'),
                                          ),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          DownloadButton(
                                            data: entry as Map,
                                            icon: 'download',
                                          ),
                                          AddToQueueButton(data: entry),
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
