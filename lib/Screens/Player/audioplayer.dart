import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/animated_text.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/equalizer.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/popup.dart';
import 'package:blackhole/CustomWidgets/seek_bar.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/config.dart';
import 'package:blackhole/Helpers/lyrics.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayScreen extends StatefulWidget {
  final List songsList;
  final bool fromMiniplayer;
  final bool? offline;
  final int index;
  final bool recommend;
  final bool fromDownloads;
  const PlayScreen({
    Key? key,
    required this.index,
    required this.songsList,
    required this.fromMiniplayer,
    required this.offline,
    required this.recommend,
    required this.fromDownloads,
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
  bool useImageColor =
      Hive.box('settings').get('useImageColor', defaultValue: true) as bool;
  List<MediaItem> globalQueue = [];
  int globalIndex = 0;
  List response = [];
  bool offline = false;
  bool fromDownloads = false;
  String defaultCover = '';
  final ValueNotifier<Color?> gradientColor =
      ValueNotifier<Color?>(currentTheme.playGradientColor);

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
    response = widget.songsList;
    globalIndex = widget.index;
    if (globalIndex == -1) {
      globalIndex = 0;
    }
    fromDownloads = widget.fromDownloads;
    if (widget.offline == null) {
      if (audioHandler.mediaItem.value?.extras!['url'].startsWith('http')
          as bool) {
        offline = false;
      } else {
        offline = true;
      }
    } else {
      offline = widget.offline!;
    }

    fromMiniplayer = widget.fromMiniplayer;
    if (!fromMiniplayer) {
      if (offline) {
        fromDownloads ? setDownValues(response) : setOffValues(response);
      } else {
        setValues(response);
        updateNplay();
      }
    }
  }

  Future<MediaItem> setTags(SongModel response, Directory tempDir) async {
    String playTitle = response.title;
    playTitle == ''
        ? playTitle = response.displayNameWOExt
        : playTitle = response.title;
    String playArtist = response.artist!;
    playArtist == '<unknown>'
        ? playArtist = 'Unknown'
        : playArtist = response.artist!;

    final String playAlbum = response.album!;
    final int playDuration = response.duration ?? 180000;
    final String imagePath = '${tempDir.path}/${response.displayNameWOExt}.jpg';

    final MediaItem tempDict = MediaItem(
      id: response.id.toString(),
      album: playAlbum,
      duration: Duration(milliseconds: playDuration),
      title: playTitle.split('(')[0],
      artist: playArtist,
      genre: response.genre,
      artUri: Uri.file(imagePath),
      extras: {
        'url': response.data,
        'date_added': response.dateAdded,
        'date_modified': response.dateModified,
        'size': response.size,
      },
    );
    return tempDict;
  }

  void setOffValues(List response, {bool downloaed = false}) {
    getTemporaryDirectory().then((tempDir) async {
      final File file =
          File('${(await getTemporaryDirectory()).path}/cover.jpg');
      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/cover.jpg');
        await file.writeAsBytes(
          byteData.buffer
              .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
      }
      for (int i = 0; i < response.length; i++) {
        globalQueue.add(
          await setTags(response[i] as SongModel, tempDir),
        );
      }
      updateNplay();
    });
  }

  void setDownValues(List response) {
    globalQueue.addAll(
      response.map(
        (song) => MediaItemConverter.downMapToMediaItem(song as Map),
      ),
    );
    updateNplay();
  }

  void setValues(List response) {
    globalQueue.addAll(
      response.map(
        (song) => MediaItemConverter.mapToMediaItem(
          song as Map,
          autoplay: widget.recommend,
        ),
      ),
    );
  }

  Future<void> updateNplay() async {
    await audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
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
    } else {
      audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
      Hive.box('settings').put('repeatMode', 'None');
    }
  }

  String format(String msg) {
    return '${msg[0].toUpperCase()}${msg.substring(1)}: '.replaceAll('_', ' ');
  }

  Future<void> getColors(ImageProvider imageProvider) async {
    PaletteGenerator paletteGenerator;
    paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
    Color dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
    if (dominantColor.computeLuminance() > 0.6) {
      Color contrastColor =
          paletteGenerator.darkMutedColor?.color ?? Colors.black;
      if (dominantColor == contrastColor) {
        contrastColor = paletteGenerator.lightMutedColor?.color ?? Colors.white;
      }
      if (contrastColor.computeLuminance() < 0.6) {
        dominantColor = contrastColor;
      }
    }
    gradientColor.value = dominantColor;
    currentTheme.setLastPlayGradient(gradientColor.value);
  }

  @override
  Widget build(BuildContext context) {
    BuildContext? scaffoldContext;

    return Dismissible(
      direction: DismissDirection.down,
      background: Container(color: Colors.transparent),
      key: const Key('playScreen'),
      onDismissed: (direction) {
        Navigator.pop(context);
      },
      child: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final MediaItem? mediaItem = snapshot.data;
          if (mediaItem == null) return const SizedBox();
          mediaItem.artUri.toString().startsWith('file')
              ? getColors(
                  FileImage(
                    File(
                      mediaItem.artUri!.toFilePath(),
                    ),
                  ),
                )
              : getColors(
                  CachedNetworkImageProvider(
                    mediaItem.artUri.toString(),
                  ),
                );
          return ValueListenableBuilder(
            valueListenable: gradientColor,
            child: SafeArea(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.expand_more_rounded),
                    tooltip: AppLocalizations.of(context)!.back,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: Image.asset(
                        'assets/lyrics.png',
                      ),
                      tooltip: AppLocalizations.of(context)!.lyrics,
                      onPressed: () => cardKey.currentState!.toggleCard(),
                    ),
                    if (!offline)
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        tooltip: AppLocalizations.of(context)!.share,
                        onPressed: () {
                          Share.share(
                            mediaItem.extras!['perma_url'].toString(),
                          );
                        },
                      ),
                    PopupMenuButton(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(15.0),
                        ),
                      ),
                      onSelected: (int? value) {
                        if (value == 10) {
                          final Map details =
                              MediaItemConverter.mediaItemtoMap(mediaItem);
                          if (mediaItem.extras?['size'] != null) {
                            details.addEntries([
                              MapEntry(
                                'date_modified',
                                '${mediaItem.extras?['date_modified']}',
                              ),
                              MapEntry(
                                'size',
                                '${((mediaItem.extras?['size'] as int) / (1024 * 1024)).toStringAsFixed(2)} MB',
                              ),
                            ]);
                          }
                          PopupDialog().showPopup(
                            context: context,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.all(25.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: details.keys.map((e) {
                                  return RichText(
                                    text: TextSpan(
                                      text: format(
                                        e.toString(),
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyText1!
                                            .color,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: details[e].toString(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }
                        if (value == 5) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              opaque: false,
                              pageBuilder: (_, __, ___) => SongsListPage(
                                listItem: {
                                  'type': 'album',
                                  'id': mediaItem.extras?['album_id'],
                                  'title': mediaItem.album,
                                  'image': mediaItem.artUri,
                                },
                              ),
                            ),
                          );
                        }
                        if (value == 4) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return const Equalizer();
                            },
                          );
                        }
                        if (value == 3) {
                          launch(
                            mediaItem.genre == 'YouTube'
                                ? 'https://youtube.com/watch?v=${mediaItem.id}'
                                : 'https://www.youtube.com/results?search_query=${mediaItem.title} by ${mediaItem.artist}',
                          );
                        }
                        if (value == 1) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return SimpleDialog(
                                title: Text(
                                  AppLocalizations.of(context)!.sleepTimer,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(10.0),
                                children: [
                                  ListTile(
                                    title: Text(
                                      AppLocalizations.of(context)!.sleepDur,
                                    ),
                                    subtitle: Text(
                                      AppLocalizations.of(context)!.sleepDurSub,
                                    ),
                                    dense: true,
                                    onTap: () {
                                      Navigator.pop(context);
                                      setTimer(
                                        context,
                                        scaffoldContext,
                                      );
                                    },
                                  ),
                                  ListTile(
                                    title: Text(
                                      AppLocalizations.of(context)!.sleepAfter,
                                    ),
                                    subtitle: Text(
                                      AppLocalizations.of(context)!
                                          .sleepAfterSub,
                                    ),
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
                      },
                      itemBuilder: (context) => offline
                          ? [
                              if (mediaItem.extras?['album_id'] != null)
                                PopupMenuItem(
                                  value: 5,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.album_rounded,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      const SizedBox(width: 10.0),
                                      Text(
                                        AppLocalizations.of(context)!.viewAlbum,
                                      ),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.timer,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Text(
                                      AppLocalizations.of(context)!.sleepTimer,
                                    ),
                                  ],
                                ),
                              ),
                              if (Hive.box('settings').get(
                                'supportEq',
                                defaultValue: false,
                              ) as bool)
                                PopupMenuItem(
                                  value: 4,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.equalizer_rounded,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      const SizedBox(width: 10.0),
                                      Text(
                                        AppLocalizations.of(context)!.equalizer,
                                      ),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 10,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_rounded,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Text(
                                      AppLocalizations.of(context)!.songInfo,
                                    ),
                                  ],
                                ),
                              ),
                            ]
                          : [
                              if (mediaItem.extras?['album_id'] != null)
                                PopupMenuItem(
                                  value: 5,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.album_rounded,
                                      ),
                                      const SizedBox(width: 10.0),
                                      Text(
                                        AppLocalizations.of(context)!.viewAlbum,
                                      ),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 0,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.playlist_add_rounded,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .addToPlaylist,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.timer,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Text(
                                      AppLocalizations.of(context)!.sleepTimer,
                                    ),
                                  ],
                                ),
                              ),
                              if (Hive.box('settings').get(
                                'supportEq',
                                defaultValue: false,
                              ) as bool)
                                PopupMenuItem(
                                  value: 4,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.equalizer_rounded,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      const SizedBox(width: 10.0),
                                      Text(
                                        AppLocalizations.of(context)!.equalizer,
                                      ),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: 3,
                                child: Row(
                                  children: [
                                    Icon(
                                      MdiIcons.youtube,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Text(
                                      mediaItem.genre == 'YouTube'
                                          ? AppLocalizations.of(
                                              context,
                                            )!
                                              .watchVideo
                                          : AppLocalizations.of(
                                              context,
                                            )!
                                              .searchVideo,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 10,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_rounded,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    const SizedBox(width: 10.0),
                                    Text(
                                      AppLocalizations.of(context)!.songInfo,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                    )
                  ],
                ),
                body: LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
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
                  },
                ),
                // }
              ),
            ),
            builder: (BuildContext context, Color? value, Widget? child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: !useImageColor
                        ? Alignment.topLeft
                        : Alignment.topCenter,
                    end: !useImageColor
                        ? Alignment.bottomRight
                        : Alignment.center,
                    colors: !useImageColor
                        ? Theme.of(context).brightness == Brightness.dark
                            ? currentTheme.getBackGradient()
                            : [
                                const Color(0xfff5f9ff),
                                Colors.white,
                              ]
                        : Theme.of(context).brightness == Brightness.dark
                            ? [
                                value ?? Colors.grey[900]!,
                                currentTheme.getPlayGradient(),
                              ]
                            : [
                                value ?? const Color(0xfff5f9ff),
                                Colors.white,
                              ],
                  ),
                ),
                child: child,
              );
            },
          );
          // );
        },
      ),
    );
  }

  Future<dynamic> setTimer(
    BuildContext context,
    BuildContext? scaffoldContext,
  ) {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.selectDur,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          children: [
            Center(
              child: SizedBox(
                height: 200,
                width: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    primaryColor: Theme.of(context).colorScheme.secondary,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
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
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    primary: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    sleepTimer(0);
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(
                  width: 10,
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    primary:
                        Theme.of(context).colorScheme.secondary == Colors.white
                            ? Colors.black
                            : Colors.white,
                  ),
                  onPressed: () {
                    sleepTimer(_time.inMinutes);
                    Navigator.pop(context);
                    ShowSnackBar().showSnackBar(
                      context,
                      '${AppLocalizations.of(context)!.sleepTimerSetFor} ${_time.inMinutes} ${AppLocalizations.of(context)!.minutes}',
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.ok),
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
    await showTextInputDialog(
      context: scaffoldContext,
      title: AppLocalizations.of(context)!.enterSongsCount,
      initialText: '',
      keyboardType: TextInputType.number,
      onSubmitted: (String value) {
        sleepCounter(
          int.parse(value),
        );
        Navigator.pop(scaffoldContext);
        ShowSnackBar().showSnackBar(
          context,
          '${AppLocalizations.of(context)!.sleepTimerSetFor} $value ${AppLocalizations.of(context)!.songs}',
        );
      },
    );
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
    this.queue,
    this.queueIndex,
    this.shuffleIndices,
    this.repeatMode,
  );

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
  final List buttons;
  final Color? dominantColor;

  const ControlButtons(
    this.audioHandler, {
    this.shuffle = false,
    this.miniplayer = false,
    this.dominantColor,
    this.buttons = const ['Previous', 'Play/Pause', 'Next'],
  });

  @override
  Widget build(BuildContext context) {
    final MediaItem mediaItem = audioHandler.mediaItem.value!;
    final bool online = mediaItem.extras!['url'].toString().startsWith('http');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (buttons.contains('Like') && online)
          LikeButton(
            mediaItem: mediaItem,
            size: 22.0,
          ),
        if (buttons.contains('Previous') || !online)
          StreamBuilder<QueueState>(
            stream: audioHandler.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              return IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: miniplayer ? 24.0 : 45.0,
                tooltip: AppLocalizations.of(context)!.skipPrevious,
                color: Theme.of(context).iconTheme.color,
                onPressed:
                    queueState.hasPrevious ? audioHandler.skipToPrevious : null,
              );
            },
          ),
        if (buttons.contains('Play/Pause') || !online)
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
                              Theme.of(context).iconTheme.color!,
                            ),
                          ),
                        ),
                      ),
                    if (miniplayer)
                      Center(
                        child: playing
                            ? IconButton(
                                tooltip: AppLocalizations.of(context)!.pause,
                                onPressed: audioHandler.pause,
                                icon: const Icon(
                                  Icons.pause_rounded,
                                ),
                                color: Theme.of(context).iconTheme.color,
                              )
                            : IconButton(
                                tooltip: AppLocalizations.of(context)!.play,
                                onPressed: audioHandler.play,
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                ),
                                color: Theme.of(context).iconTheme.color,
                              ),
                      )
                    else
                      Center(
                        child: SizedBox(
                          height: 59,
                          width: 59,
                          child: Center(
                            child: playing
                                ? FloatingActionButton(
                                    elevation: 10,
                                    tooltip:
                                        AppLocalizations.of(context)!.pause,
                                    backgroundColor: Colors.white,
                                    onPressed: audioHandler.pause,
                                    child: const Icon(
                                      Icons.pause_rounded,
                                      size: 40.0,
                                      color: Colors.black,
                                    ),
                                  )
                                : FloatingActionButton(
                                    elevation: 10,
                                    tooltip: AppLocalizations.of(context)!.play,
                                    backgroundColor: Colors.white,
                                    onPressed: audioHandler.play,
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 40.0,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        if (buttons.contains('Next') || !online)
          StreamBuilder<QueueState>(
            stream: audioHandler.queueState,
            builder: (context, snapshot) {
              final queueState = snapshot.data ?? QueueState.empty;
              return IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: miniplayer ? 24.0 : 45.0,
                tooltip: AppLocalizations.of(context)!.skipNext,
                color: Theme.of(context).iconTheme.color,
                onPressed: queueState.hasNext ? audioHandler.skipToNext : null,
              );
            },
          ),
        if (buttons.contains('Download') && online)
          DownloadButton(
            size: 20.0,
            icon: 'download',
            data: {
              'id': mediaItem.id,
              'artist': mediaItem.artist.toString(),
              'album': mediaItem.album.toString(),
              'image': mediaItem.artUri.toString(),
              'duration': mediaItem.duration?.inSeconds.toString(),
              'title': mediaItem.title,
              'url': mediaItem.extras!['url'].toString(),
              'year': mediaItem.extras!['year'].toString(),
              'language': mediaItem.extras!['language'].toString(),
              'genre': mediaItem.genre?.toString(),
              '320kbps': mediaItem.extras?['320kbps'],
              'has_lyrics': mediaItem.extras?['has_lyrics'],
              'release_date': mediaItem.extras!['release_date'],
              'album_id': mediaItem.extras!['album_id'],
              'subtitle': mediaItem.extras!['subtitle'],
              'perma_url': mediaItem.extras!['perma_url'],
            },
          ),
      ],
    );
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
                        child: Text(
                          AppLocalizations.of(context)!.nowPlaying,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
                selectedColor: Theme.of(context).colorScheme.secondary,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.only(left: 16.0, right: 10.0),
                  selected: index == queueState.queueIndex,
                  trailing: index == queueState.queueIndex
                      ? IconButton(
                          icon: const Icon(
                            Icons.bar_chart_rounded,
                          ),
                          tooltip: AppLocalizations.of(context)!.playing,
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
                                DownloadButton(
                                  icon: 'download',
                                  size: 25.0,
                                  data: {
                                    'id': queue[index].id,
                                    'artist': queue[index].artist.toString(),
                                    'album': queue[index].album.toString(),
                                    'image': queue[index].artUri.toString(),
                                    'duration': queue[index]
                                        .duration!
                                        .inSeconds
                                        .toString(),
                                    'title': queue[index].title,
                                    'url':
                                        queue[index].extras?['url'].toString(),
                                    'year':
                                        queue[index].extras?['year'].toString(),
                                    'language': queue[index]
                                        .extras?['language']
                                        .toString(),
                                    'genre': queue[index].genre?.toString(),
                                    '320kbps': queue[index].extras?['320kbps'],
                                    'has_lyrics':
                                        queue[index].extras?['has_lyrics'],
                                    'release_date':
                                        queue[index].extras?['release_date'],
                                    'album_id':
                                        queue[index].extras?['album_id'],
                                    'subtitle':
                                        queue[index].extras?['subtitle'],
                                    'perma_url':
                                        queue[index].extras?['perma_url'],
                                  },
                                )
                              ],
                            )
                          : const SizedBox(),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (queue[index].extras?['addedByAutoplay'] as bool? ??
                          false)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    AppLocalizations.of(context)!.addedBy,
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      fontSize: 5.0,
                                    ),
                                  ),
                                ),
                                RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    AppLocalizations.of(context)!.autoplay,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 8.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                          ],
                        ),
                      Card(
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
                                        image: FileImage(
                                          File(
                                            queue[index].artUri!.toFilePath(),
                                          ),
                                        ),
                                      )
                                    : CachedNetworkImage(
                                        fit: BoxFit.cover,
                                        errorWidget:
                                            (BuildContext context, _, __) =>
                                                const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage(
                                            'assets/cover.jpg',
                                          ),
                                        ),
                                        placeholder:
                                            (BuildContext context, _) =>
                                                const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage(
                                            'assets/cover.jpg',
                                          ),
                                        ),
                                        imageUrl:
                                            queue[index].artUri.toString(),
                                      ),
                              ),
                      ),
                    ],
                  ),
                  title: Text(
                    queue[index].title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: index == queueState.queueIndex
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
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
          },
        );
      },
    );
  }
}

