import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/add_queue.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/equalizer.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/seek_bar.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/lyrics.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/main.dart';

class PlayScreen extends StatefulWidget {
  final Map data;
  final bool fromMiniplayer;
  const PlayScreen({
    Key? key,
    required this.data,
    required this.fromMiniplayer,
  }) : super(key: key);
  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  bool fromMiniplayer = false;
  String preferredQuality = Hive.box('settings')
      .get('streamingQuality', defaultValue: '96 kbps')
      .toString();
  String repeatMode =
      Hive.box('settings').get('repeatMode', defaultValue: 'None').toString();
  bool enforceRepeat =
      Hive.box('settings').get('enforceRepeat', defaultValue: false) as bool;
  bool shuffle =
      Hive.box('settings').get('shuffle', defaultValue: false) as bool;
  List<MediaItem> globalQueue = [];
  int globalIndex = 0;
  bool same = false;
  List response = [];
  bool fetched = false;
  bool offline = false;
  bool fromYT = false;
  String defaultCover = '';

  GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  void sleepTimer(int time) {
    audioHandler.customAction('sleepTimer', {'time': time});
  }

  void sleepCounter(int count) {
    audioHandler.customAction('sleepCounter', {'count': count});
  }

  late Duration _time;

  Future<void> main() async {
    await Hive.openBox('Favorite Songs');
  }

  @override
  void initState() {
    super.initState();
    main();
  }

  Future<MediaItem> setTags(Map response, Directory tempDir) async {
    String? playTitle = response['title'].toString();
    playTitle == ''
        ? playTitle = response['_display_name_wo_ext']?.toString()
        : playTitle = response['title']?.toString();
    String? playArtist = response['artist']?.toString();
    playArtist == '<unknown>'
        ? playArtist = 'Unknown'
        : playArtist = response['artist']?.toString();

    final String playAlbum = response['album'].toString();
    final int playDuration = response['duration'] as int? ?? 180000;
    String? filePath;
    if (response['image'] != null) {
      try {
        final File file = File(
            '${tempDir.path}/${playTitle.toString().replaceAll('/', '')}-${playArtist.toString().replaceAll('/', '')}.jpg');
        filePath = file.path;
        if (!await file.exists()) {
          await file.create();
          file.writeAsBytesSync(response['image'] as Uint8List);
        }
      } catch (e) {
        filePath = null;
      }
    } else {
      filePath = await getImageFileFromAssets();
    }

    final MediaItem tempDict = MediaItem(
        id: response['_data'].toString(),
        album: playAlbum,
        duration: Duration(milliseconds: playDuration),
        title: playTitle != null ? playTitle.split('(')[0] : 'Unknown',
        artist: playArtist ?? 'Unknown',
        artUri: Uri.file(filePath!),
        extras: {
          'url': response['_data'],
        });
    return tempDict;
  }

  Future<String> getImageFileFromAssets() async {
    if (defaultCover != '') return defaultCover;
    final file = File('${(await getTemporaryDirectory()).path}/cover.jpg');
    defaultCover = file.path;
    if (await file.exists()) return file.path;
    final byteData = await rootBundle.load('assets/cover.jpg');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file.path;
  }

  void setOffValues(List response) {
    getTemporaryDirectory().then((tempDir) async {
      final File file =
          File('${(await getTemporaryDirectory()).path}/cover.jpg');
      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/cover.jpg');
        await file.writeAsBytes(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      }
      for (int i = 0; i < response.length; i++) {
        globalQueue.add(await setTags(response[i] as Map, tempDir));
      }
      updateNplay();
    });
  }

  void setValues(List response) {
    globalQueue.addAll(
      response.map((song) => MediaItemConverter().mapToMediaItem(song as Map)),
    );
    fetched = true;
  }

