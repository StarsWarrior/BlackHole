import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'dart:math';
import 'dart:convert';
import 'package:des_plugin/des_plugin.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';
import 'package:audiotagger/audiotagger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart' show rootBundle;

class PlayScreen extends StatefulWidget {
  final Map data;
  final controller;
  final bool fromMiniplayer;
  PlayScreen(
      {Key key,
      @required this.data,
      @required this.fromMiniplayer,
      this.controller})
      : super(key: key);
  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  bool fromMiniplayer = false;
  int _total = 0;
  int _recieved = 0;
  String downloadedId = '';
  String preferredQuality =
      Hive.box('settings').get('streamingQuality') ?? '96 kbps';
  String preferredDownloadQuality =
      Hive.box('settings').get('downloadQuality') ?? '320 kbps';
  String repeatMode = Hive.box('settings').get('repeatMode') ?? 'None';
  bool shuffle = Hive.box('settings').get('shuffle') ?? false;
  List<MediaItem> globalQueue = [];
  int globalIndex = 0;
  bool same = false;
  List response = [];
  bool fetched = false;
  Box likedBox;
  bool liked = false;
  bool offline = false;
  MediaItem playItem;
  // sleepTimer(0) cancels the timer
  void sleepTimer(int time) {
    AudioService.customAction('sleepTimer', time);
  }

  Duration _time;

  void main() async {
    await Hive.openBox('favorites');
  }

  @override
  void initState() {
    super.initState();
    main();
  }

  void checkLiked(key) async {
    likedBox = Hive.box('favorites');
    liked = likedBox.containsKey(key);
  }

  // Future<bool> checkPlaylist(name, key) async {
  //   await Hive.openBox(name);
  //   final playlistBox = Hive.box(name);
  //   return playlistBox.containsKey(key);
  // }

  void addPlaylist(name, id, info) async {
    await Hive.openBox(name);
    final playlistBox = Hive.box(name);
    playlistBox.put(id, info);
  }

  void removeLiked(key) async {
    likedBox = Hive.box('favorites');
    likedBox.delete(key);
    setState(() {});
  }

