import 'dart:ui';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/add_queue.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ArtistSearchPage extends StatefulWidget {
  final String? artistName;
  final String artistToken;
  final String? artistImage;

  const ArtistSearchPage({
    Key? key,
    required this.artistToken,
    this.artistName,
    this.artistImage,
  }) : super(key: key);

  @override
  _ArtistSearchPageState createState() => _ArtistSearchPageState();
}

class _ArtistSearchPageState extends State<ArtistSearchPage> {
  bool status = false;
  Map<String, List> data = {};
  bool fetched = false;

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      SaavnAPI().fetchArtistSongs(widget.artistToken).then((value) {
        setState(() {
          data = value;
          fetched = true;
        });
      });
    }
    return GradientContainer(
      child: Column(children: [
        Expanded(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: !fetched
                ? SizedBox(
                    child: Center(
                      child: SizedBox(
                          height: MediaQuery.of(context).size.width / 7,
                          width: MediaQuery.of(context).size.width / 7,
                          child: const CircularProgressIndicator()),
                    ),
                  )
                : data.isEmpty
                    ? EmptyScreen().emptyScreen(context, 0, ':( ', 100, 'SORRY',
                        60, 'Results Not Found', 20)
                    : CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverAppBar(
                            // backgroundColor: Colors.transparent,
                            elevation: 0,
                            stretch: true,
                            pinned: true,
                            expandedHeight:
                                MediaQuery.of(context).size.height * 0.4,
                            flexibleSpace: FlexibleSpaceBar(
                              title: Text(
                                widget.artistName ?? 'Songs',
                                textAlign: TextAlign.center,
                              ),
                              centerTitle: true,
                              background: ShaderMask(
                                shaderCallback: (rect) {
                                  return const LinearGradient(
                                    begin: Alignment.center,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black, Colors.transparent],
                                  ).createShader(Rect.fromLTRB(
                                      0, 0, rect.width, rect.height));
                                },
                                blendMode: BlendMode.dstIn,
                                child: CachedNetworkImage(
                                  fit: BoxFit.cover,
                                  errorWidget: (context, _, __) => const Image(
                                    image: AssetImage('assets/artist.png'),
                                  ),
                                  imageUrl: widget.artistImage!
                                      .replaceAll('http:', 'https:')
                                      .replaceAll('50x50', '500x500')
                                      .replaceAll('150x150', '500x500'),
                                  placeholder: (context, url) => const Image(
                                    image: AssetImage('assets/artist.png'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate(
                              data.entries.map(
                                (entry) {
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            25, 30, 0, 0),
                                        child: Row(
                                          children: [
                                            Text(
                                              entry.key,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ListView.builder(
                                        itemCount: entry.value.length,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.fromLTRB(
                                            5, 10, 5, 0),
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 7, 7, 5),
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                      left: 15.0),
                                              title: Text(
                                                '${entry.value[index]["title"]}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              subtitle: Text(
                                                '${entry.value[index]["subtitle"]}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              leading: Card(
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0)),
                                                clipBehavior: Clip.antiAlias,
                                                child: CachedNetworkImage(
                                                  errorWidget:
                                                      (context, _, __) => Image(
                                                    image: AssetImage((entry
                                                                    .key ==
                                                                'Top Songs' ||
                                                            entry.key ==
                                                                'Latest Release')
                                                        ? 'assets/cover.jpg'
                                                        : 'assets/album.png'),
                                                  ),
                                                  imageUrl:
                                                      '${entry.value[index]["image"].replaceAll('http:', 'https:')}',
                                                  placeholder: (context, url) =>
                                                      Image(
                                                    image: AssetImage((entry
                                                                    .key ==
                                                                'Top Songs' ||
                                                            entry.key ==
                                                                'Latest Release' ||
                                                            entry.key ==
                                                                'Singles')
                                                        ? 'assets/cover.jpg'
                                                        : 'assets/album.png'),
                                                  ),
                                                ),
                                              ),
                                              trailing: (entry.key ==
                                                          'Top Songs' ||
                                                      entry.key ==
                                                          'Latest Release' ||
                                                      entry.key == 'Singles')
                                                  ? Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                          DownloadButton(
                                                            data: entry.value[
                                                                index] as Map,
                                                            icon: 'download',
                                                          ),
                                                          AddToQueueButton(
                                                              data: entry.value[
                                                                      index]
                                                                  as Map),
                                                        ])
                                                  : null,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    pageBuilder: (_, __, ___) => (entry
                                                                    .key ==
                                                                'Top Songs' ||
                                                            entry.key ==
                                                                'Latest Release' ||
                                                            entry.key ==
                                                                'Singles')
                                                        ? PlayScreen(
                                                            data: {
                                                              'response':
                                                                  entry.value,
                                                              'index': index,
                                                              'offline': false,
                                                            },
                                                            fromMiniplayer:
                                                                false,
                                                          )
                                                        : SongsListPage(
                                                            listItem: entry
                                                                    .value[
                                                                index] as Map),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        MiniPlayer(),
      ]),
    );
  }
}
