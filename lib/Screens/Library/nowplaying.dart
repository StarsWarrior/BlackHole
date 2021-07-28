import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NowPlaying extends StatefulWidget {
  @override
  _NowPlayingState createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<bool>(
                stream: AudioService.runningStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.active) {
                    return SizedBox();
                  }
                  final running = snapshot.data ?? false;
                  return Scaffold(
                    backgroundColor: Colors.transparent,
                    appBar: running
                        ? null
                        : AppBar(
                            title: Text('Now Playing'),
                            centerTitle: true,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.transparent
                                    : Theme.of(context).accentColor,
                            elevation: 0,
                          ),
                    body: !running
                        ? EmptyScreen().emptyScreen(context, 3, "Nothing is ",
                            18.0, "PLAYING", 60, "Go and Play Something", 23.0)
                        : StreamBuilder<List<MediaItem>>(
                            stream: AudioService.queueStream,
                            builder: (context, snapshot) {
                              final queue = snapshot.data;
                              return queue == null
                                  ? SizedBox()
                                  : StreamBuilder<MediaItem>(
                                      stream:
                                          AudioService.currentMediaItemStream,
                                      builder: (context, snapshot) {
                                        final mediaItem = snapshot.data;
                                        return (mediaItem == null ||
                                                queue.isEmpty)
                                            ? SizedBox()
                                            : CustomScrollView(
                                                physics:
                                                    BouncingScrollPhysics(),
                                                slivers: [
                                                    SliverAppBar(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      elevation: 0,
                                                      stretch: true,
                                                      pinned: false,
                                                      // floating: true,
                                                      expandedHeight:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.4,
                                                      flexibleSpace:
                                                          FlexibleSpaceBar(
                                                        title: Text(
                                                          'Now Playing',
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        centerTitle: true,
                                                        stretchModes: [
                                                          StretchMode
                                                              .zoomBackground
                                                        ],
                                                        background: ShaderMask(
                                                            shaderCallback:
                                                                (rect) {
                                                              return LinearGradient(
                                                                begin: Alignment
                                                                    .topCenter,
                                                                end: Alignment
                                                                    .bottomCenter,
                                                                colors: [
                                                                  Colors.black,
                                                                  Colors
                                                                      .transparent
                                                                ],
                                                              ).createShader(
                                                                  Rect.fromLTRB(
                                                                      0,
                                                                      0,
                                                                      rect.width,
                                                                      rect.height));
                                                            },
                                                            blendMode:
                                                                BlendMode.dstIn,
                                                            child: mediaItem
                                                                    .artUri
                                                                    .toString()
                                                                    .startsWith(
                                                                        'file:')
                                                                ? Image(
                                                                    image: FileImage(File(
                                                                        mediaItem
                                                                            .artUri
                                                                            .toFilePath())),
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  )
                                                                : CachedNetworkImage(
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    errorWidget:
                                                                        (BuildContext context,
                                                                                _,
                                                                                __) =>
                                                                            Image(
                                                                              image: AssetImage('assets/cover.jpg'),
                                                                            ),
                                                                    placeholder:
                                                                        (BuildContext context,
                                                                                _) =>
                                                                            Image(
                                                                              image: AssetImage('assets/cover.jpg'),
                                                                            ),
                                                                    imageUrl: mediaItem
                                                                        .artUri
                                                                        .toString())),
                                                      ),
                                                    ),
                                                    SliverList(
                                                        delegate:
                                                            SliverChildListDelegate([
                                                      ReorderableListView
                                                          .builder(
                                                              onReorder: (int
                                                                      oldIndex,
                                                                  int
                                                                      newIndex) {
                                                                setState(() {
                                                                  if (oldIndex <
                                                                      newIndex) {
                                                                    newIndex--;
                                                                  }
                                                                  final items =
                                                                      queue.removeAt(
                                                                          oldIndex);
                                                                  queue.insert(
                                                                      newIndex,
                                                                      items);
                                                                  AudioService
                                                                      .customAction(
                                                                          'reorder',
                                                                          [
                                                                        oldIndex,
                                                                        newIndex,
                                                                      ]);
                                                                });
                                                              },
                                                              physics:
                                                                  BouncingScrollPhysics(),
                                                              padding: EdgeInsets
                                                                  .only(
                                                                      top: 10,
                                                                      bottom:
                                                                          10),
                                                              shrinkWrap: true,
                                                              itemCount:
                                                                  queue.length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                return Dismissible(
                                                                  key: Key(queue[
                                                                          index]
                                                                      .id),
                                                                  direction: queue[
                                                                              index] ==
                                                                          mediaItem
                                                                      ? DismissDirection
                                                                          .none
                                                                      : DismissDirection
                                                                          .horizontal,
                                                                  onDismissed:
                                                                      (dir) {
                                                                    setState(
                                                                        () {
                                                                      AudioService
                                                                          .removeQueueItem(
                                                                              queue[index]);
                                                                      queue.remove(
                                                                          queue[
                                                                              index]);
                                                                    });
                                                                  },
                                                                  child:
                                                                      ListTileTheme(
                                                                    selectedColor:
                                                                        Theme.of(context)
                                                                            .accentColor,
                                                                    child:
                                                                        ListTile(
                                                                      contentPadding: EdgeInsets.only(
                                                                          left:
                                                                              16.0,
                                                                          right:
                                                                              10.0),
                                                                      selected:
                                                                          queue[index] ==
                                                                              mediaItem,
                                                                      trailing: queue[index] ==
                                                                              mediaItem
                                                                          ? IconButton(
                                                                              icon: Icon(
                                                                                Icons.bar_chart_rounded,
                                                                              ),
                                                                              tooltip: 'Now Playing',
                                                                              onPressed: () {},
                                                                            )
                                                                          : queue[index].artUri.toString().startsWith('file:')
                                                                              ? SizedBox()
                                                                              : Row(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    LikeButton(
                                                                                      mediaItem: queue[index],
                                                                                    ),
                                                                                    DownloadButton(icon: 'download', data: {
                                                                                      'id': queue[index].id.toString(),
                                                                                      'artist': queue[index].artist.toString(),
                                                                                      'album': queue[index].album.toString(),
                                                                                      'image': queue[index].artUri.toString(),
                                                                                      'duration': queue[index].duration.inSeconds.toString(),
                                                                                      'title': queue[index].title.toString(),
                                                                                      'url': queue[index].extras['url'].toString(),
                                                                                      "year": queue[index].extras["year"].toString(),
                                                                                      "language": queue[index].extras["language"].toString(),
                                                                                      "genre": queue[index].genre.toString(),
                                                                                      "320kbps": queue[index].extras["320kbps"],
                                                                                      "has_lyrics": queue[index].extras["has_lyrics"],
                                                                                      "release_date": queue[index].extras["release_date"],
                                                                                      "album_id": queue[index].extras["album_id"],
                                                                                      "subtitle": queue[index].extras["subtitle"]
                                                                                    })
                                                                                  ],
                                                                                ),
                                                                      leading:
                                                                          Card(
                                                                        elevation:
                                                                            5,
                                                                        shape:
                                                                            RoundedRectangleBorder(
                                                                          borderRadius:
                                                                              BorderRadius.circular(7.0),
                                                                        ),
                                                                        clipBehavior:
                                                                            Clip.antiAlias,
                                                                        child:
                                                                            Stack(
                                                                          children: [
                                                                            Image(
                                                                              image: AssetImage('assets/cover.jpg'),
                                                                            ),
                                                                            queue[index].artUri == null
                                                                                ? SizedBox()
                                                                                : queue[index].artUri.toString().startsWith('file:')
                                                                                    ? Image(image: FileImage(File(queue[index].artUri.toFilePath())))
                                                                                    : CachedNetworkImage(
                                                                                        errorWidget: (BuildContext context, _, __) => Image(
                                                                                              image: AssetImage('assets/cover.jpg'),
                                                                                            ),
                                                                                        placeholder: (BuildContext context, _) => Image(
                                                                                              image: AssetImage('assets/cover.jpg'),
                                                                                            ),
                                                                                        imageUrl: queue[index].artUri.toString())
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      title:
                                                                          Text(
                                                                        '${queue[index].title}',
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        style: TextStyle(
                                                                            fontWeight: queue[index] == mediaItem
                                                                                ? FontWeight.w600
                                                                                : FontWeight.normal),
                                                                      ),
                                                                      subtitle:
                                                                          Text(
                                                                        '${queue[index].artist}',
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                      onTap:
                                                                          () {
                                                                        AudioService.skipToQueueItem(
                                                                            queue[index].id);
                                                                      },
                                                                    ),
                                                                  ),
                                                                );
                                                              }),
                                                    ])),
                                                  ]);
                                      },
                                    );
                            }),
                  );
                }),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
