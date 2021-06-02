import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audio_session/audio_session.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class AudioPlayerTask extends BackgroundAudioTask {
  AudioPlayer _player = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    handleAudioSessionActivation: true,
  );
  Timer _sleepTimer;
  StreamSubscription<PlaybackEvent> _eventSubscription;
  String preferredQuality;
  List<MediaItem> queue = [];
  String repeatMode = 'None';
  bool shuffle = false;
  List<MediaItem> defaultQueue = [];

  int index;
  bool offline;
  MediaItem get mediaItem => index == null ? queue[0] : queue[index];

  Future<File> getImageFileFromAssets() async {
    final byteData = await rootBundle.load('assets/cover.jpg');
    final file = File('${(await getTemporaryDirectory()).path}/cover.jpg');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }

  Future<void> onTaskRemoved() async {
    bool stopForegroundService =
        Hive.box('settings').get('stopForegroundService') ?? true;
    if (stopForegroundService) {
      await onStop();
    }
  }

  initiateBox() async {
    try {
      await Hive.initFlutter();
    } catch (e) {}
    try {
      await Hive.openBox('settings');
    } catch (e) {
      print('Failed to open Settings Box');
      print("Error: $e");
      Directory dir = await getApplicationDocumentsDirectory();
      String dirPath = dir.path;
      String boxName = "settings";
      File dbFile = File('$dirPath/$boxName.hive');
      File lockFile = File('$dirPath/$boxName.lock');
      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox("settings");
    }
    try {
      await Hive.openBox('recentlyPlayed');
    } catch (e) {
      print('Failed to open Recent Box');
      print("Error: $e");
      Directory dir = await getApplicationDocumentsDirectory();
      String dirPath = dir.path;
      String boxName = "recentlyPlayed";
      File dbFile = File('$dirPath/$boxName.hive');
      File lockFile = File('$dirPath/$boxName.lock');
      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox("recentlyPlayed");
    }
  }

  addRecentlyPlayed(MediaItem mediaitem) async {
    List recentList;
    try {
      recentList = await Hive.box('recentlyPlayed').get('recentSongs').toList();
    } catch (e) {
      recentList = null;
    }

    Map item = {
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
    recentList == null ? recentList = [item] : recentList.insert(0, item);

    final jsonList = recentList.map((item) => jsonEncode(item)).toList();
    final uniqueJsonList = jsonList.toSet().toList();
    recentList = uniqueJsonList.map((item) => jsonDecode(item)).toList();

    if (recentList.length > 30) {
      recentList = recentList.sublist(0, 30);
    }
    Hive.box('recentlyPlayed').put('recentSongs', recentList);
    final userID = Hive.box('settings').get('userID');
    final dbRef = FirebaseDatabase.instance.reference().child("Users");
    dbRef.child(userID).update({"recentlyPlayed": recentList});
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    index = params['index'];
    offline = params['offline'];
    preferredQuality = params['quality'];
    await initiateBox();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
    _eventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });
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
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    final newIndex = queue.indexWhere((item) => item.id == mediaId);
    index = newIndex;
    if (newIndex == -1) return;
    // _player.pause();
    if (offline) {
      await _player.setFilePath(queue[newIndex].extras['url']);
    } else {
      await _player.setUrl(queue[newIndex]
          .extras['url']
          .replaceAll("_96.", "_${preferredQuality.replaceAll(' kbps', '')}."));
      addRecentlyPlayed(queue[newIndex]);
    }

    if (queue[index].duration == Duration(seconds: 180)) {
      Duration duration = await _player.durationFuture;
      if (duration != null) {
        await AudioServiceBackground.setMediaItem(
            queue[index].copyWith(duration: duration));
      } else {
        await AudioServiceBackground.setMediaItem(queue[index]);
      }
    } else {
      await AudioServiceBackground.setMediaItem(queue[index]);
    }
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> _queue) {
    queue = _queue;
    AudioServiceBackground.setQueue(_queue);
    return super.onUpdateQueue(_queue);
  }

  @override
  Future<void> onPlay() async {
    try {
      if (queue[index].artUri == null) {
        File f = await getImageFileFromAssets();
        queue[index] = queue[index].copyWith(artUri: Uri.file('${f.path}'));
      }
      if (AudioServiceBackground.mediaItem != queue[index]) {
        if (offline) {
          await _player.setFilePath(queue[index].extras['url']);
        } else {
          await _player.setUrl(queue[index].extras['url'].replaceAll(
              "_96.", "_${preferredQuality.replaceAll(' kbps', '')}."));
          addRecentlyPlayed(queue[index]);
        }
        _player.play();
        if (queue[index].duration == Duration(seconds: 180)) {
          Duration duration = await _player.durationFuture;
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
      print('Error in onPlay: $e');
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
  Future<void> onStop() async {
    await _player.dispose();
    _eventSubscription.cancel();
    await _broadcastState();
    // Shut down this task
    await super.onStop();
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

  /// Maps just_audio's processing state into into audio_service's playing state.
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