  Future<void> updateNplay() async {
    await audioHandler.updateQueue(globalQueue);
    await audioHandler.skipToQueueItem(globalIndex);
    await audioHandler.play();
    if (enforceRepeat) {
      switch (repeatMode) {
        case 'None':
          audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
          break;
        case 'All':
          audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
          break;
        case 'One':
          audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    BuildContext? scaffoldContext;
    final Map data = widget.data;
    if (response == data['response'] && globalIndex == data['index']) {
      same = true;
    }
    response = data['response'] as List;
    globalIndex = data['index'] as int;
    fromYT = data['fromYT'] as bool? ?? false;
    if (data['offline'] == null) {
      if (audioHandler.mediaItem.value?.extras!['url'].startsWith('http')
          as bool) {
        offline = false;
      } else {
        offline = true;
      }
    } else {
      offline = data['offline'] as bool;
    }
    if (!fetched) {
      if (response.isEmpty || same) {
        fromMiniplayer = true;
      } else {
        fromMiniplayer = false;
        if (!enforceRepeat) {
          repeatMode = 'None';
          Hive.box('settings').put('repeatMode', repeatMode);
        }
        shuffle = false;
        Hive.box('settings').put('shuffle', shuffle);
        if (offline) {
          setOffValues(response);
        } else {
          setValues(response);
          updateNplay();
        }
      }
    }

    return Dismissible(
      direction: DismissDirection.down,
      background: Container(color: Colors.transparent),
      key: const Key('playScreen'),
      onDismissed: (direction) {
        Navigator.pop(context);
      },
      child: GradientContainer(
        child: SafeArea(
          child: StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final MediaItem? mediaItem = snapshot.data;
                if (mediaItem == null) return const SizedBox();
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    centerTitle: true,
                    leading: IconButton(
                        icon: const Icon(Icons.expand_more_rounded),
                        color: Theme.of(context).iconTheme.color,
                        tooltip: 'Back',
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                    actions: [
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.textformat,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        tooltip: 'Lyrics',
                        onPressed: () => cardKey.currentState!.toggleCard(),
                      ),
                      if (!offline)
                        IconButton(
                            icon: const Icon(Icons.share_rounded),
                            tooltip: 'Share',
                            onPressed: () {
                              Share.share(fromYT
                                  ? 'https://youtube.com/watch?v=${mediaItem.id}'
                                  : mediaItem.extras!['perma_url'].toString());
                            }),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(15.0))),
                        onSelected: (int? value) {
                          if (value == 4) {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return const Equalizer();
                                });
                          }
                          if (value == 3) {
                            launch(fromYT
                                ? 'https://youtube.com/watch?v=${mediaItem.id}'
                                : 'https://www.youtube.com/results?search_query=${mediaItem.title} by ${mediaItem.artist}');
                          }
                          if (value == 1) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return SimpleDialog(
                                  title: Text(
                                    'Sleep Timer',
                                    style: TextStyle(
                                      color: Theme.of(context).accentColor,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.all(10.0),
                                  children: [
                                    ListTile(
                                      title: const Text(
                                          'Sleep after a duration of hh:mm'),
                                      subtitle: const Text(
                                          'Music will stop after selected duration'),
                                      dense: true,
                                      onTap: () {
                                        Navigator.pop(context);
                                        setTimer(context, scaffoldContext);
                                      },
                                    ),
                                    ListTile(
                                      title: const Text('Sleep after N Songs'),
                                      subtitle: const Text(
                                          'Music will stop after playing selected no of songs'),
                                      dense: true,
                                      onTap: () {
                                        Navigator.pop(context);
                                        setCounter(scaffoldContext!);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                          if (value == 0) {
                            AddToPlaylist().addToPlaylist(context, mediaItem);
                          }
                          if (value == 2) {
                            SaavnAPI().getReco(mediaItem.id).then((value) {
                              showModalBottomSheet(
                                  isDismissible: true,
                                  backgroundColor: Colors.transparent,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return BottomGradientContainer(
                                      padding: EdgeInsets.zero,
                                      margin: const EdgeInsets.only(
                                          left: 20, right: 20),
                                      borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(15.0),
                                          topRight: Radius.circular(15.0)),
                                      child: ListView.builder(
                                          itemCount: value.length,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.all(10.0),
                                          itemBuilder: (context, index) {
                                            return ListTile(
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                      left: 15.0),
                                              title: Text(
                                                '${value[index]["title"]}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              subtitle: Text(
                                                '${value[index]["subtitle"]}',
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
                                                      (context, _, __) =>
                                                          const Image(
                                                    image: AssetImage(
                                                        'assets/cover.jpg'),
                                                  ),
                                                  imageUrl:
                                                      '${value[index]["image"].replaceAll('http:', 'https:')}',
                                                  placeholder: (context, url) =>
                                                      const Image(
                                                    image: AssetImage(
                                                        'assets/cover.jpg'),
                                                  ),
                                                ),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  DownloadButton(
                                                    data: value[index] as Map,
                                                    icon: 'download',
                                                  ),
                                                  AddToQueueButton(
                                                      data:
                                                          value[index] as Map),
                                                ],
                                              ),
                                              onTap: () {},
                                            );
                                          }),
                                    );
                                  });
                            });
                          }
                        },
                        itemBuilder: (context) => offline
                            ? [
                                PopupMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.timer,
                                          color:
                                              Theme.of(context).iconTheme.color,
                                        ),
                                        const SizedBox(width: 10.0),
                                        const Text('Sleep Timer'),
                                      ],
                                    )),
                                if (Hive.box('settings').get('supportEq',
                                    defaultValue: true) as bool)
                                  PopupMenuItem(
                                      value: 4,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.equalizer_rounded,
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color,
                                          ),
                                          const SizedBox(width: 10.0),
                                          const Text('Equalizer'),
                                        ],
                                      )),
                              ]
                            : [
                                PopupMenuItem(
                                    value: 0,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.playlist_add_rounded,
                                          color:
                                              Theme.of(context).iconTheme.color,
                                        ),
                                        const SizedBox(width: 10.0),
                                        const Text('Add to playlist'),
                                      ],
                                    )),
                                PopupMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.timer,
                                          color:
                                              Theme.of(context).iconTheme.color,
                                        ),
                                        const SizedBox(width: 10.0),
                                        const Text('Sleep Timer'),
                                      ],
                                    )),
                                if (Hive.box('settings').get('supportEq',
                                    defaultValue: true) as bool)
                                  PopupMenuItem(
                                      value: 4,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.equalizer_rounded,
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color,
                                          ),
                                          const SizedBox(width: 10.0),
                                          const Text('Equalizer'),
                                        ],
                                      )),
                                PopupMenuItem(
                                    value: 3,
                                    child: Row(
                                      children: [
                                        Icon(
                                          MdiIcons.youtube,
                                          color:
                                              Theme.of(context).iconTheme.color,
                                        ),
                                        const SizedBox(width: 10.0),
                                        Text(fromYT
                                            ? 'Watch Video'
                                            : 'Search Video'),
                                      ],
                                    )),
                                if (!fromYT)
                                  PopupMenuItem(
                                      value: 2,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.music_note_rounded,
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color,
                                          ),
                                          const SizedBox(width: 10.0),
                                          const Text('Recommended Songs'),
                                        ],
                                      )),
                              ],
                      )
                    ],
                  ),
                  body: Builder(builder: (BuildContext context) {
                    scaffoldContext = context;
                    return LayoutBuilder(builder:
                        (BuildContext context, BoxConstraints constraints) {
                      if (constraints.maxWidth > constraints.maxHeight) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Artwork
                            ArtWorkWidget(
                              cardKey,
                              mediaItem,
                              constraints.maxHeight / 0.9,
                              offline: offline,
                            ),

                            // title and controls
                            SizedBox(
                              width: constraints.maxWidth / 2,
                              child: NameNControls(
                                mediaItem,
                                offline: offline,
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          // Artwork
                          ArtWorkWidget(
                            cardKey,
                            mediaItem,
                            constraints.maxWidth,
                            offline: offline,
                          ),

                          // title and controls
                          Expanded(
                            child: NameNControls(
                              mediaItem,
                              offline: offline,
                            ),
                          ),
                        ],
                      );
                    });
                  }),

                  // }
                );
                // );
              }),
        ),
        // ),
      ),
    );
  }

  Future<dynamic> setTimer(
      BuildContext context, BuildContext? scaffoldContext) {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Center(
              child: Text(
            'Select a Duration',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).accentColor),
          )),
          children: [
            Center(
                child: SizedBox(
              height: 200,
              width: 200,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  primaryColor: Theme.of(context).accentColor,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).accentColor,
                    ),
                  ),
                ),
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  onTimerDurationChanged: (value) {
                    _time = value;
                  },
                ),
              ),
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    primary: Theme.of(context).accentColor,
                  ),
                  onPressed: () {
                    sleepTimer(0);
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: Theme.of(context).accentColor,
                  ),
                  onPressed: () {
                    sleepTimer(_time.inMinutes);
                    Navigator.pop(context);
                    ShowSnackBar().showSnackBar(
                      context,
                      'Sleep timer set for ${_time.inMinutes} minutes',
                    );
                  },
                  child: const Text('Ok'),
                ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> setCounter(BuildContext scaffoldContext) async {
    await TextInputDialog().showTextInputDialog(
        scaffoldContext, 'Enter no of Songs', '', TextInputType.number,
        (String value) {
      sleepCounter(int.parse(value));
      Navigator.pop(scaffoldContext);
      ShowSnackBar().showSnackBar(
        context,
        'Sleep timer set for $value songs',
      );
    });
  }
}

