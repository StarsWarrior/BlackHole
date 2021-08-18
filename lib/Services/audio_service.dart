import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerTask extends BackgroundAudioTask {
  final _equalizer = AndroidEqualizer();
  AndroidEqualizerParameters? _equalizerParams;

  late final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [
        _equalizer,
      ],
    ),
  );

  int? count;
  Timer? _sleepTimer;
  late StreamSubscription<PlaybackEvent> _eventSubscription;
  late String preferredQuality;
  List<MediaItem> queue = [];
  List<MediaItem> defaultQueue = [];
  late ConcatenatingAudioSource concatenatingAudioSource;

  int? index;
  bool offline = false;
  MediaItem get mediaItem => index == null ? queue[0] : queue[index!];

  @override
  Future<void> onTaskRemoved() async {
    final bool stopForegroundService = Hive.box('settings')
        .get('stopForegroundService', defaultValue: true) as bool;
    if (stopForegroundService) {
      await onStop();
    }
  }

  Future<void> initiateBox() async {
    try {
      await Hive.initFlutter();
    } catch (e) {
      // print('Failed to initiate Hive');
      // print('Error: $e');
    }
    try {
      await Hive.openBox('settings');
    } catch (e) {
      // print('Failed to open Settings Box');
      // print('Error: $e');
      final Directory dir = await getApplicationDocumentsDirectory();
      final String dirPath = dir.path;
      final File dbFile = File('$dirPath/settings.hive');
      final File lockFile = File('$dirPath/settings.lock');
      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox('settings');
    }
    try {
      await Hive.openBox('recentlyPlayed');
    } catch (e) {
      // print('Failed to open Recent Box');
      // print('Error: $e');
      final Directory dir = await getApplicationDocumentsDirectory();
      final String dirPath = dir.path;
      final File dbFile = File('$dirPath/recentlyPlayed.hive');
      final File lockFile = File('$dirPath/recentlyPlayed.lock');
      await dbFile.delete();
      await lockFile.delete();
      await Hive.openBox('recentlyPlayed');
    }
  }

  Future<void> addRecentlyPlayed(MediaItem mediaitem) async {
    if (mediaItem.artUri.toString().startsWith('https://img.youtube.com')) {
      return;
    }
    List recentList;
    recentList = await Hive.box('recentlyPlayed')
        .get('recentSongs', defaultValue: [])?.toList() as List;

    final Map item = MediaItemConverter().mediaItemtoMap(mediaItem);
    recentList.insert(0, item);

    final jsonList = recentList.map((item) => jsonEncode(item)).toList();
    final uniqueJsonList = jsonList.toSet().toList();
    recentList = uniqueJsonList.map((item) => jsonDecode(item)).toList();

    if (recentList.length > 30) {
      recentList = recentList.sublist(0, 30);
    }
    Hive.box('recentlyPlayed').put('recentSongs', recentList);
  }

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    index = params!['index'] as int?;
    offline = params['offline'] as bool;
    preferredQuality = params['quality'].toString();
    await initiateBox();

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.currentIndexStream.distinct().listen((idx) {
      if (idx != null && queue.isNotEmpty) {
        index = idx;
        AudioServiceBackground.setMediaItem(queue[idx]);
        if (count != null) {
          count = count! - 1;
          if (count! <= 0) {
            count = null;
            onStop();
          }
        }
      }
    });

    // _player.sequenceStateStream.distinct().listen((state) {
    // if (state != null) {
    // MediaItem mediaItem = state.currentSource.tag;
    // AudioServiceBackground.setMediaItem(mediaItem);
    // index = queue.indexWhere((element) => element == mediaItem);
    // }
    // });

    _eventSubscription = _player.playbackEventStream.listen((event) {
      _broadcastState();
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        AudioService.stop();
      }
    });
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    final newIndex = queue.indexWhere((item) => item.id == mediaId);
    if (newIndex == -1) return;
    index = newIndex;
    _player.seek(Duration.zero, index: newIndex);
    if (!offline) addRecentlyPlayed(queue[newIndex]);
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> _queue) async {
    await AudioServiceBackground.setQueue(_queue);
    await AudioServiceBackground.setMediaItem(_queue[index!]);
    concatenatingAudioSource = ConcatenatingAudioSource(
      children: _queue
          .map((item) => AudioSource.uri(
              offline
                  ? Uri.file(item.extras!['url'].toString())
                  : Uri.parse(item.extras!['url'].toString().replaceAll(
                      '_96.', "_${preferredQuality.replaceAll(' kbps', '')}.")),
              tag: item))
          .toList(),
    );
    await _player.setAudioSource(concatenatingAudioSource);
    await _player.seek(Duration.zero, index: index);
    queue = _queue;
  }

  @override
  Future<void> onAddQueueItemAt(MediaItem mediaItem, int index) async {
    int addIndex = index;
    if (addIndex == -1) {
      addIndex = queue.indexWhere((item) => item == queue[index]) + 1;
    }
    await concatenatingAudioSource.insert(
        addIndex,
        AudioSource.uri(
            offline
                ? Uri.file(mediaItem.extras!['url'].toString())
                : Uri.parse(mediaItem.extras!['url'].toString().replaceAll(
                    '_96.', "_${preferredQuality.replaceAll(' kbps', '')}.")),
            tag: mediaItem));
    queue.insert(addIndex, mediaItem);
    await AudioServiceBackground.setQueue(queue);
  }

  Future<void> onAddQueueList(List<MediaItem> mediaItemList) async {
    await concatenatingAudioSource.addAll(mediaItemList
        .map((item) => AudioSource.uri(
            offline
                ? Uri.file(item.extras!['url'].toString())
                : Uri.parse(item.extras!['url'].toString().replaceAll(
                    '_96.', "_${preferredQuality.replaceAll(' kbps', '')}.")),
            tag: item))
        .toList());
    queue.addAll(mediaItemList);
    await AudioServiceBackground.setQueue(queue);
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {
    await concatenatingAudioSource.add(AudioSource.uri(
        offline
            ? Uri.file(mediaItem.extras!['url'].toString())
            : Uri.parse(mediaItem.extras!['url'].toString().replaceAll(
                '_96.', "_${preferredQuality.replaceAll(' kbps', '')}.")),
        tag: mediaItem));
    queue.add(mediaItem);
    await AudioServiceBackground.setQueue(queue);
  }

  @override
  Future<void> onRemoveQueueItem(MediaItem mediaItem) async {
    final removeIndex = queue.indexWhere((item) => item == mediaItem);
    queue.remove(mediaItem);
    await concatenatingAudioSource.removeAt(removeIndex);
    await AudioServiceBackground.setQueue(queue);
  }

  Future<void> onReorderQueue(int oldIndex, int newIndex) async {
    concatenatingAudioSource.move(oldIndex, newIndex);
    final MediaItem item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    await AudioServiceBackground.setQueue(queue);
  }

  @override
  Future<void> onPlay() async {
    if (!offline) addRecentlyPlayed(queue[index!]);
    _player.play();
  }

  @override
  Future<dynamic> onCustomAction(String myFunction, dynamic myVariable) {
    if (myFunction == 'sleepTimer') {
      _sleepTimer?.cancel();
      if (myVariable.runtimeType == int &&
          myVariable != null &&
          myVariable > 0 as bool) {
        _sleepTimer = Timer(Duration(minutes: myVariable as int), () {
          onStop();
        });
      }
    }

    if (myFunction == 'sleepCounter') {
      if (myVariable.runtimeType == int &&
          myVariable != null &&
          myVariable > 0 as bool) {
        count = myVariable as int;
      }
    }

    if (myFunction == 'addListToQueue') {
      final List temp = myVariable as List;
      final MediaItemConverter converter = MediaItemConverter();
      final List<MediaItem> mediaItemList =
          temp.map((item) => converter.mapToMediaItem(item as Map)).toList();
      onAddQueueList(mediaItemList);
    }

    if (myFunction == 'setBandGain') {
      final bandIdx = myVariable['band'] as int;
      final gain = myVariable['gain'] as double;
      _equalizerParams!.bands[bandIdx].setGain(gain);
    }

    if (myFunction == 'reorder') {
      onReorderQueue(myVariable[0] as int, myVariable[1] as int);
    }

    if (myFunction == 'setEqualizer') {
      _equalizer.setEnabled(myVariable as bool);
    }

    if (myFunction == 'getEqualizerParams') {
      return getEqParms();
    }

    return Future.value(true);
  }

  Future<Map> getEqParms() async {
    _equalizerParams ??= await _equalizer.parameters;
    final List<AndroidEqualizerBand> bands = _equalizerParams!.bands;
    final List<Map> bandList = bands
        .map((e) => {
              'centerFrequency': e.centerFrequency,
              'gain': e.gain,
              'index': e.index
            })
        .toList();

    return {
      'maxDecibels': _equalizerParams!.maxDecibels,
      'minDecibels': _equalizerParams!.minDecibels,
      'bands': bandList
    };
  }

  @override
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) {
    switch (repeatMode) {
      case AudioServiceRepeatMode.all:
        _player.setLoopMode(LoopMode.all);
        break;

      case AudioServiceRepeatMode.one:
        _player.setLoopMode(LoopMode.one);
        break;
      default:
        _player.setLoopMode(LoopMode.off);
        break;
    }

    return super.onSetRepeatMode(repeatMode);
  }

  @override
  Future<void> onSetShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    switch (shuffleMode) {
      case AudioServiceShuffleMode.none:
        queue = defaultQueue;
        _player.setShuffleModeEnabled(false);
        AudioServiceBackground.setQueue(queue);
        break;
      case AudioServiceShuffleMode.group:
        break;
      case AudioServiceShuffleMode.all:
        defaultQueue = queue;
        await _player.setShuffleModeEnabled(true);
        await _player.shuffle();
        _player.sequenceStateStream
            .map((state) => state?.effectiveSequence)
            .distinct()
            .map((sequence) =>
                sequence!.map((source) => source.tag as MediaItem?).toList())
            .listen(AudioServiceBackground.setQueue as void Function(
                List<MediaItem?>)?);
        break;
    }
  }

  @override
  Future<void> onClick(MediaButton button) {
    switch (button) {
      case MediaButton.next:
        onSkipToNext();
        break;
      case MediaButton.previous:
        onSkipToPrevious();
        break;
      case MediaButton.media:
        _handleMediaActionPressed();
        break;
    }
    return Future.value();
  }

  late BehaviorSubject<int> _tappedMediaActionNumber;
  Timer? _timer;

  void _handleMediaActionPressed() {
    if (_timer == null) {
      _tappedMediaActionNumber = BehaviorSubject.seeded(1);
      _timer = Timer(const Duration(milliseconds: 600), () {
        final tappedNumber = _tappedMediaActionNumber.value;
        if (tappedNumber == 1) {
          if (AudioServiceBackground.state.playing) {
            onPause();
          } else {
            onPlay();
          }
        } else if (tappedNumber == 2) {
          onSkipToNext();
        } else {
          onSkipToPrevious();
        }

        _tappedMediaActionNumber.close();
        _timer!.cancel();
        _timer = null;
      });
    } else {
      final current = _tappedMediaActionNumber.value;
      _tappedMediaActionNumber.add(current + 1);
    }
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
    await super.onStop();
  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: [
        MediaAction.seekTo,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      androidCompactActions: [0, 1, 2],
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
        throw Exception('Invalid state: ${_player.processingState}');
    }
  }
}
