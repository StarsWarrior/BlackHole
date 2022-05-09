/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2022, Ankit Sangwan
 */

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool rotated = MediaQuery.of(context).size.height < screenWidth;
    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data;
        final processingState = playbackState?.processingState;
        if (processingState == AudioProcessingState.idle) {
          return const SizedBox();
        }
        return StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.active) {
              return const SizedBox();
            }
            final mediaItem = snapshot.data;
            if (mediaItem == null) return const SizedBox();
            return Dismissible(
              key: const Key('miniplayer'),
              direction: DismissDirection.down,
              onDismissed: (_) {
                Feedback.forLongPress(context);
                audioHandler.stop();
              },
              child: Dismissible(
                key: Key(mediaItem.id),
                confirmDismiss: (DismissDirection direction) {
                  if (direction == DismissDirection.startToEnd) {
                    audioHandler.skipToPrevious();
                  } else {
                    audioHandler.skipToNext();
                  }
                  return Future.value(false);
                },
                child: ValueListenableBuilder(
                  valueListenable: Hive.box('settings').listenable(),
                  child: StreamBuilder<Duration>(
                    stream: AudioService.position,
                    builder: (context, snapshot) {
                      final position = snapshot.data;
                      return position == null
                          ? const SizedBox()
                          : (position.inSeconds.toDouble() < 0.0 ||
                                  (position.inSeconds.toDouble() >
                                      mediaItem.duration!.inSeconds.toDouble()))
                              ? const SizedBox()
                              : SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor:
                                        Theme.of(context).colorScheme.secondary,
                                    inactiveTrackColor: Colors.transparent,
                                    trackHeight: 0.5,
                                    thumbColor:
                                        Theme.of(context).colorScheme.secondary,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 1.0,
                                    ),
                                    overlayColor: Colors.transparent,
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 2.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Slider(
                                      inactiveColor: Colors.transparent,
                                      // activeColor: Colors.white,
                                      value: position.inSeconds.toDouble(),
                                      max: mediaItem.duration!.inSeconds
                                          .toDouble(),
                                      onChanged: (newPosition) {
                                        audioHandler.seek(
                                          Duration(
                                            seconds: newPosition.round(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                    },
                  ),
                  builder: (BuildContext context, Box box1, Widget? child) {
                    final bool useDense = box1.get(
                          'useDenseMini',
                          defaultValue: false,
                        ) as bool ||
                        rotated;
                    final List preferredMiniButtons = Hive.box('settings').get(
                      'preferredMiniButtons',
                      defaultValue: ['Previous', 'Play/Pause', 'Next'],
                    )?.toList() as List;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical: 1.0,
                      ),
                      child: SizedBox(
                        height: useDense ? 68.0 : 76.0,
                        child: GradientContainer(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                dense: useDense,
                                onTap: () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (_, __, ___) =>
                                          const PlayScreen(
                                        songsList: [],
                                        index: 1,
                                        offline: null,
                                        fromMiniplayer: true,
                                        fromDownloads: false,
                                        recommend: false,
                                      ),
                                    ),
                                  );
                                },
                                title: Text(
                                  mediaItem.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  mediaItem.artist ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                leading: Hero(
                                  tag: 'currentArtwork',
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7.0),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: (mediaItem.artUri
                                            .toString()
                                            .startsWith('file:'))
                                        ? SizedBox.square(
                                            dimension: useDense ? 40.0 : 50.0,
                                            child: Image(
                                              fit: BoxFit.cover,
                                              image: FileImage(
                                                File(
                                                  mediaItem.artUri!
                                                      .toFilePath(),
                                                ),
                                              ),
                                            ),
                                          )
                                        : SizedBox.square(
                                            dimension: useDense ? 40.0 : 50.0,
                                            child: CachedNetworkImage(
                                              fit: BoxFit.cover,
                                              errorWidget: (
                                                BuildContext context,
                                                _,
                                                __,
                                              ) =>
                                                  const Image(
                                                fit: BoxFit.cover,
                                                image: AssetImage(
                                                  'assets/cover.jpg',
                                                ),
                                              ),
                                              placeholder: (
                                                BuildContext context,
                                                _,
                                              ) =>
                                                  const Image(
                                                fit: BoxFit.cover,
                                                image: AssetImage(
                                                  'assets/cover.jpg',
                                                ),
                                              ),
                                              imageUrl:
                                                  mediaItem.artUri.toString(),
                                            ),
                                          ),
                                  ),
                                ),
                                trailing: ControlButtons(
                                  audioHandler,
                                  miniplayer: true,
                                  buttons: mediaItem.artUri
                                          .toString()
                                          .startsWith('file:')
                                      ? ['Previous', 'Play/Pause', 'Next']
                                      : preferredMiniButtons,
                                ),
                              ),
                              child!,
                            ],
                          ),
                        ),
                      ),
                    );
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