class MediaState {
  final MediaItem? mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class QueueState {
  static const QueueState empty =
      QueueState([], 0, [], AudioServiceRepeatMode.none);

  final List<MediaItem> queue;
  final int? queueIndex;
  final List<int>? shuffleIndices;
  final AudioServiceRepeatMode repeatMode;

  const QueueState(
      this.queue, this.queueIndex, this.shuffleIndices, this.repeatMode);

  bool get hasPrevious =>
      repeatMode != AudioServiceRepeatMode.none || (queueIndex ?? 0) > 0;
  bool get hasNext =>
      repeatMode != AudioServiceRepeatMode.none ||
      (queueIndex ?? 0) + 1 < queue.length;

  List<int> get indices =>
      shuffleIndices ?? List.generate(queue.length, (i) => i);
}

class ControlButtons extends StatelessWidget {
  final AudioPlayerHandler audioHandler;
  final bool shuffle;
  final bool miniplayer;

  const ControlButtons(this.audioHandler,
      {this.shuffle = false, this.miniplayer = false});

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<QueueState>(
            stream: audioHandler.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              return IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: miniplayer ? 24.0 : 45.0,
                tooltip: 'Skip Previous',
                onPressed:
                    queueState.hasPrevious ? audioHandler.skipToPrevious : null,
              );
            },
          ),
          SizedBox(
            height: miniplayer ? 40.0 : 65.0,
            width: miniplayer ? 40.0 : 65.0,
            child: StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playbackState = snapshot.data;
                  final processingState = playbackState?.processingState;
                  final playing = playbackState?.playing ?? false;
                  return Stack(
                    children: [
                      if (processingState == AudioProcessingState.loading ||
                          processingState == AudioProcessingState.buffering)
                        Center(
                          child: SizedBox(
                            height: miniplayer ? 40.0 : 65.0,
                            width: miniplayer ? 40.0 : 65.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).accentColor),
                            ),
                          ),
                        ),
                      if (miniplayer)
                        Center(
                            child: playing
                                ? IconButton(
                                    tooltip: 'Pause',
                                    onPressed: audioHandler.pause,
                                    icon: const Icon(
                                      Icons.pause_rounded,
                                    ),
                                  )
                                : IconButton(
                                    tooltip: 'Play',
                                    onPressed: audioHandler.play,
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                    ),
                                  ))
                      else
                        Center(
                          child: SizedBox(
                              height: 59,
                              width: 59,
                              child: Center(
                                child: playing
                                    ? FloatingActionButton(
                                        elevation: 10,
                                        tooltip: 'Pause',
                                        onPressed: audioHandler.pause,
                                        child: const Icon(
                                          Icons.pause_rounded,
                                          size: 40.0,
                                          color: Colors.white,
                                        ),
                                      )
                                    : FloatingActionButton(
                                        elevation: 10,
                                        tooltip: 'Play',
                                        onPressed: audioHandler.play,
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 40.0,
                                          color: Colors.white,
                                        ),
                                      ),
                              )),
                        ),
                    ],
                  );
                }),
          ),
          StreamBuilder<QueueState>(
            stream: audioHandler.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              return IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: miniplayer ? 24.0 : 45.0,
                tooltip: 'Skip Next',
                onPressed: queueState.hasNext ? audioHandler.skipToNext : null,
              );
            },
          ),
        ]);
  }
}

