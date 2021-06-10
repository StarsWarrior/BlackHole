import 'dart:async';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Helpers/songs_count.dart';
import 'package:blackhole/Services/audioService.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/seekBar.dart';

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
  String preferredQuality =
      Hive.box('settings').get('streamingQuality') ?? '96 kbps';
  String preferredDownloadQuality =
      Hive.box('settings').get('downloadQuality') ?? '320 kbps';
  String repeatMode = Hive.box('settings').get('repeatMode') ?? 'None';
  bool stopServiceOnPause =
      Hive.box('settings').get('stopServiceOnPause') ?? true;
  bool shuffle = Hive.box('settings').get('shuffle') ?? false;
  List<MediaItem> globalQueue = [];
  int globalIndex = 0;
  bool same = false;
  List response = [];
  bool fetched = false;
  bool offline = false;
  MediaItem playItem;
  // sleepTimer(0) cancels the timer
  void sleepTimer(int time) {
    AudioService.customAction('sleepTimer', time);
  }

  Duration _time;

  void main() async {
    await Hive.openBox('Favorite Songs');
  }

  @override
  void initState() {
    super.initState();
    main();
  }

  bool checkPlaylist(String name, String key) {
    if (name != 'Favorite Songs') {
      Hive.openBox(name).then((value) {
        final playlistBox = Hive.box(name);
        return playlistBox.containsKey(key);
      });
    }
    final playlistBox = Hive.box(name);
    return playlistBox.containsKey(key);
  }

  void removeLiked(String key) async {
    Box likedBox = Hive.box('Favorite Songs');
    likedBox.delete(key);
    setState(() {});
  }

  void addPlaylist(String name, MediaItem mediaItem) async {
    if (name != 'Favorite Songs') await Hive.openBox(name);
    Box playlistBox = Hive.box(name);
    Map info = {
      'id': mediaItem.id.toString(),
      'artist': mediaItem.artist.toString(),
      'album': mediaItem.album.toString(),
      'image': mediaItem.artUri.toString(),
      'duration': mediaItem.duration.inSeconds.toString(),
      'title': mediaItem.title.toString(),
      'url': mediaItem.extras['url'].toString(),
      "year": mediaItem.extras["year"].toString(),
      "language": mediaItem.extras["language"].toString(),
      "genre": mediaItem.genre.toString(),
      "320kbps": mediaItem.extras["320kbps"],
      "has_lyrics": mediaItem.extras["has_lyrics"],
      "release_date": mediaItem.extras["release_date"],
      "album_id": mediaItem.extras["album_id"],
      "subtitle": mediaItem.extras["subtitle"]
    };
    List _songs = playlistBox.values;
    AddSongsCount().addSong(
      name,
      playlistBox.values.length + 1,
      _songs.length >= 4
          ? _songs.sublist(0, 4)
          : _songs.sublist(0, _songs.length),
    );
    playlistBox.put(mediaItem.id.toString(), info);
    setState(() {});
  }

  setTags(Map response, Directory tempDir) async {
    String playTitle = response['title'];
    playTitle == ''
        ? playTitle = response['id']
            .split('/')
            .last
            .replaceAll('.m4a', '')
            .replaceAll('.mp3', '')
        : playTitle = response['title'];
    String playArtist = response['artist'];
    playArtist == ''
        ? playArtist = response['id']
            .split('/')
            .last
            .replaceAll('.m4a', '')
            .replaceAll('.mp3', '')
        : playArtist = response['artist'];

    String playAlbum = response['album'];
    final playDuration = response['duration'] ?? 180;
    File file;
    if (response['image'] != null) {
      try {
        file = await File(
                '${tempDir.path}/${playTitle.toString().replaceAll('/', '')}-${playArtist.toString().replaceAll('/', '')}.jpg')
            .create();
        file.writeAsBytesSync(response['image']);
      } catch (e) {
        file = null;
      }
    } else {
      file = null;
    }

    MediaItem tempDict = MediaItem(
        id: response['id'],
        album: playAlbum,
        duration: Duration(seconds: playDuration),
        title: playTitle != null ? playTitle.split("(")[0] : 'Unknown',
        artist: playArtist ?? 'Unknown',
        artUri: file == null
            ? Uri.file('${(await getTemporaryDirectory()).path}/cover.jpg')
            : Uri.file('${file.path}'),
        extras: {'url': response['id']});
    globalQueue.add(tempDict);
    setState(() {});
  }

  setOffValues(List response) {
    getTemporaryDirectory().then((tempDir) async {
      final File file =
          File('${(await getTemporaryDirectory()).path}/cover.jpg');
      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/cover.jpg');
        await file.writeAsBytes(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      }
      for (int i = 0; i < response.length; i++) {
        await setTags(response[i], tempDir);
      }
    });
  }

  setValues(List response) {
    for (int i = 0; i < response.length; i++) {
      MediaItem tempDict = MediaItem(
          id: response[i]['id'],
          album: response[i]['album'],
          duration:
              Duration(seconds: int.parse(response[i]['duration'] ?? 180)),
          title: response[i]['title'],
          artist: response[i]["artist"],
          artUri: Uri.parse(response[i]['image']),
          genre: response[i]["language"],
          extras: {
            "url": response[i]["url"],
            "year": response[i]["year"],
            "language": response[i]["language"],
            "320kbps": response[i]["320kbps"],
            "has_lyrics": response[i]["has_lyrics"],
            "release_date": response[i]["release_date"],
            "album_id": response[i]["album_id"],
            "subtitle": response[i]['subtitle']
          });
      globalQueue.add(tempDict);
    }
    fetched = true;
  }

  @override
  Widget build(BuildContext context) {
    BuildContext scaffoldContext;
    Map data = widget.data;
    if (response == data['response'] && globalIndex == data['index']) {
      same = true;
    }
    response = data['response'];
    globalIndex = data['index'];
    if (data['offline'] == null) {
      offline = AudioService.currentMediaItem?.extras['url'].startsWith('http')
          ? false
          : true;
    } else {
      offline = data['offline'];
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
          setValues(response);
        }
      }
    }
    Widget container = GradientContainer(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            // title: Text('Now Playing'),
            toolbarHeight: 40.0,
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            leading: IconButton(
                icon: Icon(Icons.expand_more_rounded),
                onPressed: () {
                  if (widget.fromMiniplayer) {
                    widget.controller.animateToHeight(state: PanelState.MIN);
                  } else {
                    Navigator.pop(context);
                  }
                }),
            actions: [
              PopupMenuButton(
                icon: Icon(Icons.more_vert_rounded),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(7.0))),
                onSelected: (value) {
                  if (value == 2) {
                    showModalBottomSheet(
                        isDismissible: true,
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (BuildContext context) {
                          return StreamBuilder<QueueState>(
                            stream: _queueStateStream,
                            builder: (context, snapshot) {
                              String lyrics;
                              final queueState = snapshot.data;
                              final mediaItem = queueState?.mediaItem;

                              Future<dynamic> fetchLyrics() {
                                Uri lyricsUrl = Uri.https(
                                    "www.jiosaavn.com",
                                    "/api.php?__call=lyrics.getLyrics&lyrics_id=" +
                                        mediaItem.id +
                                        "&ctx=web6dot0&api_version=4&_format=json");
                                return get(lyricsUrl,
                                    headers: {"Accept": "application/json"});
                              }

                              return mediaItem == null
                                  ? SizedBox()
                                  : BottomGradientContainer(
                                      child: Center(
                                        child: SingleChildScrollView(
                                          physics: BouncingScrollPhysics(),
                                          padding:
                                              EdgeInsets.fromLTRB(0, 20, 0, 20),
                                          child: mediaItem
                                                      .extras["has_lyrics"] ==
                                                  "true"
                                              ? FutureBuilder(
                                                  future: fetchLyrics(),
                                                  builder: (BuildContext
                                                          context,
                                                      AsyncSnapshot snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState.done) {
                                                      if (mediaItem.extras[
                                                              "has_lyrics"] ==
                                                          "true") {
                                                        List lyricsEdited =
                                                            (snapshot.data.body)
                                                                .split("-->");
                                                        final fetchedLyrics =
                                                            json.decode(
                                                                lyricsEdited[
                                                                    1]);
                                                        lyrics = fetchedLyrics[
                                                                "lyrics"]
                                                            .toString()
                                                            .replaceAll(
                                                                "<br>", "\n");
                                                        return Text(lyrics);
                                                      }
                                                    }
                                                    return CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Theme.of(context)
                                                                  .accentColor),
                                                    );
                                                  })
                                              : EmptyScreen().emptyScreen(
                                                  context,
                                                  0,
                                                  ":( ",
                                                  100.0,
                                                  "Lyrics",
                                                  60.0,
                                                  "Not Available",
                                                  20.0),
                                        ),
                                      ),
                                    );
                            },
                          );
                        });
                  }
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
                                    setState(() {
                                      _time = value;
                                    });
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
                                        Theme.of(context).accentColor,
                                  ),
                                  child: Text('Ok'),
                                  onPressed: () {
                                    sleepTimer(_time.inMinutes);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(scaffoldContext)
                                        .showSnackBar(
                                      SnackBar(
                                        duration: Duration(seconds: 2),
                                        elevation: 6,
                                        backgroundColor: Colors.grey[900],
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Sleep timer set for ${_time.inMinutes} minutes',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        action: SnackBarAction(
                                          textColor:
                                              Theme.of(context).accentColor,
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
                          final settingsBox = Hive.box('settings');
                          List playlistNames =
                              settingsBox.get('playlistNames') ?? [];

                          return BottomGradientContainer(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text('Create Playlist'),
                                    leading: Icon(Icons.add_rounded),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          final controller =
                                              TextEditingController();
                                          return AlertDialog(
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Create new playlist',
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .accentColor),
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
                                                    controller: controller,
                                                    autofocus: true,
                                                    onSubmitted:
                                                        (String value) {
                                                      if (value.trim() == '') {
                                                        value =
                                                            'Playlist ${playlistNames.length}';
                                                      }
                                                      if (playlistNames
                                                          .contains(value))
                                                        value = value + ' (1)';
                                                      playlistNames.add(value);
                                                      settingsBox.put(
                                                          'playlistNames',
                                                          playlistNames);
                                                      Navigator.pop(context);
                                                    }),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  primary: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.grey[700],
                                                  //       backgroundColor: Theme.of(context).accentColor,
                                                ),
                                                child: Text("Cancel"),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  primary: Colors.white,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .accentColor,
                                                ),
                                                child: Text(
                                                  "Ok",
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                onPressed: () {
                                                  if (controller.text.trim() ==
                                                      '') {
                                                    controller.text =
                                                        'Playlist ${playlistNames.length}';
                                                  }
                                                  if (playlistNames.contains(
                                                      controller.text))
                                                    controller.text =
                                                        controller.text +
                                                            ' (1)';
                                                  playlistNames
                                                      .add(controller.text);

                                                  settingsBox.put(
                                                      'playlistNames',
                                                      playlistNames);
                                                  Navigator.pop(context);
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
                                  playlistNames.isEmpty
                                      ? SizedBox()
                                      : StreamBuilder<QueueState>(
                                          stream: _queueStateStream,
                                          builder: (context, snapshot) {
                                            final queueState = snapshot.data;
                                            final mediaItem =
                                                queueState?.mediaItem;
                                            return ListView.builder(
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: playlistNames.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                      leading: Icon(Icons
                                                          .queue_music_rounded),
                                                      title: Text(
                                                          '${playlistNames[index]}'),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        // checkPlaylist(playlistNames[index],
                                                        // mediaItem.id.toString())

                                                        addPlaylist(
                                                            playlistNames[
                                                                index],
                                                            mediaItem);
                                                        ScaffoldMessenger.of(
                                                                scaffoldContext)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            duration: Duration(
                                                                seconds: 2),
                                                            elevation: 6,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[900],
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            content: Text(
                                                              'Added to ${playlistNames[index]}',
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
                                                      });
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
                                Icon(CupertinoIcons.timer),
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
                                Icon(Icons.playlist_add_rounded),
                                Spacer(),
                                Text('Add to playlist'),
                                Spacer(),
                              ],
                            )),
                        PopupMenuItem(
                            value: 1,
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.timer),
                                Spacer(),
                                Text('Sleep Timer'),
                                Spacer(),
                              ],
                            )),
                        PopupMenuItem(
                            value: 2,
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.textformat),
                                Spacer(),
                                Text('Show Lyrics'),
                                Spacer(),
                              ],
                            )),
                      ],
              )
            ],
          ),
          body: Builder(builder: (BuildContext context) {
            scaffoldContext = context;
            return StreamBuilder<bool>(
                stream: AudioService.runningStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.active) {
                    return SizedBox();
                  }
                  final running = snapshot.data ?? false;
                  return (!running)
                      ? FutureBuilder(
                          future: audioPlayerButton(),
                          builder: (context, AsyncSnapshot spshot) {
                            if (spshot.hasData) {
                              return SizedBox();
                            } else {
                              return Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Card(
                                    elevation: 10,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      children: [
                                        Image(
                                            fit: BoxFit.cover,
                                            image:
                                                AssetImage('assets/cover.jpg')),
                                        globalQueue.length <= globalIndex
                                            ? Image(
                                                fit: BoxFit.cover,
                                                image: AssetImage(
                                                    'assets/cover.jpg'))
                                            : offline
                                                ? Image(
                                                    fit: BoxFit.cover,
                                                    image: FileImage(File(
                                                      globalQueue[globalIndex]
                                                          .artUri
                                                          .toFilePath(),
                                                    )))
                                                : Image(
                                                    fit: BoxFit.cover,
                                                    image: NetworkImage(
                                                      globalQueue[globalIndex]
                                                          .artUri
                                                          .toString(),
                                                    ),
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.9,
                                                  ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        15, 25, 15, 0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
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
                                            globalQueue.length <= globalIndex
                                                ? 'Unknown'
                                                : globalQueue[globalIndex]
                                                    .title,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 50,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .accentColor),
                                          )),
                                        ),
                                        Text(
                                          globalQueue.length <= globalIndex
                                              ? 'Unknown'
                                              : globalQueue[globalIndex].artist,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SeekBar(
                                    duration: Duration.zero,
                                    position: Duration.zero,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        children: [
                                          SizedBox(height: 6.0),
                                          IconButton(
                                            icon: Icon(
                                              Icons.shuffle_rounded,
                                            ),
                                            iconSize: 25.0,
                                            onPressed: null,
                                          ),
                                          if (!offline)
                                            IconButton(
                                              icon: Icon(
                                                Icons.favorite_border_rounded,
                                              ),
                                              iconSize: 25.0,
                                              onPressed: null,
                                            ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.skip_previous_rounded),
                                        iconSize: 45.0,
                                        onPressed: null,
                                      ),
                                      Stack(
                                        children: [
                                          Center(
                                              child: SizedBox(
                                            height: 65,
                                            width: 65,
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Theme.of(context)
                                                          .accentColor),
                                            ),
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
                                        icon: Icon(Icons.skip_next_rounded),
                                        iconSize: 45.0,
                                        onPressed: null,
                                      ),
                                      Column(
                                        children: [
                                          SizedBox(height: 6.0),
                                          IconButton(
                                            icon: Icon(Icons.repeat_rounded),
                                            iconSize: 25.0,
                                            onPressed: null,
                                          ),
                                          if (!offline)
                                            IconButton(
                                                icon: Icon(Icons.save_alt),
                                                iconSize: 25.0,
                                                onPressed: null),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          })
                      : Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                GestureDetector(
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
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      children: [
                                        Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage('assets/cover.jpg'),
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9,
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
                                                                      .length <=
                                                                  globalIndex)
                                                          ? (AssetImage(
                                                              'assets/cover.jpg'))
                                                          : offline
                                                              ? FileImage(File(
                                                                  globalQueue[
                                                                          globalIndex]
                                                                      .artUri
                                                                      .toFilePath(),
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
                                                              0.9,
                                                    )
                                                  : Image(
                                                      fit: BoxFit.cover,
                                                      image: offline
                                                          ? FileImage(File(
                                                              mediaItem.artUri
                                                                  .toFilePath()))
                                                          : NetworkImage(
                                                              mediaItem.artUri
                                                                  .toString()),
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.9,
                                                    );
                                            }),
                                      ],
                                    ),
                                  ),
                                ),

                                /// Title and subtitle
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 20, 15, 0),
                                  child: StreamBuilder<QueueState>(
                                      stream: _queueStateStream,
                                      builder: (context, snapshot) {
                                        final queueState = snapshot.data;
                                        final mediaItem = queueState?.mediaItem;
                                        return Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            /// Title container
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
                                                            globalQueue
                                                                    .length <=
                                                                globalIndex)
                                                        ? 'Title'
                                                        : globalQueue[
                                                                globalIndex]
                                                            .title),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 50,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .accentColor),
                                              )),
                                            ),

                                            /// Subtitle container
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
                                                            globalQueue
                                                                    .length ==
                                                                0)
                                                        ? ''
                                                        : globalQueue[
                                                                globalIndex]
                                                            .artist),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w500),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                ),

                                /// Seekbar starts from here
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

                                /// Final row starts from here
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        SizedBox(height: 6.0),
                                        IconButton(
                                          icon: Icon(Icons.shuffle_rounded),
                                          iconSize: 25.0,
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
                                        ),
                                        if (!offline)
                                          StreamBuilder<QueueState>(
                                            stream: _queueStateStream,
                                            builder: (context, snapshot) {
                                              final queueState = snapshot.data;
                                              bool liked = false;
                                              final mediaItem =
                                                  queueState?.mediaItem;
                                              try {
                                                liked = checkPlaylist(
                                                    'Favorite Songs',
                                                    mediaItem.id);
                                              } catch (e) {}

                                              return mediaItem == null
                                                  ? IconButton(
                                                      icon: Icon(Icons
                                                          .favorite_border_rounded),
                                                      iconSize: 25.0,
                                                      onPressed: null)
                                                  : IconButton(
                                                      icon: Icon(
                                                        liked
                                                            ? Icons
                                                                .favorite_rounded
                                                            : Icons
                                                                .favorite_border_rounded,
                                                        color: liked
                                                            ? Colors.redAccent
                                                            : null,
                                                      ),
                                                      iconSize: 25.0,
                                                      onPressed: () {
                                                        liked
                                                            ? removeLiked(
                                                                mediaItem.id)
                                                            : addPlaylist(
                                                                'Favorite Songs',
                                                                mediaItem);
                                                        liked = !liked;
                                                        ScaffoldMessenger.of(
                                                                scaffoldContext)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            duration: Duration(
                                                                seconds: 2),
                                                            action:
                                                                SnackBarAction(
                                                                    textColor: Theme.of(
                                                                            context)
                                                                        .accentColor,
                                                                    label:
                                                                        'Undo',
                                                                    onPressed:
                                                                        () {
                                                                      liked
                                                                          ? removeLiked(mediaItem
                                                                              .id)
                                                                          : addPlaylist(
                                                                              'Favorite Songs',
                                                                              mediaItem);
                                                                      liked =
                                                                          !liked;
                                                                    }),
                                                            elevation: 6,
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[900],
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            content: Text(
                                                              liked
                                                                  ? 'Added to Favorites'
                                                                  : 'Removed from Favorites',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                        );
                                                      });
                                            },
                                          ),
                                      ],
                                    ),
                                    StreamBuilder<QueueState>(
                                        stream: _queueStateStream,
                                        builder: (context, snapshot) {
                                          final queueState = snapshot.data;
                                          final queue = queueState?.queue ?? [];
                                          final mediaItem =
                                              queueState?.mediaItem;
                                          return (queue != null &&
                                                  queue.isNotEmpty)
                                              ? IconButton(
                                                  icon: Icon(Icons
                                                      .skip_previous_rounded),
                                                  iconSize: 45.0,
                                                  onPressed: (mediaItem ==
                                                              queue.first ||
                                                          mediaItem == null)
                                                      ? null
                                                      : AudioService
                                                          .skipToPrevious,
                                                )
                                              : IconButton(
                                                  icon: Icon(Icons
                                                      .skip_previous_rounded),
                                                  iconSize: 45.0,
                                                  onPressed: null);
                                        }),

                                    /// Play button
                                    Stack(
                                      children: [
                                        Center(
                                          child: StreamBuilder<
                                              AudioProcessingState>(
                                            stream: AudioService
                                                .playbackStateStream
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
                                                          CircularProgressIndicator(
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
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
                                          child: StreamBuilder<bool>(
                                            stream: AudioService
                                                .playbackStateStream
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

                                    StreamBuilder<QueueState>(
                                      stream: _queueStateStream,
                                      builder: (context, snapshot) {
                                        final queueState = snapshot.data;
                                        final queue = queueState?.queue ?? [];
                                        final mediaItem = queueState?.mediaItem;
                                        return (queue != null &&
                                                queue.isNotEmpty)
                                            ? IconButton(
                                                icon: Icon(
                                                    Icons.skip_next_rounded),
                                                iconSize: 45.0,
                                                onPressed: (mediaItem ==
                                                            queue.last ||
                                                        mediaItem == null)
                                                    ? null
                                                    : AudioService.skipToNext,
                                              )
                                            : IconButton(
                                                icon: Icon(
                                                    Icons.skip_next_rounded),
                                                iconSize: 45.0,
                                                onPressed: null);
                                      },
                                    ),
                                    Column(
                                      children: [
                                        SizedBox(height: 6.0),
                                        IconButton(
                                          icon: repeatMode == 'One'
                                              ? Icon(Icons.repeat_one_rounded)
                                              : Icon(Icons.repeat_rounded),
                                          iconSize: 25.0,
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
                                        ),
                                        if (!offline)
                                          StreamBuilder<QueueState>(
                                              stream: _queueStateStream,
                                              builder: (context, snapshot) {
                                                final queueState =
                                                    snapshot.data;
                                                final queue =
                                                    queueState?.queue ?? [];
                                                final mediaItem =
                                                    queueState?.mediaItem;
                                                return (mediaItem != null &&
                                                        queue.isNotEmpty)
                                                    ? DownloadButton(data: {
                                                        'id': mediaItem.id
                                                            .toString(),
                                                        'artist': mediaItem
                                                            .artist
                                                            .toString(),
                                                        'album': mediaItem.album
                                                            .toString(),
                                                        'image': mediaItem
                                                            .artUri
                                                            .toString(),
                                                        'duration': mediaItem
                                                            .duration.inSeconds
                                                            .toString(),
                                                        'title': mediaItem.title
                                                            .toString(),
                                                        'url': mediaItem
                                                            .extras['url']
                                                            .toString(),
                                                        "year": mediaItem
                                                            .extras["year"]
                                                            .toString(),
                                                        "language": mediaItem
                                                            .extras["language"]
                                                            .toString(),
                                                        "genre": mediaItem.genre
                                                            .toString(),
                                                        "320kbps": mediaItem
                                                            .extras["320kbps"],
                                                        "has_lyrics":
                                                            mediaItem.extras[
                                                                "has_lyrics"],
                                                        "release_date":
                                                            mediaItem.extras[
                                                                "release_date"],
                                                        "album_id": mediaItem
                                                            .extras["album_id"],
                                                        "subtitle": mediaItem
                                                            .extras["subtitle"]
                                                      })
                                                    : IconButton(
                                                        icon: Icon(
                                                          Icons.save_alt,
                                                        ),
                                                        iconSize: 25.0,
                                                        onPressed: null);
                                              }),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 40,
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                height: 500,
                                child: DraggableScrollableSheet(
                                    initialChildSize: 0.1,
                                    minChildSize: 0.1,
                                    maxChildSize: 1,
                                    builder: (BuildContext context,
                                        ScrollController scrollController) {
                                      return BottomGradientContainer(
                                          padding: EdgeInsets.zero,
                                          margin: EdgeInsets.only(
                                              left: 20, right: 20),
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(15.0),
                                              topRight: Radius.circular(15.0)),
                                          child: StreamBuilder<List<MediaItem>>(
                                            stream: AudioService.queueStream,
                                            builder: (context, snapshot) {
                                              final queue = snapshot.data;
                                              return queue == null
                                                  ? SizedBox()
                                                  : StreamBuilder<MediaItem>(
                                                      stream: AudioService
                                                          .currentMediaItemStream,
                                                      builder:
                                                          (context, snapshot) {
                                                        final mediaItem =
                                                            snapshot.data;
                                                        return (mediaItem ==
                                                                    null ||
                                                                queue.isEmpty)
                                                            ? SizedBox()
                                                            : ListView.builder(
                                                                controller:
                                                                    scrollController,
                                                                physics:
                                                                    BouncingScrollPhysics(),
                                                                padding: EdgeInsets
                                                                    .only(
                                                                        top: 10,
                                                                        bottom:
                                                                            10),
                                                                shrinkWrap:
                                                                    true,
                                                                itemCount: queue
                                                                        .length +
                                                                    1,
                                                                itemBuilder:
                                                                    (context,
                                                                        index) {
                                                                  return index ==
                                                                          0
                                                                      ? SizedBox(
                                                                          height:
                                                                              40,
                                                                          child:
                                                                              Center(
                                                                            child:
                                                                                Text(
                                                                              'Now Playing',
                                                                              textAlign: TextAlign.center,
                                                                              style: TextStyle(
                                                                                fontWeight: FontWeight.w600,
                                                                                fontSize: 18,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : ListTileTheme(
                                                                          selectedColor:
                                                                              Theme.of(context).accentColor,
                                                                          child:
                                                                              ListTile(
                                                                            selected:
                                                                                queue[index - 1] == mediaItem,
                                                                            trailing: queue[index - 1] == mediaItem
                                                                                ? Icon(Icons.bar_chart_rounded)
                                                                                : SizedBox(),
                                                                            leading:
                                                                                Card(
                                                                              elevation: 5,
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(7.0),
                                                                              ),
                                                                              clipBehavior: Clip.antiAlias,
                                                                              child: Stack(
                                                                                children: [
                                                                                  Image(
                                                                                    image: AssetImage('assets/cover.jpg'),
                                                                                  ),
                                                                                  queue[index - 1].artUri == null ? SizedBox() : Image(image: queue[index - 1].artUri.toString().startsWith('file:') ? FileImage(File(queue[index - 1].artUri.toFilePath())) : NetworkImage(queue[index - 1].artUri.toString()))
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            title:
                                                                                Text(
                                                                              '${queue[index - 1].title}',
                                                                              style: TextStyle(fontWeight: queue[index - 1] == mediaItem ? FontWeight.w600 : FontWeight.normal),
                                                                            ),
                                                                            subtitle:
                                                                                Text(
                                                                              '${queue[index - 1].artist}',
                                                                            ),
                                                                            onTap:
                                                                                () {
                                                                              AudioService.skipToQueueItem(queue[index - 1].id);
                                                                            },
                                                                          ),
                                                                        );
                                                                });
                                                      },
                                                    );
                                            },
                                          ));
                                    }),
                              ),
                            ),
                          ],
                        );
                });
          }),
        ),
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

  audioPlayerButton() async {
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
      androidStopForegroundOnPause: stopServiceOnPause,
    );

    await AudioService.updateQueue(globalQueue);
    // AudioService.setRepeatMode(AudioServiceRepeatMode.all);
    // await AudioService.setShuffleMode(AudioServiceShuffleMode.all);
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

void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}
