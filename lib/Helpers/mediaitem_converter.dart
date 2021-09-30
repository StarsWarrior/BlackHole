import 'package:audio_service/audio_service.dart';

class MediaItemConverter {
  Map mediaItemtoMap(MediaItem mediaItem) {
    return {
      'id': mediaItem.id.toString(),
      'album': mediaItem.album.toString(),
      'album_id': mediaItem.extras?['album_id'],
      'artist': mediaItem.artist.toString(),
      'duration': mediaItem.duration?.inSeconds.toString(),
      'genre': mediaItem.genre.toString(),
      'has_lyrics': mediaItem.extras!['has_lyrics'],
      'image': mediaItem.artUri.toString(),
      'language': mediaItem.extras?['language'].toString(),
      'release_date': mediaItem.extras?['release_date'],
      'subtitle': mediaItem.extras?['subtitle'],
      'title': mediaItem.title.toString(),
      'url': mediaItem.extras!['url'].toString(),
      'year': mediaItem.extras?['year'].toString(),
      '320kbps': mediaItem.extras?['320kbps'],
      'perma_url': mediaItem.extras?['perma_url'],
    };
  }

  MediaItem mapToMediaItem(Map song,
      {bool addedByAutoplay = false, bool autoplay = true}) {
    return MediaItem(
        id: song['id'].toString(),
        album: song['album'].toString(),
        artist: song['artist'].toString(),
        duration: Duration(
            seconds: int.parse(
                (song['duration'] == null || song['duration'] == 'null')
                    ? '180'
                    : song['duration'].toString())),
        title: song['title'].toString(),
        artUri: Uri.parse(song['image']
            .toString()
            .replaceAll('50x50', '500x500')
            .replaceAll('150x150', '500x500')),
        genre: song['language'].toString(),
        extras: {
          'url': song['url'],
          'year': song['year'],
          'language': song['language'],
          '320kbps': song['320kbps'],
          'has_lyrics': song['has_lyrics'],
          'release_date': song['release_date'],
          'album_id': song['album_id'],
          'subtitle': song['subtitle'],
          'perma_url': song['perma_url'],
          'addedByAutoplay': addedByAutoplay,
          'autoplay': autoplay,
        });
  }

  MediaItem downMapToMediaItem(Map song) {
    return MediaItem(
        id: song['id'].toString(),
        album: song['album'].toString(),
        artist: song['artist'].toString(),
        duration: Duration(
            seconds: int.parse(
                (song['duration'] == null || song['duration'] == 'null')
                    ? '180'
                    : song['duration'].toString())),
        title: song['title'].toString(),
        artUri: Uri.file(song['image'].toString()),
        genre: song['genre'].toString(),
        extras: {
          'url': song['path'].toString(),
          'year': song['year'],
          'language': song['genre'],
          'release_date': song['release_date'],
          'album_id': song['album_id'],
          'subtitle': song['subtitle'],
        });
  }
}