abstract class AudioPlayerHandler implements AudioHandler {
  Stream<QueueState> get queueState;
  Future<void> moveQueueItem(int currentIndex, int newIndex);
  ValueStream<double> get volume;
  Future<void> setVolume(double volume);
  ValueStream<double> get speed;
}

class NowPlayingStream extends StatelessWidget {
  final AudioPlayerHandler audioHandler;
  final bool hideHeader;

  const NowPlayingStream(this.audioHandler, {this.hideHeader = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueueState>(
        stream: audioHandler.queueState,
        builder: (context, snapshot) {
          final queueState = snapshot.data ?? QueueState.empty;
          final queue = queueState.queue;
          return ReorderableListView.builder(
              header: hideHeader
                  ? null
                  : SizedBox(
                      key: const Key('head'),
                      height: 50,
                      child: Center(
                        child: SizedBox.expand(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              primary: Theme.of(context).iconTheme.color,
                              backgroundColor: Colors.transparent,
                              elevation: 0.0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Now Playing',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  newIndex--;
                }
                audioHandler.moveQueueItem(oldIndex, newIndex);
              },
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 10),
              shrinkWrap: true,
              itemCount: queue.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: ValueKey(queue[index].id),
                  direction: index == queueState.queueIndex
                      ? DismissDirection.none
                      : DismissDirection.horizontal,
                  onDismissed: (dir) {
                    audioHandler.removeQueueItemAt(index);
                  },
                  child: ListTileTheme(
                    selectedColor: Theme.of(context).accentColor,
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.only(left: 16.0, right: 10.0),
                      selected: index == queueState.queueIndex,
                      trailing: index == queueState.queueIndex
                          ? IconButton(
                              icon: const Icon(
                                Icons.bar_chart_rounded,
                              ),
                              tooltip: 'Playing',
                              onPressed: () {},
                            )
                          : queue[index]
                                  .extras!['url']
                                  .toString()
                                  .startsWith('http')
                              ? Row(
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
                                      'duration': queue[index]
                                          .duration!
                                          .inSeconds
                                          .toString(),
                                      'title': queue[index].title.toString(),
                                      'url': queue[index]
                                          .extras?['url']
                                          .toString(),
                                      'year': queue[index]
                                          .extras?['year']
                                          .toString(),
                                      'language': queue[index]
                                          .extras?['language']
                                          .toString(),
                                      'genre': queue[index].genre?.toString(),
                                      '320kbps':
                                          queue[index].extras?['320kbps'],
                                      'has_lyrics':
                                          queue[index].extras?['has_lyrics'],
                                      'release_date':
                                          queue[index].extras?['release_date'],
                                      'album_id':
                                          queue[index].extras?['album_id'],
                                      'subtitle':
                                          queue[index].extras?['subtitle']
                                    })
                                  ],
                                )
                              : const SizedBox(),
                      leading: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (queue[index].artUri == null)
                            ? const SizedBox(
                                height: 50.0,
                                width: 50.0,
                                child: Image(
                                  image: AssetImage('assets/cover.jpg'),
                                ),
                              )
                            : SizedBox(
                                height: 50.0,
                                width: 50.0,
                                child: queue[index]
                                        .artUri
                                        .toString()
                                        .startsWith('file:')
                                    ? Image(
                                        fit: BoxFit.cover,
                                        image: FileImage(File(
                                            queue[index].artUri!.toFilePath())))
                                    : CachedNetworkImage(
                                        fit: BoxFit.cover,
                                        errorWidget:
                                            (BuildContext context, _, __) =>
                                                const Image(
                                          image: AssetImage('assets/cover.jpg'),
                                        ),
                                        placeholder:
                                            (BuildContext context, _) =>
                                                const Image(
                                          image: AssetImage('assets/cover.jpg'),
                                        ),
                                        imageUrl:
                                            queue[index].artUri.toString(),
                                      ),
                              ),
                      ),
                      title: Text(
                        queue[index].title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: index == queueState.queueIndex
                                ? FontWeight.w600
                                : FontWeight.normal),
                      ),
                      subtitle: Text(
                        queue[index].artist!,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        audioHandler.skipToQueueItem(index);
                      },
                    ),
                  ),
                );
              });
        });
  }
}

