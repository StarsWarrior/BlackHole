import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:rxdart/rxdart.dart';

final ValueNotifier<double> playerExpandProgress = ValueNotifier(76);

class MiniPlayer extends StatefulWidget {
  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final MiniplayerController controller = MiniplayerController();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: AudioService.runningStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return SizedBox();
          }
          final running = snapshot.data ?? false;
          // !running
          return StreamBuilder<QueueState>(
              stream: _queueStateStream,
              builder: (context, snapshot) {
                final queueState = snapshot.data;
                final queue = queueState?.queue ?? [];
                final mediaItem = queueState?.mediaItem;
                return (running && mediaItem != null && queue.isNotEmpty)
                    ? Miniplayer(
                        controller: controller,
                        valueNotifier: playerExpandProgress,
                        duration: Duration(milliseconds: 300),
                        onDismissed: () {
                          AudioService.stop();
                        },
                        minHeight: 76,
                        backgroundColor: Colors.grey[900],
                        maxHeight: MediaQuery.of(context).size.height - 20.0,
                        builder: (height, percentage) {
                          return percentage * 100 > 0
                              ? Opacity(
                                  opacity: percentage,
                                  child: PlayScreen(
                                    data: {
                                      'response': [],
                                      'index': 0,
                                      'offline': null,
                                    },
                                    fromMiniplayer: true,
                                    controller: controller,
                                  ))
                              : Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: Theme.of(context)
                                                      .brightness ==
                                                  Brightness.dark
                                              ? [
                                                  Colors.grey[900],
                                                  Colors.black,
                                                ]
                                              : [
                                                  Colors.white,
                                                  Theme.of(context).canvasColor,
                                                ],
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Dismissible(
                                            key: Key('miniplayer'),
                                            onDismissed: (direction) {
                                              AudioService.stop();
                                            },
                                            child: ListTile(
                                              onTap: () {
                                                controller.animateToHeight(
                                                    state: PanelState.MAX);
                                              },
                                              title: Text(
                                                mediaItem.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              subtitle: Text(
                                                mediaItem.artist,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              leading: Hero(
                                                tag: 'image',
                                                child: Card(
                                                    elevation: 8,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        7.0)),
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    child: //playlist.playSong.check()
                                                        //? Image(image: MemoryImage(playlist.playImage)):
                                                        Stack(
                                                      children: [
                                                        Image(
                                                            image: AssetImage(
                                                                'assets/cover.jpg')),
                                                        Image(
                                                            image: mediaItem
                                                                    .artUri
                                                                    .toString()
                                                                    .startsWith(
                                                                        'file:')
                                                                ? FileImage(File(
                                                                    mediaItem
                                                                        .artUri
                                                                        .toFilePath()))
                                                                : NetworkImage(
                                                                    mediaItem
                                                                        .artUri
                                                                        .toString()))
                                                      ],
                                                    )),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons
                                                        .skip_previous_rounded),
                                                    color: Theme.of(context)
                                                        .iconTheme
                                                        .color,
                                                    onPressed:
                                                        mediaItem == queue.first
                                                            ? null
                                                            : AudioService
                                                                .skipToPrevious,
                                                  ),
                                                  Stack(
                                                    children: [
                                                      Center(
                                                        child: StreamBuilder<
                                                            AudioProcessingState>(
                                                          stream: AudioService
                                                              .playbackStateStream
                                                              .map((state) => state
                                                                  .processingState)
                                                              .distinct(),
                                                          builder: (context,
                                                              snapshot) {
                                                            final processingState =
                                                                snapshot.data ??
                                                                    AudioProcessingState
                                                                        .none;

                                                            return (describeEnum(
                                                                            processingState) !=
                                                                        'ready' &&
                                                                    describeEnum(
                                                                            processingState) !=
                                                                        'none')
                                                                ? SizedBox(
                                                                    height: 40,
                                                                    width: 40,
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      valueColor: AlwaysStoppedAnimation<
                                                                          Color>(Theme.of(
                                                                              context)
                                                                          .accentColor),
                                                                    ),
                                                                  )
                                                                : SizedBox();
                                                          },
                                                        ),
                                                      ),
                                                      Center(
                                                        child:
                                                            StreamBuilder<bool>(
                                                          stream: AudioService
                                                              .playbackStateStream
                                                              .map((state) =>
                                                                  state.playing)
                                                              .distinct(),
                                                          builder: (context,
                                                              snapshot) {
                                                            final playing =
                                                                snapshot.data ??
                                                                    false;
                                                            return playing ==
                                                                    null
                                                                ? SizedBox()
                                                                : Container(
                                                                    height: 40,
                                                                    width: 40,
                                                                    child:
                                                                        Center(
                                                                      child:
                                                                          SizedBox(
                                                                        height:
                                                                            40,
                                                                        width:
                                                                            40,
                                                                        child: playing
                                                                            ? IconButton(
                                                                                icon: Icon(Icons.pause_rounded),
                                                                                color: Theme.of(context).iconTheme.color,
                                                                                onPressed: AudioService.pause,
                                                                              )
                                                                            : IconButton(
                                                                                icon: Icon(Icons.play_arrow_rounded),
                                                                                onPressed: AudioService.play,
                                                                                color: Theme.of(context).iconTheme.color,
                                                                              ),
                                                                      ),
                                                                    ),
                                                                  );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons
                                                        .skip_next_rounded),
                                                    color: Theme.of(context)
                                                        .iconTheme
                                                        .color,
                                                    onPressed:
                                                        mediaItem == queue.last
                                                            ? null
                                                            : AudioService
                                                                .skipToNext,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          StreamBuilder(
                                              stream:
                                                  AudioService.positionStream,
                                              builder: (context, snapshot) {
                                                final position = snapshot.data;
                                                return position == null
                                                    ? SizedBox()
                                                    : (position.inSeconds
                                                                    .toDouble() <
                                                                0.0 ||
                                                            position.inSeconds
                                                                    .toDouble() >
                                                                mediaItem
                                                                    .duration
                                                                    .inSeconds
                                                                    .toDouble())
                                                        ? SizedBox()
                                                        : SliderTheme(
                                                            data:
                                                                SliderTheme.of(
                                                                        context)
                                                                    .copyWith(
                                                              activeTrackColor:
                                                                  Theme.of(
                                                                          context)
                                                                      .accentColor,
                                                              inactiveTrackColor:
                                                                  Colors
                                                                      .transparent,
                                                              trackHeight: 0.5,
                                                              thumbColor: Theme
                                                                      .of(context)
                                                                  .accentColor,
                                                              thumbShape:
                                                                  RoundSliderThumbShape(
                                                                      enabledThumbRadius:
                                                                          1.0),
                                                              overlayColor: Colors
                                                                  .transparent,
                                                              overlayShape:
                                                                  RoundSliderOverlayShape(
                                                                      overlayRadius:
                                                                          2.0),
                                                            ),
                                                            child: Slider(
                                                              inactiveColor: Colors
                                                                  .transparent,
                                                              // activeColor: Colors.white,
                                                              value: position
                                                                  .inSeconds
                                                                  .toDouble(),
                                                              min: 0.0,
                                                              max: mediaItem
                                                                  .duration
                                                                  .inSeconds
                                                                  .toDouble(),
                                                              onChanged:
                                                                  (newPosition) {
                                                                AudioService.seekTo(
                                                                    Duration(
                                                                        seconds:
                                                                            newPosition.round()));
                                                              },
                                                            ),
                                                          );
                                              }),
                                        ],
                                      )),
                                );
                        })
                    : SizedBox();
              });
        });
  }

  Stream<QueueState> get _queueStateStream =>
      Rx.combineLatest2<List<MediaItem>, MediaItem, QueueState>(
          AudioService.queueStream,
          AudioService.currentMediaItemStream,
          (queue, mediaItem) => QueueState(queue, mediaItem));
}
