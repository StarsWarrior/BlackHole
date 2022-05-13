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

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Services/download.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

class DownloadButton extends StatefulWidget {
  final Map data;
  final String? icon;
  final double? size;
  const DownloadButton({
    Key? key,
    required this.data,
    this.icon,
    this.size,
  }) : super(key: key);

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  Download down = Download();
  final Box downloadsBox = Hive.box('downloads');
  final ValueNotifier<bool> showStopButton = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    down.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 50,
      child: Center(
        child: (downloadsBox.containsKey(widget.data['id']))
            ? IconButton(
                icon: const Icon(Icons.download_done_rounded),
                tooltip: 'Download Done',
                color: Theme.of(context).colorScheme.secondary,
                iconSize: widget.size ?? 24.0,
                onPressed: () {
                  down.prepareDownload(context, widget.data);
                },
              )
            : down.progress == 0
                ? IconButton(
                    icon: Icon(
                      widget.icon == 'download'
                          ? Icons.download_rounded
                          : Icons.save_alt,
                    ),
                    iconSize: widget.size ?? 24.0,
                    color: Theme.of(context).iconTheme.color,
                    tooltip: 'Download',
                    onPressed: () {
                      down.prepareDownload(context, widget.data);
                    },
                  )
                : GestureDetector(
                    child: Stack(
                      children: [
                        Center(
                          child: CircularProgressIndicator(
                            value: down.progress == 1 ? null : down.progress,
                          ),
                        ),
                        Center(
                          child: ValueListenableBuilder(
                            valueListenable: showStopButton,
                            child: Center(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                ),
                                iconSize: 25.0,
                                color: Theme.of(context).iconTheme.color,
                                tooltip: AppLocalizations.of(
                                  context,
                                )!
                                    .stopDown,
                                onPressed: () {
                                  down.download = false;
                                },
                              ),
                            ),
                            builder: (
                              BuildContext context,
                              bool showValue,
                              Widget? child,
                            ) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: !showValue,
                                      child: Center(
                                        child: Text(
                                          down.progress == null
                                              ? '0%'
                                              : '${(100 * down.progress!).round()}%',
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: showValue,
                                      child: child!,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                    onTap: () {
                      showStopButton.value = true;
                      Future.delayed(const Duration(seconds: 2), () async {
                        showStopButton.value = false;
                      });
                    },
                  ),
      ),
    );
  }
}

class MultiDownloadButton extends StatefulWidget {
  final List data;
  final String playlistName;
  const MultiDownloadButton({
    Key? key,
    required this.data,
    required this.playlistName,
  }) : super(key: key);

  @override
  _MultiDownloadButtonState createState() => _MultiDownloadButtonState();
}

class _MultiDownloadButtonState extends State<MultiDownloadButton> {
  Download down = Download();
  int done = 0;

  @override
  void initState() {
    super.initState();
    down.addListener(() {
      setState(() {});
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox();
    }
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: (down.lastDownloadId == widget.data.last['id'])
            ? IconButton(
                icon: const Icon(
                  Icons.download_done_rounded,
                ),
                color: Theme.of(context).colorScheme.secondary,
                iconSize: 25.0,
                tooltip: AppLocalizations.of(context)!.downDone,
                onPressed: () {},
              )
            : down.progress == 0
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                      ),
                      iconSize: 25.0,
                      tooltip: AppLocalizations.of(context)!.down,
                      onPressed: () async {
                        for (final items in widget.data) {
                          down.prepareDownload(
                            context,
                            items as Map,
                            createFolder: true,
                            folderName: widget.playlistName,
                          );
                          await _waitUntilDone(items['id'].toString());
                          setState(() {
                            done++;
                          });
                        }
                      },
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%',
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            value: down.progress == 1 ? null : down.progress,
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: done / widget.data.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class AlbumDownloadButton extends StatefulWidget {
  final String albumId;
  final String albumName;
  const AlbumDownloadButton({
    Key? key,
    required this.albumId,
    required this.albumName,
  }) : super(key: key);

  @override
  _AlbumDownloadButtonState createState() => _AlbumDownloadButtonState();
}

class _AlbumDownloadButtonState extends State<AlbumDownloadButton> {
  Download down = Download();
  int done = 0;
  List data = [];
  bool finished = false;

  @override
  void initState() {
    super.initState();
    down.addListener(() {
      setState(() {});
    });
  }

  Future<void> _waitUntilDone(String id) async {
    while (down.lastDownloadId != id) {
      await Future.delayed(const Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: finished
            ? IconButton(
                icon: const Icon(
                  Icons.download_done_rounded,
                ),
                color: Theme.of(context).colorScheme.secondary,
                iconSize: 25.0,
                tooltip: AppLocalizations.of(context)!.downDone,
                onPressed: () {},
              )
            : down.progress == 0
                ? Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                      ),
                      iconSize: 25.0,
                      color: Theme.of(context).iconTheme.color,
                      tooltip: AppLocalizations.of(context)!.down,
                      onPressed: () async {
                        ShowSnackBar().showSnackBar(
                          context,
                          '${AppLocalizations.of(context)!.downingAlbum} "${widget.albumName}"',
                        );

                        data = (await SaavnAPI()
                            .fetchAlbumSongs(widget.albumId))['songs'] as List;
                        for (final items in data) {
                          down.prepareDownload(
                            context,
                            items as Map,
                            createFolder: true,
                            folderName: widget.albumName,
                          );
                          await _waitUntilDone(items['id'].toString());
                          setState(() {
                            done++;
                          });
                        }
                        finished = true;
                      },
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%',
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 35,
                          width: 35,
                          child: CircularProgressIndicator(
                            value: down.progress == 1 ? null : down.progress,
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: data.isEmpty ? 0 : done / data.length,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