class ArtWorkWidget extends StatefulWidget {
  final GlobalKey<FlipCardState> cardKey;
  final MediaItem mediaItem;
  final bool offline;
  final double width;

  const ArtWorkWidget(this.cardKey, this.mediaItem, this.width,
      {this.offline = false});

  @override
  _ArtWorkWidgetState createState() => _ArtWorkWidgetState();
}

class _ArtWorkWidgetState extends State<ArtWorkWidget> {
  final ValueNotifier<bool> dragging = ValueNotifier<bool>(false);
  final ValueNotifier<bool> done = ValueNotifier<bool>(false);
  Map lyrics = {'id': '', 'lyrics': ''};

  Future<String> fetchLyrics() async {
    return Lyrics().getLyrics(
        widget.mediaItem.title.toString(), widget.mediaItem.artist.toString());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.width * 0.9,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: widget.width * 0.85,
          width: widget.width * 0.85,
          child: Hero(
            tag: 'currentArtwork',
            child: FlipCard(
              key: widget.cardKey,
              flipOnTouch: false,
              onFlipDone: (value) {
                if (lyrics['id'] != widget.mediaItem.id ||
                    (!value && lyrics['lyrics'] == '' && !done.value)) {
                  done.value = false;
                  fetchLyrics().then((value) {
                    lyrics['lyrics'] = value;
                    lyrics['id'] = widget.mediaItem.id;
                    done.value = true;
                  });
                }
              },
              back: GestureDetector(
                onTap: () => widget.cardKey.currentState!.toggleCard(),
                onDoubleTap: () => widget.cardKey.currentState!.toggleCard(),
                child: Card(
                  elevation: 10.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0)),
                  clipBehavior: Clip.antiAlias,
                  child: GradientContainer(
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.transparent],
                        ).createShader(
                            Rect.fromLTRB(0, 0, rect.width, rect.height));
                      },
                      blendMode: BlendMode.dstIn,
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 50),
                          child: widget.offline
                              ? FutureBuilder(
                                  future: Lyrics().getOffLyrics(
                                    widget.mediaItem.id.toString(),
                                  ),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      final String lyrics = snapshot.data ?? '';
                                      if (lyrics == '') {
                                        return EmptyScreen().emptyScreen(
                                            context,
                                            0,
                                            ':( ',
                                            100.0,
                                            'Lyrics',
                                            60.0,
                                            'Not Available',
                                            20.0);
                                      }
                                      return SelectableText(
                                        lyrics,
                                        textAlign: TextAlign.center,
                                      );
                                    }
                                    return CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Theme.of(context).accentColor),
                                    );
                                  })
                              : widget.mediaItem.extras?['has_lyrics'] == 'true'
                                  ? FutureBuilder(
                                      future: Lyrics().getSaavnLyrics(
                                          widget.mediaItem.id.toString()),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<String> snapshot) {
                                        String? lyrics;
                                        if (snapshot.connectionState ==
                                            ConnectionState.done) {
                                          lyrics = snapshot.data;
                                          return Text(
                                            lyrics!,
                                            textAlign: TextAlign.center,
                                          );
                                        }
                                        return CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<
                                                  Color>(
                                              Theme.of(context).accentColor),
                                        );
                                      })
                                  : ValueListenableBuilder(
                                      valueListenable: done,
                                      builder: (BuildContext context,
                                          bool value, Widget? child) {
                                        return value
                                            ? lyrics['lyrics'] == ''
                                                ? EmptyScreen().emptyScreen(
                                                    context,
                                                    0,
                                                    ':( ',
                                                    100.0,
                                                    'Lyrics',
                                                    60.0,
                                                    'Not Available',
                                                    20.0)
                                                : Text(
                                                    lyrics['lyrics'].toString(),
                                                    textAlign: TextAlign.center,
                                                  )
                                            : CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Theme.of(context)
                                                            .accentColor),
                                              );
                                      }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              front: StreamBuilder<QueueState>(
                  stream: audioHandler.queueState,
                  builder: (context, snapshot) {
                    final queueState = snapshot.data ?? QueueState.empty;
                    return GestureDetector(
                      onTap: () {
                        audioHandler.playbackState.value.playing
                            ? audioHandler.pause()
                            : audioHandler.play();
                      },
                      onDoubleTap: () =>
                          widget.cardKey.currentState!.toggleCard(),
                      onHorizontalDragEnd: (DragEndDetails details) {
                        if ((details.primaryVelocity ?? 0) > 100) {
                          if (queueState.hasPrevious) {
                            audioHandler.skipToPrevious();
                          }
                        }

                        if ((details.primaryVelocity ?? 0) < -100) {
                          if (queueState.hasNext) {
                            audioHandler.skipToNext();
                          }
                        }
                      },
                      onLongPress: () {
                        if (!widget.offline) {
                          AddToPlaylist()
                              .addToPlaylist(context, widget.mediaItem);
                        }
                      },
                      onVerticalDragStart: (_) {
                        dragging.value = true;
                      },
                      onVerticalDragEnd: (_) {
                        dragging.value = false;
                      },
                      onVerticalDragUpdate: (DragUpdateDetails details) {
                        if (details.delta.dy != 0.0) {
                          double volume = audioHandler.volume.value;
                          volume -= details.delta.dy / 150;
                          if (volume < 0) {
                            volume = 0;
                          }
                          if (volume > 1.0) {
                            volume = 1.0;
                          }
                          audioHandler.setVolume(volume);
                        }
                      },
                      child: Stack(
                        children: [
                          Card(
                            elevation: 10.0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0)),
                            clipBehavior: Clip.antiAlias,
                            child: widget.mediaItem.artUri
                                    .toString()
                                    .startsWith('file')
                                ? Image(
                                    fit: BoxFit.cover,
                                    height: widget.width * 0.85,
                                    width: widget.width * 0.85,
                                    image: FileImage(File(
                                        widget.mediaItem.artUri!.toFilePath())))
                                : CachedNetworkImage(
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        (BuildContext context, _, __) =>
                                            const Image(
                                      image: AssetImage('assets/cover.jpg'),
                                    ),
                                    placeholder: (BuildContext context, _) =>
                                        const Image(
                                      image: AssetImage('assets/cover.jpg'),
                                    ),
                                    imageUrl:
                                        widget.mediaItem.artUri.toString(),
                                    height: widget.width * 0.85,
                                  ),
                          ),
                          ValueListenableBuilder(
                              valueListenable: dragging,
                              builder: (BuildContext context, bool value,
                                  Widget? child) {
                                return Visibility(
                                  visible: value,
                                  child: StreamBuilder<double>(
                                      stream: audioHandler.volume,
                                      builder: (context, snapshot) {
                                        final double volumeValue =
                                            snapshot.data ?? 1.0;
                                        return Center(
                                          child: SizedBox(
                                            width: 60.0,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.7,
                                            child: Card(
                                              color: Colors.black87,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Expanded(
                                                    child: FittedBox(
                                                      fit: BoxFit.fitHeight,
                                                      child: RotatedBox(
                                                        quarterTurns: -1,
                                                        child: SliderTheme(
                                                          data: SliderTheme.of(
                                                                  context)
                                                              .copyWith(
                                                            thumbShape:
                                                                HiddenThumbComponentShape(),
                                                            activeTrackColor:
                                                                Theme.of(
                                                                        context)
                                                                    .accentColor,
                                                            inactiveTrackColor:
                                                                Theme.of(
                                                                        context)
                                                                    .accentColor
                                                                    .withOpacity(
                                                                        0.4),
                                                            trackShape:
                                                                const RoundedRectSliderTrackShape(),
                                                          ),
                                                          child:
                                                              ExcludeSemantics(
                                                            child: Slider(
                                                              value:
                                                                  audioHandler
                                                                      .volume
                                                                      .value,
                                                              onChanged: (_) {},
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 20.0),
                                                    child: Icon(volumeValue == 0
                                                        ? Icons
                                                            .volume_off_rounded
                                                        : volumeValue > 0.6
                                                            ? Icons
                                                                .volume_up_rounded
                                                            : Icons
                                                                .volume_down_rounded),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                );
                              }),
                        ],
                      ),
                    );
                  }),
            ),
          ),
        ),
      ),
    );
  }
}

class NameNControls extends StatelessWidget {
  final MediaItem mediaItem;
  final bool offline;

  const NameNControls(this.mediaItem, {this.offline = false});

  Stream<Duration> get _bufferedPositionStream => audioHandler.playbackState
      .map((state) => state.bufferedPosition)
      .distinct();
  Stream<Duration?> get _durationStream =>
      audioHandler.mediaItem.map((item) => item?.duration).distinct();
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          AudioService.position,
          _bufferedPositionStream,
          _durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        /// Title and subtitle
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(35, 5, 35, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  /// Title container
                  Text(
                    mediaItem.title.split(' (')[0].split('|')[0].trim(),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).accentColor,
                    ),
                  ),

                  /// Subtitle container
                  Text(
                    mediaItem.artist ?? 'Unknown',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        /// Seekbar starts from here
        StreamBuilder<PositionData>(
          stream: _positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data ??
                PositionData(Duration.zero, Duration.zero,
                    mediaItem.duration ?? Duration.zero);
            return SeekBar(
              duration: positionData.duration,
              position: positionData.position,
              bufferedPosition: positionData.bufferedPosition,
              onChangeEnd: (newPosition) {
                audioHandler.seek(newPosition);
              },
            );
          },
        ),

        /// Final row starts from here
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 6.0),
                  StreamBuilder<bool>(
                    stream: audioHandler.playbackState
                        .map((state) =>
                            state.shuffleMode == AudioServiceShuffleMode.all)
                        .distinct(),
                    builder: (context, snapshot) {
                      final shuffleModeEnabled = snapshot.data ?? false;
                      return IconButton(
                        icon: shuffleModeEnabled
                            ? Icon(Icons.shuffle,
                                color: Theme.of(context).accentColor)
                            : const Icon(
                                Icons.shuffle,
                              ),
                        tooltip: 'Shuffle',
                        onPressed: () async {
                          final enable = !shuffleModeEnabled;
                          await audioHandler.setShuffleMode(enable
                              ? AudioServiceShuffleMode.all
                              : AudioServiceShuffleMode.none);
                        },
                      );
                    },
                  ),
                  if (!offline) LikeButton(mediaItem: mediaItem, size: 25.0)
                ],
              ),
              ControlButtons(audioHandler),
              Column(
                children: [
                  const SizedBox(height: 6.0),
                  StreamBuilder<AudioServiceRepeatMode>(
                    stream: audioHandler.playbackState
                        .map((state) => state.repeatMode)
                        .distinct(),
                    builder: (context, snapshot) {
                      final repeatMode =
                          snapshot.data ?? AudioServiceRepeatMode.none;
                      const texts = ['None', 'All', 'One'];
                      final icons = [
                        const Icon(
                          Icons.repeat_rounded,
                        ),
                        Icon(Icons.repeat_rounded,
                            color: Theme.of(context).accentColor),
                        Icon(Icons.repeat_one_rounded,
                            color: Theme.of(context).accentColor),
                      ];
                      const cycleModes = [
                        AudioServiceRepeatMode.none,
                        AudioServiceRepeatMode.all,
                        AudioServiceRepeatMode.one,
                      ];
                      final index = cycleModes.indexOf(repeatMode);
                      return IconButton(
                        icon: icons[index],
                        tooltip: 'Repeat ${texts[(index + 1) % texts.length]}',
                        onPressed: () {
                          Hive.box('settings').put(
                              'repeatMode', texts[(index + 1) % texts.length]);
                          audioHandler.setRepeatMode(cycleModes[
                              (cycleModes.indexOf(repeatMode) + 1) %
                                  cycleModes.length]);
                        },
                      );
                    },
                  ),
                  if (!offline)
                    DownloadButton(data: {
                      'id': mediaItem.id.toString(),
                      'artist': mediaItem.artist.toString(),
                      'album': mediaItem.album.toString(),
                      'image': mediaItem.artUri.toString(),
                      'duration': mediaItem.duration?.inSeconds.toString(),
                      'title': mediaItem.title.toString(),
                      'url': mediaItem.extras!['url'].toString(),
                      'year': mediaItem.extras!['year'].toString(),
                      'language': mediaItem.extras!['language'].toString(),
                      'genre': mediaItem.genre?.toString(),
                      '320kbps': mediaItem.extras?['320kbps'],
                      'has_lyrics': mediaItem.extras?['has_lyrics'],
                      'release_date': mediaItem.extras!['release_date'],
                      'album_id': mediaItem.extras!['album_id'],
                      'subtitle': mediaItem.extras!['subtitle']
                    })
                ],
              ),
            ],
          ),
        ),

        // Now playing
        TextButton(
          onPressed: () {
            showModalBottomSheet(
                isDismissible: true,
                backgroundColor: Colors.transparent,
                context: context,
                builder: (BuildContext context) {
                  return BottomGradientContainer(
                      padding: EdgeInsets.zero,
                      margin: const EdgeInsets.only(left: 20, right: 20),
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15.0),
                          topRight: Radius.circular(15.0)),
                      child: NowPlayingStream(audioHandler));
                });
          },
          child: Text(
            'Now Playing',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).iconTheme.color,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}