class ArtWorkWidget extends StatefulWidget {
  final GlobalKey<FlipCardState> cardKey;
  final MediaItem mediaItem;
  final bool offline;
  final double width;

  const ArtWorkWidget(
    this.cardKey,
    this.mediaItem,
    this.width, {
    this.offline = false,
  });

  @override
  _ArtWorkWidgetState createState() => _ArtWorkWidgetState();
}

class _ArtWorkWidgetState extends State<ArtWorkWidget> {
  final ValueNotifier<bool> dragging = ValueNotifier<bool>(false);
  final ValueNotifier<bool> done = ValueNotifier<bool>(false);
  Map lyrics = {'id': '', 'lyrics': ''};

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
                  if (widget.offline) {
                    Lyrics.getOffLyrics(
                      widget.mediaItem.extras!['url'].toString(),
                    ).then((value) {
                      lyrics['lyrics'] = value;
                      lyrics['id'] = widget.mediaItem.id;
                      done.value = true;
                    });
                  } else {
                    Lyrics.getLyrics(
                      id: widget.mediaItem.id,
                      saavnHas:
                          widget.mediaItem.extras?['has_lyrics'] == 'true',
                      title: widget.mediaItem.title,
                      artist: widget.mediaItem.artist.toString(),
                    ).then((value) {
                      lyrics['lyrics'] = value;
                      lyrics['id'] = widget.mediaItem.id;
                      done.value = true;
                    });
                  }
                }
              },
              back: GestureDetector(
                onTap: () => widget.cardKey.currentState!.toggleCard(),
                onDoubleTap: () => widget.cardKey.currentState!.toggleCard(),
                child: Stack(
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.black,
                            Colors.transparent
                          ],
                        ).createShader(
                          Rect.fromLTRB(0, 0, rect.width, rect.height),
                        );
                      },
                      blendMode: BlendMode.dstIn,
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            vertical: 55,
                            horizontal: 10,
                          ),
                          child: ValueListenableBuilder(
                            valueListenable: done,
                            child: const CircularProgressIndicator(),
                            builder: (
                              BuildContext context,
                              bool value,
                              Widget? child,
                            ) {
                              return value
                                  ? lyrics['lyrics'] == ''
                                      ? emptyScreen(
                                          context,
                                          0,
                                          ':( ',
                                          100.0,
                                          AppLocalizations.of(context)!.lyrics,
                                          60.0,
                                          AppLocalizations.of(context)!
                                              .notAvailable,
                                          20.0,
                                          useWhite: true,
                                        )
                                      : SelectableText(
                                          lyrics['lyrics'].toString(),
                                          textAlign: TextAlign.center,
                                        )
                                  : child!;
                            },
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Card(
                        elevation: 10.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        color: Theme.of(context).cardColor.withOpacity(0.6),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          tooltip: AppLocalizations.of(context)!.copy,
                          onPressed: () {
                            Feedback.forLongPress(context);
                            copyToClipboard(
                              context: context,
                              text: lyrics['lyrics'].toString(),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                          color: Theme.of(context)
                              .iconTheme
                              .color!
                              .withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              front: StreamBuilder<QueueState>(
                stream: audioHandler.queueState,
                builder: (context, snapshot) {
                  final queueState = snapshot.data ?? QueueState.empty;

                  final bool enabled = Hive.box('settings')
                      .get('enableGesture', defaultValue: true) as bool;
                  return GestureDetector(
                    onTap: !enabled
                        ? null
                        : () {
                            audioHandler.playbackState.value.playing
                                ? audioHandler.pause()
                                : audioHandler.play();
                          },
                    onDoubleTap: !enabled
                        ? null
                        : () {
                            Feedback.forLongPress(context);
                            widget.cardKey.currentState!.toggleCard();
                          },
                    onHorizontalDragEnd: !enabled
                        ? null
                        : (DragEndDetails details) {
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
                    onLongPress: !enabled
                        ? null
                        : () {
                            if (!widget.offline) {
                              Feedback.forLongPress(context);
                              AddToPlaylist()
                                  .addToPlaylist(context, widget.mediaItem);
                            }
                          },
                    onVerticalDragStart: !enabled
                        ? null
                        : (_) {
                            dragging.value = true;
                          },
                    onVerticalDragEnd: !enabled
                        ? null
                        : (_) {
                            dragging.value = false;
                          },
                    onVerticalDragUpdate: !enabled
                        ? null
                        : (DragUpdateDetails details) {
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
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.mediaItem.artUri
                                  .toString()
                                  .startsWith('file')
                              ? Image(
                                  fit: BoxFit.cover,
                                  height: widget.width * 0.85,
                                  width: widget.width * 0.85,
                                  gaplessPlayback: true,
                                  image: FileImage(
                                    File(
                                      widget.mediaItem.artUri!.toFilePath(),
                                    ),
                                  ),
                                )
                              : CachedNetworkImage(
                                  fit: BoxFit.cover,
                                  errorWidget: (BuildContext context, _, __) =>
                                      const Image(
                                    fit: BoxFit.cover,
                                    image: AssetImage('assets/cover.jpg'),
                                  ),
                                  placeholder: (BuildContext context, _) =>
                                      const Image(
                                    fit: BoxFit.cover,
                                    image: AssetImage('assets/cover.jpg'),
                                  ),
                                  imageUrl: widget.mediaItem.artUri.toString(),
                                  height: widget.width * 0.85,
                                ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: dragging,
                          child: StreamBuilder<double>(
                            stream: audioHandler.volume,
                            builder: (context, snapshot) {
                              final double volumeValue = snapshot.data ?? 1.0;
                              return Center(
                                child: SizedBox(
                                  width: 60.0,
                                  height:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Card(
                                    color: Colors.black87,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
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
                                                data: SliderTheme.of(context)
                                                    .copyWith(
                                                  thumbShape:
                                                      HiddenThumbComponentShape(),
                                                  activeTrackColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                  inactiveTrackColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                          .withOpacity(0.4),
                                                  trackShape:
                                                      const RoundedRectSliderTrackShape(),
                                                ),
                                                child: ExcludeSemantics(
                                                  child: Slider(
                                                    value: audioHandler
                                                        .volume.value,
                                                    onChanged: (_) {},
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 20.0,
                                          ),
                                          child: Icon(
                                            volumeValue == 0
                                                ? Icons.volume_off_rounded
                                                : volumeValue > 0.6
                                                    ? Icons.volume_up_rounded
                                                    : Icons.volume_down_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          builder: (
                            BuildContext context,
                            bool value,
                            Widget? child,
                          ) {
                            return Visibility(
                              visible: value,
                              child: child!,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
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
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        /// Title and subtitle
        PopupMenuButton<int>(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          offset: const Offset(1.0, 0.0),
          onSelected: (int value) {
            if (value == 0) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => SongsListPage(
                    listItem: {
                      'type': 'album',
                      'id': mediaItem.extras?['album_id'],
                      'title': mediaItem.album,
                      'image': mediaItem.artUri,
                    },
                  ),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
            if (mediaItem.extras?['album_id'] != null)
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    const Icon(
                      Icons.album_rounded,
                    ),
                    const SizedBox(width: 10.0),
                    Text(AppLocalizations.of(context)!.viewAlbum),
                  ],
                ),
              ),
          ],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(35, 5, 35, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    /// Title container
                    SizedBox(
                      height: (35.0) * MediaQuery.of(context).textScaleFactor,
                      child: AnimatedText(
                        text:
                            mediaItem.title.split(' (')[0].split('|')[0].trim(),
                        pauseAfterRound: const Duration(seconds: 3),
                        showFadingOnlyWhenScrolling: false,
                        fadingEdgeEndFraction: 0.1,
                        fadingEdgeStartFraction: 0.1,
                        startAfter: const Duration(seconds: 2),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          // color: Theme.of(context).accentColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 3.0),

                    /// Subtitle container
                    SizedBox(
                      height: (18.0) * MediaQuery.of(context).textScaleFactor,
                      child: AnimatedText(
                        text:
                            '${mediaItem.artist ?? "Unknown"} • ${mediaItem.album ?? "Unknown"}',
                        pauseAfterRound: const Duration(seconds: 3),
                        showFadingOnlyWhenScrolling: false,
                        fadingEdgeEndFraction: 0.1,
                        fadingEdgeStartFraction: 0.1,
                        startAfter: const Duration(seconds: 2),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// Seekbar starts from here

        StreamBuilder<PositionData>(
          stream: _positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data ??
                PositionData(
                  Duration.zero,
                  Duration.zero,
                  mediaItem.duration ?? Duration.zero,
                );
            return SeekBar(
              duration: positionData.duration,
              position: positionData.position,
              bufferedPosition: positionData.bufferedPosition,
              offline: offline,
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
                        .map(
                          (state) =>
                              state.shuffleMode == AudioServiceShuffleMode.all,
                        )
                        .distinct(),
                    builder: (context, snapshot) {
                      final shuffleModeEnabled = snapshot.data ?? false;
                      return IconButton(
                        icon: shuffleModeEnabled
                            ? const Icon(
                                Icons.shuffle_rounded,
                              )
                            : Icon(
                                Icons.shuffle_rounded,
                                color: Theme.of(context).disabledColor,
                              ),
                        tooltip: AppLocalizations.of(context)!.shuffle,
                        onPressed: () async {
                          final enable = !shuffleModeEnabled;
                          await audioHandler.setShuffleMode(
                            enable
                                ? AudioServiceShuffleMode.all
                                : AudioServiceShuffleMode.none,
                          );
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
                        Icon(
                          Icons.repeat_rounded,
                          color: Theme.of(context).disabledColor,
                        ),
                        const Icon(
                          Icons.repeat_rounded,
                        ),
                        const Icon(
                          Icons.repeat_one_rounded,
                        ),
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
                            'repeatMode',
                            texts[(index + 1) % texts.length],
                          );
                          audioHandler.setRepeatMode(
                            cycleModes[(cycleModes.indexOf(repeatMode) + 1) %
                                cycleModes.length],
                          );
                        },
                      );
                    },
                  ),
                  if (!offline)
                    DownloadButton(
                      size: 25.0,
                      data: {
                        'id': mediaItem.id,
                        'artist': mediaItem.artist.toString(),
                        'album': mediaItem.album.toString(),
                        'image': mediaItem.artUri.toString(),
                        'duration': mediaItem.duration?.inSeconds.toString(),
                        'title': mediaItem.title,
                        'url': mediaItem.extras!['url'].toString(),
                        'year': mediaItem.extras!['year'].toString(),
                        'language': mediaItem.extras!['language'].toString(),
                        'genre': mediaItem.genre?.toString(),
                        '320kbps': mediaItem.extras?['320kbps'],
                        'has_lyrics': mediaItem.extras?['has_lyrics'],
                        'release_date': mediaItem.extras!['release_date'],
                        'album_id': mediaItem.extras!['album_id'],
                        'subtitle': mediaItem.extras!['subtitle'],
                        'perma_url': mediaItem.extras!['perma_url'],
                      },
                    )
                ],
              ),
            ],
          ),
        ),

        // Now playing
        GestureDetector(
          onVerticalDragEnd: (_) {
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
                    topRight: Radius.circular(15.0),
                  ),
                  child: NowPlayingStream(audioHandler),
                );
              },
            );
          },
          onTap: () {
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
                    topRight: Radius.circular(15.0),
                  ),
                  child: NowPlayingStream(audioHandler),
                );
              },
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 5.0),
              const Icon(
                Icons.expand_less_rounded,
              ),
              Text(
                AppLocalizations.of(context)!.nowPlaying,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5.0),
            ],
          ),
        ),
      ],
    );
  }
}
