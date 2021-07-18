import 'package:audio_service/audio_service.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Helpers/songs_count.dart';
import 'package:hive/hive.dart';

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
  // setState(() {});
}

void addPlaylistMap(String name, Map info) async {
  if (name != 'Favorite Songs') await Hive.openBox(name);
  Box playlistBox = Hive.box(name);
  List _songs = playlistBox.values.toList();
  AddSongsCount().addSong(
    name,
    playlistBox.values.length + 1,
    _songs.length >= 4
        ? _songs.sublist(0, 4)
        : _songs.sublist(0, _songs.length),
  );
  playlistBox.put(info['id'].toString(), info);
}

void addPlaylist(String name, MediaItem mediaItem) async {
  if (name != 'Favorite Songs') await Hive.openBox(name);
  Box playlistBox = Hive.box(name);
  Map info = MediaItemConverter().mediaItemtoMap(mediaItem);
  List _songs = playlistBox.values.toList();
  AddSongsCount().addSong(
    name,
    playlistBox.values.length + 1,
    _songs.length >= 4
        ? _songs.sublist(0, 4)
        : _songs.sublist(0, _songs.length),
  );
  playlistBox.put(mediaItem.id.toString(), info);
}
