import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Services/download.dart';
import 'package:flutter/material.dart';

class DownloadButton extends StatefulWidget {
  final Map data;
  final String icon;
  DownloadButton({Key key, @required this.data, this.icon}) : super(key: key);

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
                          onPressed: () {
                            down.prepareDownload(context, widget.data);
                          }))
                  : Stack(
                      children: [
                        Center(
                          child: Text(down.progress == null
                              ? '0%'
                              : '${(100 * down.progress).round()}%'),
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
  MultiDownloadButton({Key key, @required this.data}) : super(key: key);

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
      await Future.delayed(Duration(seconds: 1));
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
                  icon: Icon(
                    Icons.download_done_rounded,
                  ),
                  color: Theme.of(context).accentColor,
                  iconSize: 25.0,
                  onPressed: () {},
                )
              : down.progress == 0
                  ? Center(
                      child: IconButton(
                          icon: Icon(
                            Icons.save_alt_rounded,
                          ),
                          iconSize: 25.0,
                          onPressed: () async {
                            for (Map items in widget.data) {
                              down.prepareDownload(context, items);
                              await _waitUntilDone(items['id']);
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
                              : '${(100 * down.progress).round()}%'),
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
  AlbumDownloadButton(
      {Key key, @required this.albumId, @required this.albumName})
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
      await Future.delayed(Duration(seconds: 1));
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
          child: (finished)
              ? IconButton(
                  icon: Icon(
                    Icons.download_done_rounded,
                  ),
                  color: Theme.of(context).accentColor,
                  iconSize: 25.0,
                  onPressed: () {},
                )
              : down.progress == 0
                  ? Center(
                      child: IconButton(
                          icon: Icon(
                            Icons.download_rounded,
                          ),
                          iconSize: 25.0,
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                elevation: 6,
                                backgroundColor: Colors.grey[900],
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'Downloading Album "${widget.albumName}"',
                                  style: TextStyle(color: Colors.white),
                                ),
                                action: SnackBarAction(
                                    textColor: Theme.of(context).accentColor,
                                    label: 'Ok',
                                    onPressed: () {})));
                            data =
                                await Search().fetchAlbumSongs(widget.albumId);
                            for (Map items in data) {
                              down.prepareDownload(context, items);
                              await _waitUntilDone(items['id']);
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
                              : '${(100 * down.progress).round()}%'),
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