  void addLiked(id, info) async {
    likedBox = Hive.box('favorites');
    likedBox.put(id, info);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    BuildContext scaffoldContext;
    // Map data = ModalRoute.of(context).settings.arguments;
    Map data = widget.data;
    if (response == data['response'] && globalIndex == data['index']) {
      same = true;
    }
    response = data['response'];
    globalIndex = data['index'];
    offline = data['offline'];
    if (offline == null) {
      offline = AudioService.currentMediaItem.extras['URL'].startsWith('http')
          ? false
          : true;
    }

    setFavValues(response) {
      for (int i = 0; i < response.length; i++) {
        var tempDict = MediaItem(
          id: response[i]['id'],
          album: response[i]['album'],
          duration: Duration(seconds: int.parse(response[i]['duration'])),
          title: response[i]['title'].split("(")[0],
          artist: response[i]["artist"],
          artUri: Uri.parse(response[i]['image'].replaceAll('http:', 'https:')),
        );
        globalQueue.add(tempDict);
      }
      // fetched = true;
    }

    setTags(response, tempDir) async {
      var playTitle = response['title'];
      playTitle == ''
          ? playTitle = response['id']
              .split('/')
              .last
              .replaceAll('.m4a', '')
              .replaceAll('.mp3', '')
          : playTitle = response['title'];
      var playArtist = response['artist'];
      playArtist == ''
          ? playArtist = response['id']
              .split('/')
              .last
              .replaceAll('.m4a', '')
              .replaceAll('.mp3', '')
          : playArtist = response['artist'];

      var playAlbum = response['album'];
      final playDuration = '180';
      var file =
          await File('${tempDir.path}/$playTitle-$playArtist.jpg').create();
      if (response['image'] != null) {
        file.writeAsBytesSync(response['image']);
      } else {
        file = null;
      }

      var tempDict = MediaItem(
          id: response['id'],
          album: playAlbum,
          duration: Duration(seconds: int.parse(playDuration)),
          title: playTitle != null ? playTitle.split("(")[0] : 'Unknown',
          artist: playArtist ?? 'Unknown',
          artUri: file == null
              ? Uri.parse(
                  'file:${(await getTemporaryDirectory()).path}/cover.jpg')
              : Uri.parse('file:${file.path}'),
          extras: {'URL': response['id']});
      globalQueue.add(tempDict);
      setState(() {});
    }

    setOffValues(response) {
      getTemporaryDirectory().then((tempDir) async {
        final byteData = await rootBundle.load('assets/cover.jpg');
        final file = File('${(await getTemporaryDirectory()).path}/cover.jpg');
        await file.writeAsBytes(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        for (int i = 0; i < response.length; i++) {
          // print(response[i]['id']);
          await setTags(response[i], tempDir);
        }
        // print('global queue is $globalQueue');
      });
    }

    setValues(response) {
      for (int i = 0; i < response.length; i++) {
        var tempDict = MediaItem(
            id: response[i]['id'],
            album: response[i]['more_info']['album']
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
                .split('(')
                .first,
            duration: Duration(
                seconds:
                    int.parse(response[i]['more_info']['duration'] ?? '180')),
            title: response[i]['title']
                .toString()
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\"")
                .split('(')
                .first,
            artist: response[i]["more_info"]["artistMap"] == null
                ? response[i]['more_info']['primary_artists']
                : response[i]["more_info"]["artistMap"]["primary_artists"][0]
                        ["name"]
                    .toString()
                    .replaceAll("&amp;", "&")
                    .replaceAll("&#039;", "'")
                    .replaceAll("&quot;", "\""),
            artUri: Uri.parse(response[i]['image']
                .toString()
                .replaceAll("150x150", "500x500")
                .replaceAll('http:', 'https:')));
        globalQueue.add(tempDict);
      }
      // fetched = true;
    }

    if (!fetched) {
      if (response.length == 0 || same) {
        fromMiniplayer = true;
      } else {
        fromMiniplayer = false;
        repeatMode = 'None';
        shuffle = false;
        Hive.box('settings').put('repeatMode', repeatMode);
        Hive.box('settings').put('shuffle', shuffle);
        AudioService.stop();
        if (offline) {
          setOffValues(response);
        } else {
          try {
            setValues(response);
          } catch (e) {
            setFavValues(response);
          }
        }
      }
    }
    var container = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.grey[850],
                  Colors.grey[900],
                  Colors.black,
                ]
              : [
                  Colors.white,
                  Theme.of(context).canvasColor,
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // appBar: AppBar(
        //   title: Text('Now Playing'),
        //   centerTitle: true,
        // ),
        body: Builder(builder: (BuildContext context) {
          scaffoldContext = context;
          return SafeArea(
            child: SingleChildScrollView(
              child: StreamBuilder<bool>(
                  stream: AudioService.runningStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.active) {
                      return SizedBox();
                    }
                    final running = snapshot.data ?? false;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!running) ...[
                          FutureBuilder(
                              future: audioPlayerButton(),
                              builder: (context, AsyncSnapshot spshot) {
                                if (spshot.hasData) {
                                  return SizedBox();
                                } else {
                                  return Column(
                                    children: [
                                      Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.0725,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                                icon: Icon(
                                                    Icons.expand_more_rounded),
                                                onPressed: () {
                                                  if (widget.fromMiniplayer) {
                                                    widget.controller
                                                        .animateToHeight(
                                                            state:
                                                                PanelState.MIN);
                                                  } else {
                                                    Navigator.pop(context);
                                                  }
                                                }),
                                            PopupMenuButton(
                                                icon: Icon(
                                                    Icons.more_vert_rounded),
                                                itemBuilder: (context) => []),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.925,
                                        child: Card(
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          clipBehavior: Clip.antiAlias,
                                          child: Stack(
                                            children: [
                                              Image(
                                                  fit: BoxFit.cover,
                                                  image: AssetImage(
                                                      'assets/cover.jpg')),
                                              globalQueue.length <= globalIndex
                                                  ? Image(
                                                      fit: BoxFit.cover,
                                                      image: AssetImage(
                                                          'assets/cover.jpg'))
                                                  : offline
                                                      ? Image(
                                                          fit: BoxFit.cover,
                                                          image: FileImage(File(
                                                            globalQueue[
                                                                    globalIndex]
                                                                .artUri
                                                                .toFilePath()
                                                                .replaceAll(
                                                                    'file:',
                                                                    ''),
                                                          )))
                                                      : Image(
                                                          fit: BoxFit.cover,
                                                          image: NetworkImage(
                                                            globalQueue[
                                                                    globalIndex]
                                                                .artUri
                                                                .toString(),
                                                          ),
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.925,
                                                        ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: (MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.9 -
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.925) /
                                            3,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 25, 15, 0),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                height: (MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.9 -
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.925) *
                                                    2 /
                                                    14.0,
                                                child: FittedBox(
                                                    child: Text(
                                                  globalQueue.length <=
                                                          globalIndex
                                                      ? 'Unknown'
                                                      : globalQueue[globalIndex]
                                                          .title,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 50,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Theme.of(context)
                                                          .accentColor),
                                                )),
                                              ),
                                              Container(
                                                height: (MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.95 -
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.925) *
                                                    1 /
                                                    16.0,
                                                child: Text(
                                                  globalQueue.length <=
                                                          globalIndex
                                                      ? 'Unknown'
                                                      : globalQueue[globalIndex]
                                                          .artist,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                          height: (MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.9 -
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.925) /
                                              3.5,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              SeekBar(
                                                duration: Duration.zero,
                                                position: Duration.zero,
                                              ),
                                            ],
                                          )),
                                      Container(
                                        height: (MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.9 -
                                                MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.925) /
                                            3,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            offline
                                                ? IconButton(
                                                    icon: Icon(
                                                      Icons.shuffle_rounded,
                                                    ),
                                                    onPressed: null,
                                                  )
                                                : IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .favorite_border_rounded,
                                                    ),
                                                    onPressed: null,
                                                  ),
                                            IconButton(
                                              icon: Icon(
                                                  Icons.skip_previous_rounded),
                                              iconSize: 45.0,
                                              onPressed: null,
                                            ),
                                            Stack(
                                              children: [
                                                Center(
                                                    child: SizedBox(
                                                  height: 65,
                                                  width: 65,
                                                  child:
                                                      CircularProgressIndicator(),
                                                )),
                                                Center(
                                                  child: Container(
                                                    height: 65,
                                                    width: 65,
                                                    child: Center(
                                                      child: SizedBox(
                                                        height: 59,
                                                        width: 59,
                                                        child: playButton(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            IconButton(
                                              icon:
                                                  Icon(Icons.skip_next_rounded),
                                              iconSize: 45.0,
                                              onPressed: null,
                                            ),
                                            offline
                                                ? IconButton(
                                                    icon: Icon(
                                                        Icons.repeat_rounded),
                                                    onPressed: null,
                                                  )
                                                : IconButton(
                                                    icon: Icon(
                                                      Icons.save_alt,
                                                    ),
                                                    onPressed: null),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              }),
                        ] else ...[
                          Container(
                            height: MediaQuery.of(context).size.height * 0.0725,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                    icon: Icon(Icons.expand_more_rounded),
                                    onPressed: () {
                                      if (widget.fromMiniplayer) {
                                        widget.controller.animateToHeight(
                                            state: PanelState.MIN);
                                      } else {
                                        Navigator.pop(context);
                                      }
                                    }),
                                PopupMenuButton(
                                  icon: Icon(Icons.more_vert_rounded),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0))),
                                  onSelected: (value) {
                                    if (value == 1) {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return SimpleDialog(
                                            title: Center(
                                                child: Text(
                                              'Select a Duration',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .accentColor),
                                            )),
                                            children: [
                                              Center(
                                                  child: SizedBox(
                                                height: 200,
                                                width: 200,
                                                child: CupertinoTheme(
                                                  data: CupertinoThemeData(
                                                    primaryColor:
                                                        Theme.of(context)
                                                            .accentColor,
                                                    textTheme:
                                                        CupertinoTextThemeData(
                                                      dateTimePickerTextStyle:
                                                          TextStyle(
                                                        fontSize: 16,
                                                        color: Theme.of(context)
                                                            .accentColor,
                                                      ),
                                                    ),
                                                  ),
                                                  child: CupertinoTimerPicker(
                                                    mode:
                                                        CupertinoTimerPickerMode
                                                            .hm,
                                                    onTimerDurationChanged:
                                                        (value) {
                                                      setState(() {
                                                        _time = value;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              )),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                      primary: Theme.of(context)
                                                          .accentColor,
                                                    ),
                                                    child: Text('Cancel'),
                                                    onPressed: () {
                                                      sleepTimer(0);
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                      primary: Colors.white,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .accentColor,
                                                    ),
                                                    child: Text('Ok'),
                                                    onPressed: () {
                                                      sleepTimer(
                                                          _time.inMinutes);
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(
                                                              scaffoldContext)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          duration: Duration(
                                                              seconds: 2),
                                                          elevation: 6,
                                                          backgroundColor:
                                                              Colors.grey[900],
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          content: Text(
                                                            'Sleep timer set for ${_time.inMinutes} minutes',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                          action:
                                                              SnackBarAction(
                                                            textColor: Theme.of(
                                                                    context)
                                                                .accentColor,
                                                            label: 'Ok',
                                                            onPressed: () {},
                                                          ),
                                                        ),
                                                      );
                                                      debugPrint(
                                                          'Sleep after ${_time.inMinutes}');
                                                    },
                                                  ),
                                                  SizedBox(
                                                    width: 20,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                    if (value == 0) {
                                      showModalBottomSheet(
                                          isDismissible: true,
                                          backgroundColor: Colors.transparent,
                                          context: context,
                                          builder: (BuildContext context) {
                                            final settingsBox =
                                                Hive.box('settings');
                                            var playlistNames =
                                                settingsBox.get('playlists');
                                            // print(
                                            //     'AT START: $playlistNames');

                                            return Container(
                                              margin: EdgeInsets.fromLTRB(
                                                  25, 0, 25, 25),
                                              padding: EdgeInsets.fromLTRB(
                                                  10, 15, 10, 15),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(15.0)),
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? [
                                                          Colors.grey[850],
                                                          Colors.grey[900],
                                                          Colors.black,
                                                        ]
                                                      : [
                                                          Colors.white,
                                                          Theme.of(context)
                                                              .canvasColor,
                                                        ],
                                                ),
                                              ),
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ListTile(
                                                      title: Text(
                                                          'Create Playlist'),
                                                      leading: Icon(
                                                          Icons.add_rounded),
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            final controller =
                                                                TextEditingController();
                                                            return AlertDialog(
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Text(
                                                                        'Create new playlist',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Theme.of(context).accentColor),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  TextField(
                                                                      cursorColor:
                                                                          Theme.of(context)
                                                                              .accentColor,
                                                                      controller:
                                                                          controller,
                                                                      autofocus:
                                                                          true,
                                                                      onSubmitted:
                                                                          (value) {
                                                                        playlistNames ==
                                                                                null
                                                                            ? playlistNames =
                                                                                [
                                                                                value
                                                                              ]
                                                                            : playlistNames.add(value);
                                                                        settingsBox.put(
                                                                            'playlists',
                                                                            playlistNames);
                                                                        Navigator.pop(
                                                                            context);
                                                                      }),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  style: TextButton
                                                                      .styleFrom(
                                                                    primary: Theme.of(context).brightness ==
                                                                            Brightness
                                                                                .dark
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .grey[700],
                                                                    //       backgroundColor: Theme.of(context).accentColor,
                                                                  ),
                                                                  child: Text(
                                                                      "Cancel"),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                ),
                                                                TextButton(
                                                                  style: TextButton
                                                                      .styleFrom(
                                                                    primary: Colors
                                                                        .white,
                                                                    backgroundColor:
                                                                        Theme.of(context)
                                                                            .accentColor,
                                                                  ),
                                                                  child: Text(
                                                                    "Ok",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    playlistNames ==
                                                                            null
                                                                        ? playlistNames =
                                                                            [
                                                                            controller.text
                                                                          ]
                                                                        : playlistNames
                                                                            .add(controller.text);

                                                                    // print(
                                                                    //     'Putting as $playlistNames');
                                                                    settingsBox.put(
                                                                        'playlists',
                                                                        playlistNames);
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                ),
                                                                SizedBox(
                                                                  width: 5,
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    ),
                                                    playlistNames == null
                                                        ? SizedBox()
                                                        : StreamBuilder<
                                                                QueueState>(
                                                            stream:
                                                                _queueStateStream,
                                                            builder: (context,
                                                                snapshot) {
                                                              final queueState =
                                                                  snapshot.data;
                                                              final mediaItem =
                                                                  queueState
                                                                      ?.mediaItem;
                                                              return ListView
                                                                  .builder(
                                                                      physics:
                                                                          NeverScrollableScrollPhysics(),
                                                                      shrinkWrap:
                                                                          true,
                                                                      itemCount:
                                                                          playlistNames
                                                                              .length,
                                                                      itemBuilder:
                                                                          (context,
                                                                              index) {
                                                                        // print(
                                                                        //     'PLAYLIST IS $playlistNames');
                                                                        return ListTile(
                                                                          leading:
                                                                              Icon(Icons.music_note_rounded),
                                                                          title:
                                                                              Text('${playlistNames[index]}'),
                                                                          onTap:
                                                                              () {
                                                                            Navigator.pop(context);
                                                                            // checkPlaylist(playlistNames[index], mediaItem.id.toString())
                                                                            // ? print('Already There'):
                                                                            addPlaylist(playlistNames[index],
                                                                                mediaItem.id, {
                                                                              'id': mediaItem.id.toString(),
                                                                              'artist': mediaItem.artist.toString(),
                                                                              'album': mediaItem.album.toString(),
                                                                              'image': mediaItem.artUri.toString(),
                                                                              'duration': mediaItem.duration.inSeconds.toString(),
                                                                              'title': mediaItem.title.toString()
                                                                            });
                                                                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                                                              SnackBar(
                                                                                duration: Duration(seconds: 2),
                                                                                elevation: 6,
                                                                                backgroundColor: Colors.grey[900],
                                                                                behavior: SnackBarBehavior.floating,
                                                                                content: Text(
                                                                                  'Added to ${playlistNames[index]}',
                                                                                  style: TextStyle(color: Colors.white),
                                                                                ),
                                                                                action: SnackBarAction(
                                                                                  textColor: Theme.of(context).accentColor,
                                                                                  label: 'Ok',
                                                                                  onPressed: () {},
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        );
                                                                      });
                                                            }),
                                                  ],
                                                ),
                                              ),
                                            );
                                          });
                                    }
                                  },
                                  itemBuilder: (context) => offline
                                      ? [
                                          PopupMenuItem(
                                              value: 1,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.timer),
                                                  Spacer(),
                                                  Text('Sleep Timer'),
                                                  Spacer(),
                                                ],
                                              )),
                                        ]
                                      : [
                                          PopupMenuItem(
                                              value: 0,
                                              child: Row(
                                                children: [
                                                  Icon(Icons
                                                      .playlist_add_rounded),
                                                  Spacer(),
                                                  Text('Add to playlist'),
                                                  Spacer(),
                                                ],
                                              )),
                                          PopupMenuItem(
                                              value: 1,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.timer),
                                                  Spacer(),
                                                  Text('Sleep Timer'),
                                                  Spacer(),
                                                ],
                                              )),
                                        ],
                                )
                              ],
                            ),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.width * 0.925,
                            child: Hero(
                              tag: 'image',
                              child: GestureDetector(
                                onTap: () {
                                  if (AudioService.playbackState.playing ==
                                      true) {
                                    AudioService.pause();
                                  } else {
                                    AudioService.play();
                                  }
                                },
                                child: Card(
                                  elevation: 10,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      Image(
                                        fit: BoxFit.cover,
                                        image: AssetImage('assets/cover.jpg'),
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.925,
                                      ),
                                      StreamBuilder<QueueState>(
                                          stream: _queueStateStream,
                                          builder: (context, snapshot) {
                                            final queueState = snapshot.data;
                                            // final queue = queueState?.queue ?? [];
                                            final mediaItem =
                                                queueState?.mediaItem;
                                            return (mediaItem == null)
                                                ? Image(
                                                    fit: BoxFit.cover,
                                                    image: (globalQueue ==
                                                                null ||
                                                            globalQueue
                                                                    .length ==
                                                                0)
                                                        ? (AssetImage(
                                                            'assets/cover.jpg'))
                                                        : offline
                                                            ? FileImage(File(
                                                                globalQueue[
                                                                        globalIndex]
                                                                    .artUri
                                                                    .toFilePath()
                                                                    .replaceAll(
                                                                        'file:',
                                                                        ''),
                                                              ))
                                                            : NetworkImage(
                                                                globalQueue[
                                                                        globalIndex]
                                                                    .artUri
                                                                    .toString()),
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.925,
                                                  )
                                                : Image(
                                                    fit: BoxFit.cover,
                                                    image: offline
                                                        ? FileImage(File(
                                                            mediaItem.artUri
                                                                .toFilePath()
                                                                .replaceAll(
                                                                    'file:',
                                                                    ''),
                                                          ))
                                                        : NetworkImage(mediaItem
                                                            .artUri
                                                            .toString()),
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.925,
                                                  );
                                          }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          //Title and subtitle

                          Container(
                            height: (MediaQuery.of(context).size.height * 0.9 -
                                    MediaQuery.of(context).size.width * 0.925) /
                                3,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(15, 25, 15, 0),
                              child: StreamBuilder<QueueState>(
                                  stream: _queueStateStream,
                                  builder: (context, snapshot) {
                                    final queueState = snapshot.data;
                                    final mediaItem = queueState?.mediaItem;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Title container
                                        Container(
                                          height: (MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.9 -
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.925) *
                                              2 /
                                              14.0,
                                          child: FittedBox(
                                              child: Text(
                                            (mediaItem?.title != null)
                                                ? (mediaItem.title)
                                                : ((globalQueue == null ||
                                                        globalQueue.length == 0)
                                                    ? 'Title'
                                                    : globalQueue[globalIndex]
                                                        .title),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 50,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .accentColor),
                                          )),
                                        ),

                                        //Subtitle container
                                        Container(
                                          height: (MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.95 -
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.925) *
                                              1 /
                                              16.0,
                                          child: Text(
                                            (mediaItem?.artist != null)
                                                ? (mediaItem.artist)
                                                : ((globalQueue == null ||
                                                        globalQueue.length == 0)
                                                    ? ''
                                                    : globalQueue[globalIndex]
                                                        .artist),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                            ),
                          ),
                          //Seekbar starts from here
                          Container(
                            height: (MediaQuery.of(context).size.height * 0.9 -
                                    MediaQuery.of(context).size.width * 0.925) /
                                3.5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                StreamBuilder<MediaState>(
                                  stream: _mediaStateStream,
                                  builder: (context, snapshot) {
                                    final mediaState = snapshot.data;

                                    return SeekBar(
                                      duration:
                                          mediaState?.mediaItem?.duration ??
                                              Duration.zero,
                                      position:
                                          mediaState?.position ?? Duration.zero,
                                      onChangeEnd: (newPosition) {
                                        AudioService.seekTo(newPosition);
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Final low starts from here

                          Container(
                            height: (MediaQuery.of(context).size.height * 0.9 -
                                    MediaQuery.of(context).size.width * 0.925) /
                                3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                offline
                                    ? IconButton(
                                        icon: Icon(Icons.shuffle_rounded),
                                        color: shuffle
                                            ? Theme.of(context).accentColor
                                            : null,
                                        onPressed: () {
                                          shuffle = !shuffle;
                                          Hive.box('settings')
                                              .put('shuffle', shuffle);
                                          AudioService.customAction(
                                              'shuffle', shuffle);
                                          setState(() {});
                                        },
                                      )
                                    : StreamBuilder<QueueState>(
                                        stream: _queueStateStream,
                                        builder: (context, snapshot) {
                                          final queueState = snapshot.data;
                                          // final queue = queueState?.queue ?? [];
                                          final mediaItem =
                                              queueState?.mediaItem;
                                          try {
                                            checkLiked(mediaItem.id);
                                          } catch (e) {}

                                          return mediaItem == null
                                              ? IconButton(
                                                  icon: Icon(Icons
                                                      .favorite_border_rounded),
                                                  onPressed: null)
                                              : IconButton(
                                                  icon: Icon(
                                                    liked
                                                        ? Icons.favorite_rounded
                                                        : Icons
                                                            .favorite_border_rounded,
                                                    color: liked
                                                        ? Colors.redAccent
                                                        : null,
                                                  ),
                                                  onPressed: () {
                                                    liked
                                                        ? removeLiked(
                                                            mediaItem.id)
                                                        : addLiked(
                                                            mediaItem.id, {
                                                            'id': mediaItem.id
                                                                .toString(),
                                                            'artist': mediaItem
                                                                .artist
                                                                .toString(),
                                                            'album': mediaItem
                                                                .album
                                                                .toString(),
                                                            'image': mediaItem
                                                                .artUri
                                                                .toString(),
                                                            'duration':
                                                                mediaItem
                                                                    .duration
                                                                    .inSeconds
                                                                    .toString(),
                                                            'title': mediaItem
                                                                .title
                                                                .toString()
                                                          });
                                                    liked = !liked;
                                                    ScaffoldMessenger.of(
                                                            scaffoldContext)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        duration: Duration(
                                                            seconds: 2),
                                                        action: SnackBarAction(
                                                            textColor: Theme.of(
                                                                    context)
                                                                .accentColor,
                                                            label: 'Undo',
                                                            onPressed: () {
                                                              liked
                                                                  ? removeLiked(
                                                                      mediaItem
                                                                          .id)
                                                                  : addLiked(
                                                                      mediaItem
                                                                          .id,
                                                                      {
                                                                          'id': mediaItem
                                                                              .id
                                                                              .toString(),
                                                                          'artist': mediaItem
                                                                              .artist
                                                                              .toString(),
                                                                          'album': mediaItem
                                                                              .album
                                                                              .toString(),
                                                                          'image': mediaItem
                                                                              .artUri
                                                                              .toString(),
                                                                          'duration': mediaItem
                                                                              .duration
                                                                              .inSeconds
                                                                              .toString(),
                                                                          'title': mediaItem
                                                                              .title
                                                                              .toString()
                                                                        });
                                                              liked = !liked;
                                                            }),
                                                        elevation: 6,
                                                        backgroundColor:
                                                            Colors.grey[900],
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        content: Text(
                                                          liked
                                                              ? 'Added to Favorites'
                                                              : 'Removed from Favorites',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      ),
                                                    );
                                                  });
                                        },
                                      ),
                                StreamBuilder<QueueState>(
                                    stream: _queueStateStream,
                                    builder: (context, snapshot) {
                                      final queueState = snapshot.data;
                                      final queue = queueState?.queue ?? [];
                                      final mediaItem = queueState?.mediaItem;
                                      return (queue != null && queue.isNotEmpty)
                                          ? IconButton(
                                              icon: Icon(
                                                  Icons.skip_previous_rounded),
                                              iconSize: 45.0,
                                              onPressed: (mediaItem ==
                                                          queue.first ||
                                                      mediaItem == null)
                                                  ? null
                                                  : AudioService.skipToPrevious,
                                            )
                                          : IconButton(
                                              icon: Icon(
                                                  Icons.skip_previous_rounded),
                                              iconSize: 45.0,
                                              onPressed: null);
                                    }),
                                Stack(
                                  children: [
                                    Center(
                                      child:
                                          StreamBuilder<AudioProcessingState>(
                                        stream: AudioService.playbackStateStream
                                            .map((state) =>
                                                state.processingState)
                                            .distinct(),
                                        builder: (context, snapshot) {
                                          final processingState =
                                              snapshot.data ??
                                                  AudioProcessingState.none;
                                          return describeEnum(
                                                      processingState) !=
                                                  'ready'
                                              ? SizedBox(
                                                  height: 65,
                                                  width: 65,
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                              : SizedBox();
                                        },
                                      ),
                                    ),
                                    Center(
                                      child: StreamBuilder<bool>(
                                        stream: AudioService.playbackStateStream
                                            .map((state) => state.playing)
                                            .distinct(),
                                        builder: (context, snapshot) {
                                          final playing =
                                              snapshot.data ?? false;
                                          return Container(
                                            height: 65,
                                            width: 65,
                                            child: Center(
                                              child: SizedBox(
                                                height: 59,
                                                width: 59,
                                                child: playing
                                                    ? pauseButton()
                                                    : playButton(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                // Queue display/controls.
                                StreamBuilder<QueueState>(
                                  stream: _queueStateStream,
                                  builder: (context, snapshot) {
                                    final queueState = snapshot.data;
                                    final queue = queueState?.queue ?? [];
                                    final mediaItem = queueState?.mediaItem;
                                    return (queue != null && queue.isNotEmpty)
                                        ? IconButton(
                                            icon: Icon(Icons.skip_next_rounded),
                                            iconSize: 45.0,
                                            onPressed:
                                                (mediaItem == queue.last ||
                                                        mediaItem == null)
                                                    ? null
                                                    : AudioService.skipToNext,
                                          )
                                        : IconButton(
                                            icon: Icon(Icons.skip_next_rounded),
                                            iconSize: 45.0,
                                            onPressed: null);
                                  },
                                ),
                                offline
                                    ? IconButton(
                                        icon: repeatMode == 'One'
                                            ? Icon(Icons.repeat_one_rounded)
                                            : Icon(Icons.repeat_rounded),
                                        color: repeatMode == 'None'
                                            ? null
                                            : Theme.of(context).accentColor,
                                        // Icons.repeat_one_rounded
                                        onPressed: () {
                                          repeatMode == 'None'
                                              ? repeatMode = 'All'
                                              : (repeatMode == 'All'
                                                  ? repeatMode = 'One'
                                                  : repeatMode = 'None');
                                          Hive.box('settings')
                                              .put('repeatMode', repeatMode);
                                          AudioService.customAction(
                                              'repeatMode', repeatMode);
                                          setState(() {});
                                        },
                                      )
                                    : StreamBuilder<QueueState>(
                                        stream: _queueStateStream,
                                        builder: (context, snapshot) {
                                          final queueState = snapshot.data;
                                          final queue = queueState?.queue ?? [];
                                          final mediaItem =
                                              queueState?.mediaItem;
                                          return (mediaItem != null &&
                                                  queue.isNotEmpty)
                                              ? Stack(
                                                  children: [
                                                    Center(
                                                      child: SizedBox(
                                                        width: 50,
                                                        child: (downloadedId ==
                                                                mediaItem.id)
                                                            ? Icon(
                                                                Icons.save_alt,
                                                                color: Theme.of(
                                                                        context)
                                                                    .accentColor,
                                                              )
                                                            : SizedBox(),
                                                      ),
                                                    ),
                                                    Center(
                                                        child:
                                                            (downloadedId ==
                                                                    mediaItem
                                                                        .id)
                                                                ? SizedBox()
                                                                : SizedBox(
                                                                    height: 50,
                                                                    width: 50,
                                                                    child:
                                                                        Stack(
                                                                      children: [
                                                                        Center(
                                                                          child: Text(_total != 0
                                                                              ? '${(100 * _recieved ~/ _total)}%'
                                                                              : ''),
                                                                        ),
                                                                        Center(
                                                                          child:
                                                                              CircularProgressIndicator(value: _total != 0 ? _recieved / _total : 0),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  )),
                                                    Center(
                                                      child: (_total == 0 &&
                                                              downloadedId !=
                                                                  mediaItem.id)
                                                          ? IconButton(
                                                              icon: Icon(
                                                                Icons.save_alt,
                                                              ),
                                                              onPressed: () {
                                                                downloadSong(
                                                                    mediaItem.id
                                                                        .toString(),
                                                                    scaffoldContext,
                                                                    mediaItem
                                                                        .title
                                                                        .toString(),
                                                                    mediaItem
                                                                        .artist
                                                                        .toString(),
                                                                    mediaItem
                                                                        .album
                                                                        .toString(),
                                                                    mediaItem
                                                                        .artUri
                                                                        .toString(),
                                                                    mediaItem
                                                                        .extras[
                                                                            'URL']
                                                                        .toString());
                                                              })
                                                          : SizedBox(),
                                                    ),
                                                  ],
                                                )
                                              : IconButton(
                                                  icon: Icon(
                                                    Icons.save_alt,
                                                  ),
                                                  onPressed: null);
                                        }),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
            ),
          );
        }),
      ),
      // ),
    );
    return widget.fromMiniplayer
        ? container
        : Dismissible(
            direction: DismissDirection.down,
            background: Container(color: Colors.transparent),
            key: Key('playScreen'),
            onDismissed: (direction) {
              Navigator.pop(context);
            },
            child: container);
  }

  /// A stream reporting the combined state of the current media item and its
  /// current position.
  Stream<MediaState> get _mediaStateStream =>
      Rx.combineLatest2<MediaItem, Duration, MediaState>(
          AudioService.currentMediaItemStream,
          AudioService.positionStream,
          (mediaItem, position) => MediaState(mediaItem, position));

  /// A stream reporting the combined state of the current queue and the current
  /// media item within that queue.
  Stream<QueueState> get _queueStateStream =>
      Rx.combineLatest2<List<MediaItem>, MediaItem, QueueState>(
          AudioService.queueStream,
          AudioService.currentMediaItemStream,
          (queue, mediaItem) => QueueState(queue, mediaItem));

  fetchSongUrl(songId) async {
    String kUrl = '';
    String key = "38346591";

    // print('starting fetching url');
    var songUrl = Uri.https(
        "www.jiosaavn.com",
        "/api.php?app_version=5.18.3&api_version=4&readable_version=5.18.3&v=79&_format=json&__call=song.getDetails&pids=" +
            songId);
    var res = await get(songUrl, headers: {"Accept": "application/json"});
    var resEdited = (res.body).split("-->");
    var getMain = jsonDecode(resEdited[1]);
    kUrl = await DesPlugin.decrypt(
        key, getMain[songId]["more_info"]["encrypted_media_url"]);

    kUrl = kUrl.replaceAll(
        '_96.', '_${preferredQuality.replaceAll(' kbps', '')}.');
    print('fetched url');
    // print(kUrl);
    return kUrl;
  }

  downloadSong(id, scaffoldContext, title, artist, album, image, kUrl) async {
    String filepath;
    String filepath2;
    List<int> _bytes = [];
    var status = await Permission.storage.status;
    if (status.isPermanentlyDenied || status.isDenied) {
      // code of read or write file in external storage (SD card)
      // You can request multiple permissions at once.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.accessMediaLocation,
        Permission.mediaLibrary,
      ].request();
      debugPrint(statuses[Permission.storage].toString());
    }
    status = await Permission.storage.status;
    if (status.isGranted) {
      print('permission granted');
    }
    final filename = title + " - " + artist + ".m4a";

    final artname = title + "_artwork.jpg";

    String dlPath = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_MUSIC);
    await File(dlPath + "/" + filename)
        .create(recursive: true)
        .then((value) => filepath = value.path);
    await File(dlPath + "/" + artname)
        .create(recursive: true)
        .then((value) => filepath2 = value.path);
    debugPrint('Audio path $filepath');
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(
        elevation: 6,
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Downloading your song',
          style: TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          textColor: Theme.of(context).accentColor,
          label: 'Ok',
          onPressed: () {},
        ),
      ),
    );
    kUrl = kUrl.replaceAll(
        "_96.", "_${preferredDownloadQuality.replaceAll(' kbps', '')}.");
    print(kUrl);
    final response = await Client().send(Request('GET', Uri.parse(kUrl)));
    _total = response.contentLength;
    // print('total length is $_total');
    _recieved = 0;
    response.stream.listen((value) {
      _bytes.addAll(value);
      try {
        setState(() {
          _recieved += value.length;
          // print('recieved is $_recieved');
        });
      } catch (e) {}
    }).onDone(() async {
      final file = File("${(filepath)}");
      await file.writeAsBytes(_bytes);

      var request2 = await HttpClient().getUrl(Uri.parse(image));
      var response2 = await request2.close();
      var bytes2 = await consolidateHttpClientResponseBytes(response2);
      File file2 = File(filepath2);

      // await file.writeAsBytes(bytes);
      await file2.writeAsBytes(bytes2);
      debugPrint("Started tag editing");

      final tag = Tag(
        title: title.toString(),
        artist: artist.toString(),
        artwork: filepath2.toString(),
        album: album.toString(),
        // genre: ,
      );

      // debugPrint("Setting up Tags");
      final tagger = Audiotagger();
      await tagger.writeTags(
        path: filepath,
        tag: tag,
      );
      await Future.delayed(const Duration(seconds: 1), () {});
      if (await file2.exists()) {
        await file2.delete();
      }
      debugPrint("Done");
      downloadedId = id;

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(SnackBar(
        elevation: 6,
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        content: Text(
          '"$title" has been downloaded',
          style: TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          textColor: Theme.of(context).accentColor,
          label: 'Ok',
          onPressed: () {},
        ),
      ));
      try {
        _total = 0;
        _recieved = 0;
        setState(() {});
      } catch (e) {}
    });
  }

  audioPlayerButton() async {
    if (globalQueue[globalIndex].extras == null) {
      globalQueue[globalIndex] = globalQueue[globalIndex].copyWith(extras: {
        'URL': await fetchSongUrl(globalQueue[globalIndex].id),
      });
    }
    await AudioService.start(
      backgroundTaskEntrypoint: _audioPlayerTaskEntrypoint,
      params: {
        'index': globalIndex,
        'offline': offline,
        'quality': preferredQuality
      },
      androidNotificationChannelName: 'BlackHole',
      androidNotificationColor: 0xFF181818,
      androidNotificationIcon: 'drawable/ic_stat_music_note',
      androidEnableQueue: true,
      androidStopForegroundOnPause: true,
    );

    await AudioService.updateQueue(globalQueue);
    // print('updated queue at the start');
    // print('queue now is $globalQueue');
    // AudioService.setRepeatMode(AudioServiceRepeatMode.all);
    // await AudioService.setShuffleMode(AudioServiceShuffleMode.all);
    // print('calling play in audioplayerbutton');
    await AudioService.play();
  }

  FloatingActionButton playButton() => FloatingActionButton(
        elevation: 10,
        child: Icon(
          Icons.play_arrow_rounded,
          size: 40.0,
          color: Colors.white,
        ),
        onPressed: AudioService.play,
      );

  FloatingActionButton pauseButton() => FloatingActionButton(
        elevation: 10,
        child: Icon(
          Icons.pause_rounded,
          color: Colors.white,
          size: 40.0,
        ),
        onPressed: AudioService.pause,
      );
}

class QueueState {
  final List<MediaItem> queue;
  final MediaItem mediaItem;

  QueueState(this.queue, this.mediaItem);
}

class MediaState {
  final MediaItem mediaItem;
  final Duration position;

  MediaState(this.mediaItem, this.position);
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onChangeEnd;

  SeekBar({
    @required this.duration,
    @required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _dragValue;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final value = min(_dragValue ?? widget.position?.inMilliseconds?.toDouble(),
        widget.duration.inMilliseconds.toDouble());
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }
    return Column(
      children: [
        Slider(
          min: 0.0,
          max: widget.duration.inMilliseconds.toDouble(),
          value: value,
          activeColor: Theme.of(context).accentColor,
          inactiveColor: Theme.of(context).accentColor.withOpacity(0.3),
          onChanged: (value) {
            if (!_dragging) {
              _dragging = true;
            }
            setState(() {
              _dragValue = value;
            });
            if (widget.onChanged != null) {
              widget.onChanged(Duration(milliseconds: value.round()));
            }
          },
          onChangeEnd: (value) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd(Duration(milliseconds: value.round()));
            }
            _dragging = false;
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                        .firstMatch("$_position")
                        ?.group(1) ??
                    '$_position',
                // style: Theme.of(context).textTheme.caption,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Text(
                RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                        .firstMatch("$_duration")
                        ?.group(1) ??
                    '$_duration',
                // style: Theme.of(context).textTheme.caption,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Duration get _remaining => widget.duration - widget.position;
  Duration get _position => widget.position;
  Duration get _duration => widget.duration;
}

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class AudioPlayerTask extends BackgroundAudioTask {
  AudioPlayer _player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    handleAudioSessionActivation: true,
  );
  Seeker _seeker;
  Timer _sleepTimer;
  StreamSubscription<PlaybackEvent> _eventSubscription;
  String kUrl = '';
  String key = "38346591";
  String decrypt = "";
  String preferredQuality;
  List<MediaItem> queue = [];
  String repeatMode = 'None';
  bool shuffle = false;
  List<MediaItem> defaultQueue = [];

  int index;
  bool offline;
  // int get index => _player.currentIndex == null ? 0 : _player.currentIndex;
  MediaItem get mediaItem => index == null ? queue[0] : queue[index];

  Future<File> getImageFileFromAssets() async {
    final byteData = await rootBundle.load('assets/cover.jpg');
    final file = File('${(await getTemporaryDirectory()).path}/cover.jpg');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }

  Future<void> onTaskRemoved() async {
    await onStop();
  }

  initiateBox() async {
    try {
      await Hive.initFlutter();
    } catch (e) {}
    await Hive.openBox('settings');
  }

  addRecentlyPlayed(mediaitem) async {
    await initiateBox();
    var recentList;
    try {
      recentList = await Hive.box('settings').get('recentlyPlayed').toList();
    } catch (e) {
      recentList = null;
    }

    var item = {
      'title': mediaitem.title.toString(),
      'id': mediaitem.id.toString(),
      'artist': mediaitem.artist.toString(),
      'album': mediaitem.album.toString(),
      'image': mediaitem.artUri.toString(),
      'duration': mediaitem.duration.inSeconds.toString(),
    };
    await recentList == null ? recentList = [item] : recentList.insert(0, item);
    if (recentList.length > 30) {
      recentList = recentList.sublist(0, 30);
    }
    Hive.box('settings').put('recentlyPlayed', recentList);
    final userID = Hive.box('settings').get('userID');
    final dbRef = FirebaseDatabase.instance.reference().child("Users");
    dbRef.child(userID).update({"recentlyPlayed": recentList});
  }

  fetchSongUrl(songId) async {
    print('starting fetching url');
    var songUrl = Uri.https(
        "www.jiosaavn.com",
        "/api.php?app_version=5.18.3&api_version=4&readable_version=5.18.3&v=79&_format=json&__call=song.getDetails&pids=" +
            songId);
    var res = await get(songUrl, headers: {"Accept": "application/json"});
    var resEdited = (res.body).split("-->");
    var getMain = jsonDecode(resEdited[1]);
    kUrl = await DesPlugin.decrypt(
        key, getMain[songId]["more_info"]["encrypted_media_url"]);
    kUrl = kUrl.replaceAll(
        '_96.', "_${preferredQuality.replaceAll(' kbps', '')}.");
    print('fetched url');
    print(kUrl);
    final client = Client();
    final request = Request('HEAD', Uri.parse(kUrl))..followRedirects = false;
    final response = await client.send(request);
    print(response);
    kUrl = (response.headers['location']);
    return kUrl;
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    index = params['index'];
    offline = params['offline'];
    preferredQuality = params['quality'];
    await initiateBox();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    // _player.currentIndexStream.listen((index) {
    //   if (index != null) AudioServiceBackground.setMediaItem(queue[index]);
    // });
    // _eventSubscription = _player.playbackEventStream.listen((event) {
    //   _broadcastState();
    // });
    _player.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          if (queue[index] != queue.last) {
            if (repeatMode != 'One') {
              AudioService.skipToNext();
            } else {
              AudioService.skipToQueueItem(queue[index].id);
            }
          } else {
            if (repeatMode == 'None') {
              AudioService.stop();
            } else {
              if (repeatMode == 'One') {
                AudioService.skipToQueueItem(queue[index].id);
              } else {
                AudioService.skipToQueueItem(queue[0].id);
              }
            }
          }

          break;
        case ProcessingState.ready:
          break;
        default:
          break;
      }
    });
    // print('finished onStart function');
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    final newIndex = queue.indexWhere((item) => item.id == mediaId);
    index = newIndex;
    if (newIndex == -1) return;
    // _player.pause();
    // index = newIndex;
    if (queue[newIndex].extras == null) {
      queue[newIndex] = queue[newIndex].copyWith(extras: {
        'URL': await fetchSongUrl(queue[newIndex].id),
      });
      await AudioServiceBackground.setQueue(queue);
    }

    // print(AudioService.currentMediaItem);
    // print('new song is ${queue[newIndex]}');
    if (offline) {
      await _player.setFilePath(queue[newIndex].extras['URL']);
    } else {
      await _player.setUrl(queue[newIndex].extras['URL']);
      addRecentlyPlayed(queue[newIndex]);
    }

    if (queue[index].duration == Duration(seconds: 180)) {
      var duration = await _player.durationFuture;
      if (duration != null) {
        await AudioServiceBackground.setMediaItem(
            queue[index].copyWith(duration: duration));
      } else {
        await AudioServiceBackground.setMediaItem(queue[index]);
      }
    } else {
      await AudioServiceBackground.setMediaItem(queue[index]);
    }
    // await AudioServiceBackground.setMediaItem(queue[newIndex]);
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> _queue) {
    queue = _queue;
    AudioServiceBackground.setQueue(_queue);
    // print('Queue inside service updated is $queue');
    return super.onUpdateQueue(_queue);
  }

  @override
  Future<void> onPlay() async {
    // _player.currentIndexStream.listen((index) {
    //   if (index != null) AudioServiceBackground.setMediaItem(queue[index]);
    // });
    _eventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });
    try {
      if (queue[index].artUri == null) {
        File f = await getImageFileFromAssets();
        queue[index] =
            queue[index].copyWith(artUri: Uri.parse('file:${f.path}'));
      }
      if (AudioServiceBackground.mediaItem != queue[index]) {
        if (offline) {
          await _player.setFilePath(queue[index].extras['URL']);
        } else {
          await _player.setUrl(queue[index].extras['URL']);
          addRecentlyPlayed(queue[index]);
        }
        _player.play();
        if (queue[index].duration == Duration(seconds: 180)) {
          var duration = await _player.durationFuture;
          if (duration != null) {
            await AudioServiceBackground.setMediaItem(
                queue[index].copyWith(duration: duration));
          }
        } else {
          await AudioServiceBackground.setMediaItem(queue[index]);
        }
      } else {
        _player.play();
      }
    } catch (e) {
      // print('Error in onPlay: $e');
      print(queue[index].extras['URl']);
    }
  }

  @override
  Future<dynamic> onCustomAction(String myFunction, dynamic myVariable) {
    if (myFunction == 'sleepTimer') {
      _sleepTimer?.cancel();
      if (myVariable.runtimeType == int &&
          myVariable != null &&
          myVariable > 0) {
        _sleepTimer = Timer(Duration(minutes: myVariable), () {
          onStop();
        });
      }
    }

    if (myFunction == 'repeatMode') {
      repeatMode = myVariable;
    }
    if (myFunction == 'shuffle') {
      shuffle = myVariable;
      if (shuffle) {
        defaultQueue = queue.toList();
        queue.shuffle();
        AudioService.updateQueue(queue);
      } else {
        queue = defaultQueue;
        AudioService.updateQueue(queue);
      }
    }
    return Future.value(true);
  }

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onSeekTo(Duration position) => _player.seek(position);

  @override
  Future<void> onFastForward() => _seekRelative(fastForwardInterval);

  @override
  Future<void> onRewind() => _seekRelative(-rewindInterval);

  @override
  Future<void> onSeekForward(bool begin) async => _seekContinuously(begin, 1);

  @override
  Future<void> onSeekBackward(bool begin) async => _seekContinuously(begin, -1);

  @override
  Future<void> onStop() async {
    await _player.dispose();
    _eventSubscription.cancel();
    // It is important to wait for this state to be broadcast before we shut
    // down the task. If we don't, the background task will be destroyed before
    // the message gets sent to the UI.
    await _broadcastState();
    // Shut down this task
    await super.onStop();
  }

  /// Jumps away from the current position by [offset].
  Future<void> _seekRelative(Duration offset) async {
    var newPosition = _player.position + offset;
    // Make sure we don't jump out of bounds.
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
    // Perform the jump via a seek.
    await _player.seek(newPosition);
  }

  /// Begins or stops a continuous seek in [direction]. After it begins it will
  /// continue seeking forward or backward by 10 seconds within the audio, at
  /// intervals of 1 second in app time.
  void _seekContinuously(bool begin, int direction) {
    _seeker?.stop();
    if (begin) {
      _seeker = Seeker(_player, Duration(seconds: 10 * direction),
          Duration(seconds: 1), mediaItem)
        ..start();
    }
  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 3],
      processingState: _getProcessingState(),
      playing: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  /// Maps just_audio's processing state into into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_skipState] instead.
  AudioProcessingState _getProcessingState() {
    switch (_player.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_player.processingState}");
    }
  }
}

/// An object that performs interruptable sleep.
class Sleeper {
  Completer _blockingCompleter;

  /// Sleep for a duration. If sleep is interrupted, a
  /// [SleeperInterruptedException] will be thrown.
  Future<void> sleep([Duration duration]) async {
    _blockingCompleter = Completer();
    if (duration != null) {
      await Future.any([Future.delayed(duration), _blockingCompleter.future]);
    } else {
      await _blockingCompleter.future;
    }
    final interrupted = _blockingCompleter.isCompleted;
    _blockingCompleter = null;
    if (interrupted) {
      throw SleeperInterruptedException();
    }
  }

  /// Interrupt any sleep that's underway.
  void interrupt() {
    if (_blockingCompleter?.isCompleted == false) {
      _blockingCompleter.complete();
    }
  }
}

class SleeperInterruptedException {}

class Seeker {
  final AudioPlayer player;
  final Duration positionInterval;
  final Duration stepInterval;
  final MediaItem mediaItem;
  bool _running = false;

  Seeker(
    this.player,
    this.positionInterval,
    this.stepInterval,
    this.mediaItem,
  );

  start() async {
    _running = true;
    while (_running) {
      Duration newPosition = player.position + positionInterval;
      if (newPosition < Duration.zero) newPosition = Duration.zero;
      if (newPosition > mediaItem.duration) newPosition = mediaItem.duration;
      player.seek(newPosition);
      await Future.delayed(stepInterval);
    }
  }

  stop() {
    _running = false;
  }
}
