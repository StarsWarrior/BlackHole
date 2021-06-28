// import 'package:http/http.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeServices {
  // String searchAuthority = "www.youtube.com";
  // String searchPath = "/results";
  Future<List<Video>> getPlaylistSongs(String id) async {
    YoutubeExplode yt = YoutubeExplode();
    List<Video> results = await yt.playlists.getVideos(id).toList();
    yt.close();
    return results;
  }

  Future<Map> formatVideo(Video video) async {
    return {
      'id': video.id.value,
      'album': video?.author,
      'duration': video?.duration?.inSeconds.toString(),
      'title': video.title,
      'artist': video.author,
      'image': video?.thumbnails?.highResUrl.toString(),
      'language': '',
      'url': await getUri(video),
      'year': video?.uploadDate?.year.toString(),
      '320kbps': 'false',
      'has_lyrics': 'false',
      'release_date': video?.publishDate.toString(),
      'album_id': video?.channelId?.value,
      'subtitle': video?.author,
    };
  }

  Future<List<Video>> fetchSearchResults(String query) async {
    YoutubeExplode yt = YoutubeExplode();
    List<Video> searchResults = await yt.search.getVideos(query);

    // Uri link = Uri.https(searchAuthority, searchPath, {"search_query": query});
    // final Response response = await get(link);
    // if (response.statusCode != 200) {
    // return [];
    // }
    // List searchResults = RegExp(
    // r'\"videoId\"\:\"(.*?)\",\"thumbnail\"\:\{\"thumbnails\"\:\[\{\"url\"\:\"(.*?)".*?\"title\"\:\{\"runs\"\:\[\{\"text\"\:\"(.*?)\"\}\].*?\"longBylineText\"\:\{\"runs\"\:\[\{\"text\"\:\"(.*?)\",.*?\"lengthText\"\:\{\"accessibility\"\:\{\"accessibilityData\"\:\{\"label\"\:\"(.*?)\"\}\},\"simpleText\"\:\"(.*?)\"\},\"viewCountText\"\:\{\"simpleText\"\:\"(.*?) views\"\}.*?\"commandMetadata\"\:\{\"webCommandMetadata\"\:\{\"url\"\:\"(/watch?.*?)\".*?\"shortViewCountText\"\:\{\"accessibility\"\:\{\"accessibilityData\"\:\{\"label\"\:\"(.*?) views\"\}\},\"simpleText\"\:\"(.*?) views\"\}.*?\"channelThumbnailSupportedRenderers\"\:\{\"channelThumbnailWithLinkRenderer\"\:\{\"thumbnail\"\:\{\"thumbnails\"\:\[\{\"url\"\:\"(.*?)\"')
    // .allMatches(response.body)
    // .map((m) {
    // List<String> parts = m[6].toString().split(':');
    // int dur;
    // if (parts.length == 3)
    // dur = int.parse(parts[0]) * 60 * 60 +
    // int.parse(parts[1]) * 60 +
    // int.parse(parts[2]);
    // if (parts.length == 2)
    // dur = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    // if (parts.length == 1) dur = int.parse(parts[0]);

    // return {
    //   'id': m[1],
    //   'image': m[2],
    //   'title': m[3],
    //     'longLength': m[5],
    //     'length': m[6],
    //     'totalViewsCount': m[7],
    //     'url': 'https://www.youtube.com' + m[8],
    //     'album': '',
    //     'channelName': m[4],
    //     'channelImage': m[11],
    //     'duration': dur.toString(),
    //     'longViews': m[9] + ' views',
    //     'views': m[10] + ' views',
    //     'artist': '',
    //     "year": '',
    //     "language": '',
    //     "320kbps": '',
    //     "has_lyrics": '',
    //     "release_date": '',
    //     "album_id": '',
    //     'subtitle': '',
    //   };
    // }).toList();
    yt.close();
    return searchResults;
  }

  Future<String> getUri(Video video) async {
    YoutubeExplode yt = YoutubeExplode();
    StreamManifest manifest =
        await yt.videos.streamsClient.getManifest(video.id);
    AudioOnlyStreamInfo streamInfo = manifest.audioOnly.withHighestBitrate();
    print(streamInfo.bitrate);
    yt.close();
    return streamInfo.url.toString();
  }
}
