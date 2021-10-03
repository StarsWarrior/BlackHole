import 'package:on_audio_query/on_audio_query.dart';

class OfflineAudioQuery {
  OnAudioQuery audioQuery = OnAudioQuery();

  Future<void> requestPermission() async {
    while (!await audioQuery.permissionsStatus()) {
      await audioQuery.permissionsRequest();
    }
  }

  Future<List<SongModel>> getSongs(
      {SongSortType? sortType, OrderType? orderType}) async {
    return audioQuery.querySongs(
      sortType: sortType ?? SongSortType.DATA_ADDED,
      orderType: orderType ?? OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
    );
  }

  Future<List<AlbumModel>> getAlbums(
      {AlbumSortType? sortType, OrderType? orderType}) async {
    return audioQuery.queryAlbums(
      sortType: sortType,
      orderType: orderType,
      uriType: UriType.EXTERNAL,
    );
  }

  Future<List<ArtistModel>> getArtists(
      {ArtistSortType? sortType, OrderType? orderType}) async {
    return audioQuery.queryArtists(
      sortType: sortType,
      orderType: orderType,
      uriType: UriType.EXTERNAL,
    );
  }

  Future<List<GenreModel>> getGenres(
      {GenreSortType? sortType, OrderType? orderType}) async {
    return audioQuery.queryGenres(
      sortType: sortType,
      orderType: orderType,
      uriType: UriType.EXTERNAL,
    );
  }

  Future<List> getArtwork(List<SongModel> songs) async {
    final List<Map> songsMap = [];
    for (final SongModel song in songs) {
      final songMap = song.getMap;
      songMap.addEntries([
        MapEntry(
            'image',
            await audioQuery.queryArtwork(song.id, ArtworkType.AUDIO,
                size: 350))
      ]);
      songsMap.add(songMap);
    }
    return songsMap;
  }
}
