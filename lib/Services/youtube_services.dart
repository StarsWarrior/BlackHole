/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2022, Ankit Sangwan
 */

import 'dart:convert';

import 'package:http/http.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeServices {
  String searchAuthority = 'www.youtube.com';
  Map paths = {
    'search': '/results',
    'channel': '/channel',
    'music': '/music',
    'playlist': '/playlist'
  };
  final YoutubeExplode yt = YoutubeExplode();

  Future<List<Video>> getPlaylistSongs(String id) async {
    final List<Video> results = await yt.playlists.getVideos(id).toList();
    return results;
  }

  Future<Playlist> getPlaylistDetails(String id) async {
    final Playlist metadata = await yt.playlists.get(id);
    return metadata;
  }

  Future<Map<String, List>> getMusicHome() async {
    final Uri link = Uri.https(
      searchAuthority,
      paths['music'].toString(),
    );
    final Response response = await get(link);
    if (response.statusCode != 200) {
      return {};
    }
    final String searchResults =
        RegExp(r'(\"contents\":{.*?}),\"metadata\"', dotAll: true)
            .firstMatch(response.body)![1]!;
    final Map data = json.decode('{$searchResults}') as Map;

    final List result = data['contents']['twoColumnBrowseResultsRenderer']
            ['tabs'][0]['tabRenderer']['content']['sectionListRenderer']
        ['contents'] as List;

    final List headResult = data['header']['carouselHeaderRenderer']['contents']
        [0]['carouselItemRenderer']['carouselItems'] as List;

    final List shelfRenderer = result.map((element) {
      return element['itemSectionRenderer']['contents'][0]['shelfRenderer'];
    }).toList();

    final List finalResult = shelfRenderer.map((element) {
      if (element['title']['runs'][0]['text'].trim() !=
          'Highlights from Global Citizen Live') {
        return {
          'title': element['title']['runs'][0]['text'],
          'playlists': element['title']['runs'][0]['text'].trim() == 'Charts'
              ? formatChartItems(
                  element['content']['horizontalListRenderer']['items'] as List,
                )
              : element['title']['runs'][0]['text']
                      .toString()
                      .contains('Music Videos')
                  ? formatVideoItems(
                      element['content']['horizontalListRenderer']['items']
                          as List,
                    )
                  : formatItems(
                      element['content']['horizontalListRenderer']['items']
                          as List,
                    ),
        };
      } else {
        return null;
      }
    }).toList();

    final List finalHeadResult = formatHeadItems(headResult);
    finalResult.removeWhere((element) => element == null);

    return {'body': finalResult, 'head': finalHeadResult};
  }

  List formatVideoItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['gridVideoRenderer']['title']['simpleText'],
          'type': 'video',
          'description': e['gridVideoRenderer']['shortBylineText']['runs'][0]
              ['text'],
          'count': e['gridVideoRenderer']['shortViewCountText']['simpleText'],
          'videoId': e['gridVideoRenderer']['videoId'],
          'firstItemId': e['gridVideoRenderer']['videoId'],
          'image':
              e['gridVideoRenderer']['thumbnail']['thumbnails'].last['url'],
          'imageMin': e['gridVideoRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageMedium': e['gridVideoRenderer']['thumbnail']['thumbnails'][1]
              ['url'],
          'imageStandard': e['gridVideoRenderer']['thumbnail']['thumbnails'][2]
              ['url'],
          'imageMax':
              e['gridVideoRenderer']['thumbnail']['thumbnails'].last['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      return List.empty();
    }
  }

  List formatChartItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['gridPlaylistRenderer']['title']['runs'][0]['text'],
          'type': 'chart',
          'description': e['gridPlaylistRenderer']['shortBylineText']['runs'][0]
              ['text'],
          'count': e['gridPlaylistRenderer']['videoCountText']['runs'][0]
              ['text'],
          'playlistId': e['gridPlaylistRenderer']['navigationEndpoint']
              ['watchEndpoint']['playlistId'],
          'firstItemId': e['gridPlaylistRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'image': e['gridPlaylistRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageMedium': e['gridPlaylistRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageStandard': e['gridPlaylistRenderer']['thumbnail']['thumbnails']
              [0]['url'],
          'imageMax': e['gridPlaylistRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      return List.empty();
    }
  }

  List formatItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['compactStationRenderer']['title']['simpleText'],
          'type': 'playlist',
          'description': e['compactStationRenderer']['description']
              ['simpleText'],
          'count': e['compactStationRenderer']['videoCountText']['runs'][0]
              ['text'],
          'playlistId': e['compactStationRenderer']['navigationEndpoint']
              ['watchEndpoint']['playlistId'],
          'firstItemId': e['compactStationRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'image': e['compactStationRenderer']['thumbnail']['thumbnails'][0]
              ['url'],
          'imageMedium': e['compactStationRenderer']['thumbnail']['thumbnails']
              [0]['url'],
          'imageStandard': e['compactStationRenderer']['thumbnail']
              ['thumbnails'][1]['url'],
          'imageMax': e['compactStationRenderer']['thumbnail']['thumbnails'][2]
              ['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      return List.empty();
    }
  }

  List formatHeadItems(List itemsList) {
    try {
      final List result = itemsList.map((e) {
        return {
          'title': e['defaultPromoPanelRenderer']['title']['runs'][0]['text'],
          'type': 'video',
          'description':
              (e['defaultPromoPanelRenderer']['description']['runs'] as List)
                  .map((e) => e['text'])
                  .toList()
                  .join(),
          'videoId': e['defaultPromoPanelRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'firstItemId': e['defaultPromoPanelRenderer']['navigationEndpoint']
              ['watchEndpoint']['videoId'],
          'image': e['defaultPromoPanelRenderer']
                          ['largeFormFactorBackgroundThumbnail']
                      ['thumbnailLandscapePortraitRenderer']['landscape']
                  ['thumbnails']
              .last['url'],
          'imageMedium': e['defaultPromoPanelRenderer']
                      ['largeFormFactorBackgroundThumbnail']
                  ['thumbnailLandscapePortraitRenderer']['landscape']
              ['thumbnails'][1]['url'],
          'imageStandard': e['defaultPromoPanelRenderer']
                      ['largeFormFactorBackgroundThumbnail']
                  ['thumbnailLandscapePortraitRenderer']['landscape']
              ['thumbnails'][2]['url'],
          'imageMax': e['defaultPromoPanelRenderer']
                          ['largeFormFactorBackgroundThumbnail']
                      ['thumbnailLandscapePortraitRenderer']['landscape']
                  ['thumbnails']
              .last['url'],
        };
      }).toList();

      return result;
    } catch (e) {
      return List.empty();
    }
  }

  Future<Map?> formatVideo({
    required Video video,
    String quality = 'High',
    // bool preferM4a = true,
  }) async {
    if (video.duration?.inSeconds == null) return null;
    return {
      'id': video.id.value,
      'album': video.author,
      'duration': video.duration?.inSeconds.toString(),
      'title': video.title,
      'artist': video.author,
      'image': video.thumbnails.maxResUrl,
      'secondImage': video.thumbnails.highResUrl,
      'language': 'YouTube',
      'genre': 'YouTube',
      'url': await getUri(video, quality),
      'year': video.uploadDate?.year.toString(),
      '320kbps': 'false',
      'has_lyrics': 'false',
      'release_date': video.publishDate.toString(),
      'album_id': video.channelId.value,
      'subtitle': video.author,
      'perma_url': video.url,
    };
  }

  Future<List<Video>> fetchSearchResults(String query) async {
    final List<Video> searchResults = await yt.search.getVideos(query);

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
    return searchResults;
  }

  Future<String> getUri(
    Video video,
    String quality,
    // {bool preferM4a = true}
  ) async {
    final StreamManifest manifest =
        await yt.videos.streamsClient.getManifest(video.id);
    final List<AudioOnlyStreamInfo> sortedStreamInfo =
        manifest.audioOnly.sortByBitrate();
    // if (preferM4a) {
    //   final List<AudioOnlyStreamInfo> temp = sortedStreamInfo
    //       .where((element) => element.audioCodec == 'mp4')
    //       .toList();

    //   if (temp.isNotEmpty) {
    //     if (quality == 'High') {
    //       final AudioOnlyStreamInfo streamInfo = temp.last;
    //       return streamInfo.url.toString();
    //     } else {
    //       final AudioOnlyStreamInfo streamInfo = temp.first;
    //       return streamInfo.url.toString();
    //     }
    //   }
    // }
    if (quality == 'High') {
      final AudioOnlyStreamInfo streamInfo = sortedStreamInfo.last;
      return streamInfo.url.toString();
    }
    final AudioOnlyStreamInfo streamInfo = sortedStreamInfo.first;
    return streamInfo.url.toString();
  }
}
