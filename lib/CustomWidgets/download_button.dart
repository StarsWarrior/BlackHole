import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:flutter/material.dart';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Services/download.dart';

class DownloadButton extends StatefulWidget {
  final Map data;
  final String? icon;
  const DownloadButton({Key? key, required this.data, this.icon})
      : super(key: key);

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  Download down = Download();

  @override
  void initState() {
    super.initState();
    down.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
          child: (down.lastDownloadId == widget.data['id'])
              ? IconButton(
                  icon: Icon(widget.icon == 'download'
                      ? Icons.download_done_rounded
                      : Icons.save_alt),
                  tooltip: 'Download Done',
                  color: Theme.of(context).accentColor,
                  iconSize: 25.0,
                  onPressed: () {},
                )
              : down.progress == 0
                  ? Center(
                      child: IconButton(
                          icon: Icon(widget.icon == 'download'
                              ? Icons.download_rounded
                              : Icons.save_alt),
                          iconSize: 25.0,
                          tooltip: 'Download',
                          onPressed: () {
                            down.prepareDownload(context, widget.data);
                          }))
                  : Stack(
                      children: [
                        Center(
                          child: Text(down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%'),
                        ),
                        Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).accentColor),
                            value: down.progress == 1 ? null : down.progress,
                          ),
                        ),
                      ],
                    )),
    );
  }
}

class MultiDownloadButton extends StatefulWidget {
  final List data;
  final String playlistName;
  const MultiDownloadButton(
      {Key? key, required this.data, required this.playlistName})
      : super(key: key);

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
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
          child: (down.lastDownloadId == widget.data.last['id'])
              ? IconButton(
                  icon: const Icon(
                    Icons.download_done_rounded,
                  ),
                  color: Theme.of(context).accentColor,
                  iconSize: 25.0,
                  tooltip: 'Download Done',
                  onPressed: () {},
                )
              : down.progress == 0
                  ? Center(
                      child: IconButton(
                          icon: const Icon(
                            Icons.save_alt_rounded,
                          ),
                          iconSize: 25.0,
                          tooltip: 'Download',
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
                          }))
                  : Stack(
                      children: [
                        Center(
                          child: Text(down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%'),
                        ),
                        Center(
                          child: SizedBox(
                            height: 35,
                            width: 35,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).accentColor),
                              value: down.progress == 1 ? null : down.progress,
                            ),
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).accentColor),
                              value: done / widget.data.length,
                            ),
                          ),
                        ),
                      ],
                    )),
    );
  }
}

class AlbumDownloadButton extends StatefulWidget {
  final String albumId;
  final String albumName;
  const AlbumDownloadButton(
      {Key? key, required this.albumId, required this.albumName})
      : super(key: key);

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
                  color: Theme.of(context).accentColor,
                  iconSize: 25.0,
                  tooltip: 'Download Done',
                  onPressed: () {},
                )
              : down.progress == 0
                  ? Center(
                      child: IconButton(
                          icon: const Icon(
                            Icons.download_rounded,
                          ),
                          iconSize: 25.0,
                          tooltip: 'Download',
                          onPressed: () async {
                            ShowSnackBar().showSnackBar(
                              context,
                              'Downloading Album "${widget.albumName}"',
                            );

                            data = await SaavnAPI()
                                .fetchAlbumSongs(widget.albumId);
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
                          }))
                  : Stack(
                      children: [
                        Center(
                          child: Text(down.progress == null
                              ? '0%'
                              : '${(100 * down.progress!).round()}%'),
                        ),
                        Center(
                          child: SizedBox(
                            height: 35,
                            width: 35,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).accentColor),
                              value: down.progress == 1 ? null : down.progress,
                            ),
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            height: 30,
                            width: 30,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).accentColor),
                              value: data.isEmpty ? 0 : done / data.length,
                            ),
                          ),
                        ),
                      ],
                    )),
    );
  }
}
