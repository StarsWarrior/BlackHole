import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/GradientContainers.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';

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
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text('Now Playing'),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).accentColor,
                elevation: 0,
              ),
              body: StreamBuilder<bool>(
                  stream: AudioService.runningStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.active) {
                      return SizedBox();
                    }
                    final running = snapshot.data ?? false;
                    return !running
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
                                            : ListView.builder(
                                                physics:
                                                    BouncingScrollPhysics(),
                                                padding: EdgeInsets.only(
                                                    top: 10, bottom: 10),
                                                shrinkWrap: true,
                                                itemCount: queue.length,
                                                itemBuilder: (context, index) {
                                                  return ListTileTheme(
                                                    selectedColor:
                                                        Theme.of(context)
                                                            .accentColor,
                                                    child: ListTile(
                                                      selected: queue[index] ==
                                                          mediaItem,
                                                      trailing: queue[index] ==
                                                              mediaItem
                                                          ? Icon(Icons
                                                              .bar_chart_rounded)
                                                          : SizedBox(),
                                                      leading: Card(
                                                        elevation: 5,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      7.0),
                                                        ),
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        child: Stack(
                                                          children: [
                                                            Image(
                                                              image: AssetImage(
                                                                  'assets/cover.jpg'),
                                                            ),
                                                            queue[index].artUri ==
                                                                    null
                                                                ? SizedBox()
                                                                : Image(
                                                                    image: queue[index]
                                                                            .artUri
                                                                            .toString()
                                                                            .startsWith(
                                                                                'file:')
                                                                        ? FileImage(File(queue[index]
                                                                            .artUri
                                                                            .toFilePath()))
                                                                        : NetworkImage(queue[index]
                                                                            .artUri
                                                                            .toString()))
                                                          ],
                                                        ),
                                                      ),
                                                      title: Text(
                                                        '${queue[index].title}',
                                                        style: TextStyle(
                                                            fontWeight: queue[
                                                                        index] ==
                                                                    mediaItem
                                                                ? FontWeight
                                                                    .w600
                                                                : FontWeight
                                                                    .normal),
                                                      ),
                                                      subtitle: Text(
                                                        '${queue[index].artist}',
                                                      ),
                                                      onTap: () {
                                                        AudioService
                                                            .skipToQueueItem(
                                                                queue[index]
                                                                    .id);
                                                      },
                                                    ),
                                                  );
                                                });
                                      },
                                    );
                            },
                          );
                  }),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
