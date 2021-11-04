import 'dart:ui';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/add_list_queue.dart';
import 'package:blackhole/CustomWidgets/add_queue.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:share_plus/share_plus.dart';

class SongsListPage extends StatefulWidget {
  final Map listItem;

  const SongsListPage({
    Key? key,
    required this.listItem,
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
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : songList.isEmpty
                      ? EmptyScreen().emptyScreen(
                          context,
                          0,
                          ':( ',
                          100,
                          AppLocalizations.of(context)!.sorry,
                          60,
                          AppLocalizations.of(context)!.resultsNotFound,
                          20,
                        )
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverAppBar(
                              // backgroundColor:
                              // Theme.of(context).brightness ==
                              // Brightness.light
                              // ? Colors.transparent
                              // : null,
                              elevation: 0,
                              stretch: true,
                              // floating: true,
                              pinned: true,
                              expandedHeight:
                                  MediaQuery.of(context).size.height * 0.4,
                              actions: [
                                MultiDownloadButton(
                                  data: songList,
                                  playlistName:
                                      widget.listItem['title']?.toString() ??
                                          'Songs',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_rounded),
                                  tooltip: AppLocalizations.of(context)!.share,
                                  onPressed: () {
                                    Share.share(
                                      widget.listItem['perma_url'].toString(),
                                    );
                                  },
                                ),
                                AddListToQueueButton(
                                  data: songList,
                                  title: widget.listItem['title']?.toString() ??
                                      'Songs',
                                )
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
                                      begin: Alignment.center,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black,
                                        Colors.transparent
                                      ],
                                    ).createShader(
                                      Rect.fromLTRB(
                                        0,
                                        0,
                                        rect.width,
                                        rect.height,
                                      ),
                                    );
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: widget.listItem['image'] == null
                                      ? const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage(
                                            'assets/cover.jpg',
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          fit: BoxFit.cover,
                                          errorWidget: (context, _, __) =>
                                              const Image(
                                            image: AssetImage(
                                              'assets/album.png',
                                            ),
                                          ),
                                          imageUrl: widget.listItem['image']
                                              .toString()
                                              .replaceAll('http:', 'https:')
                                              .replaceAll(
                                                '50x50',
                                                '500x500',
                                              )
                                              .replaceAll(
                                                '150x150',
                                                '500x500',
                                              ),
                                          placeholder: (context, url) =>
                                              const Image(
                                            image: AssetImage(
                                              'assets/album.png',
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildListDelegate([
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (_, __, ___) =>
                                                PlayScreen(
                                              data: {
                                                'response': songList,
                                                'index': 0,
                                                'offline': false,
                                              },
                                              fromMiniplayer: false,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          top: 20,
                                          bottom: 5,
                                        ),
                                        height: 45.0,
                                        width: 120,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(100.0),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 5.0,
                                              offset: Offset(0.0, 3.0),
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.play_arrow_rounded,
                                              color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary ==
                                                      Colors.white
                                                  ? Colors.black
                                                  : Colors.white,
                                            ),
                                            const SizedBox(width: 5.0),
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .play,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18.0,
                                                color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary ==
                                                        Colors.white
                                                    ? Colors.black
                                                    : Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        final List tempList =
                                            List.from(songList);
                                        tempList.shuffle();
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (_, __, ___) =>
                                                PlayScreen(
                                              data: {
                                                'response': tempList,
                                                'index': 0,
                                                'offline': false,
                                              },
                                              fromMiniplayer: false,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(
                                          top: 20,
                                          bottom: 5,
                                        ),
                                        height: 45.0,
                                        width: 130,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(100.0),
                                          color: Colors.white,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 5.0,
                                              offset: Offset(0.0, 3.0),
                                            )
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.shuffle_rounded,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(width: 5.0),
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .shuffle,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18.0,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ...songList.map((entry) {
                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.only(left: 15.0),
                                    title: Text(
                                      '${entry["title"]}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${entry["subtitle"]}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    leading: Card(
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(7.0),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        errorWidget: (context, _, __) =>
                                            const Image(
                                          image: AssetImage(
                                            'assets/cover.jpg',
                                          ),
                                        ),
                                        imageUrl:
                                            '${entry["image"].replaceAll('http:', 'https:')}',
                                        placeholder: (context, url) =>
                                            const Image(
                                          image: AssetImage(
                                            'assets/cover.jpg',
                                          ),
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
                                        LikeButton(
                                          mediaItem: null,
                                          data: entry,
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
                                                (element) => element == entry,
                                              ),
                                              'offline': false,
                                            },
                                            fromMiniplayer: false,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList()
                              ]),
                            )
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
