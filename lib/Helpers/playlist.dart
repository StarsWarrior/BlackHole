import 'package:audio_service/audio_service.dart';
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
