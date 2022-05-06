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
import 'dart:developer';
import 'dart:typed_data';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Helpers/extensions.dart';
import 'package:dart_des/dart_des.dart';
import 'package:hive/hive.dart';

// ignore: avoid_classes_with_only_static_members
class FormatResponse {
  static String decode(String input) {
    const String key = '38346591';
    final DES desECB = DES(key: key.codeUnits);

    final Uint8List encrypted = base64.decode(input);
    final List<int> decrypted = desECB.decrypt(encrypted);
    final String decoded =
        utf8.decode(decrypted).replaceAll(RegExp(r'\.mp4.*'), '.mp4');
    return decoded.replaceAll('http:', 'https:');
  }

  static Future<List> formatSongsResponse(
    List responseList,
    String type,
  ) async {
    final List searchedList = [];
    for (int i = 0; i < responseList.length; i++) {
      Map? response;
      switch (type) {
        case 'song':
        case 'album':
        case 'playlist':
          response = await formatSingleSongResponse(responseList[i] as Map);
          break;
        default:
          break;
      }

      if (response!.containsKey('Error')) {
        log('Error at index $i inside FormatSongsResponse: ${response["Error"]}');
      } else {
        searchedList.add(response);
      }
    }
    return searchedList;
  }

  static Future<Map> formatSingleSongResponse(Map response) async {
    // Map cachedSong = Hive.box('cache').get(response['id']);
    // if (cachedSong != null) {
    //   return cachedSong;
    // }
    try {
      final List artistNames = [];
      if (response['more_info']?['artistMap']?['primary_artists'] == null ||
          response['more_info']?['artistMap']?['primary_artists'].length == 0) {
        if (response['more_info']?['artistMap']?['featured_artists'] == null ||
            response['more_info']?['artistMap']?['featured_artists'].length ==
                0) {
          if (response['more_info']?['artistMap']?['artists'] == null ||
              response['more_info']?['artistMap']?['artists'].length == 0) {
            artistNames.add('Unknown');
          } else {
            try {
              response['more_info']['artistMap']['artists'][0]['id']
                  .forEach((element) {
                artistNames.add(element['name']);
              });
            } catch (e) {
              response['more_info']['artistMap']['artists'].forEach((element) {
                artistNames.add(element['name']);
              });
            }
          }
        } else {
          response['more_info']['artistMap']['featured_artists']
              .forEach((element) {
            artistNames.add(element['name']);
          });
        }
      } else {
        response['more_info']['artistMap']['primary_artists']
            .forEach((element) {
          artistNames.add(element['name']);
        });
      }

      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['more_info']['album'].toString().unescape(),
        'year': response['year'],
        'duration': response['more_info']['duration'],
        'language': response['language'].toString().capitalize(),
        'genre': response['language'].toString().capitalize(),
        '320kbps': response['more_info']['320kbps'],
        'has_lyrics': response['more_info']['has_lyrics'],
        'lyrics_snippet':
            response['more_info']['lyrics_snippet'].toString().unescape(),
        'release_date': response['more_info']['release_date'],
        'album_id': response['more_info']['album_id'],
        'subtitle': response['subtitle'].toString().unescape(),
        'title': response['title'].toString().unescape(),
        'artist': artistNames.join(', ').unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': response['image']
            .toString()
            .replaceAll('150x150', '500x500')
            .replaceAll('50x50', '500x500')
            .replaceAll('http:', 'https:'),
        'perma_url': response['perma_url'],
        'url': decode(response['more_info']['encrypted_media_url'].toString()),
      };
      // Hive.box('cache').put(response['id'].toString(), info);
    } catch (e) {
      // log('Error inside FormatSingleSongResponse: $e');
      return {'Error': e};
    }
  }

  static Future<Map> formatSingleAlbumSongResponse(Map response) async {
    try {
      final List artistNames = [];
      if (response['primary_artists'] == null ||
          response['primary_artists'].toString().trim() == '') {
        if (response['featured_artists'] == null ||
            response['featured_artists'].toString().trim() == '') {
          if (response['singers'] == null ||
              response['singer'].toString().trim() == '') {
            response['singers'].toString().split(', ').forEach((element) {
              artistNames.add(element);
            });
          } else {
            artistNames.add('Unknown');
          }
        } else {
          response['featured_artists']
              .toString()
              .split(', ')
              .forEach((element) {
            artistNames.add(element);
          });
        }
      } else {
        response['primary_artists'].toString().split(', ').forEach((element) {
          artistNames.add(element);
        });
      }

      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['album'].toString().unescape(),
        // .split('(')
        // .first
        'year': response['year'],
        'duration': response['duration'],
        'language': response['language'].toString().capitalize(),
        'genre': response['language'].toString().capitalize(),
        '320kbps': response['320kbps'],
        'has_lyrics': response['has_lyrics'],
        'lyrics_snippet': response['lyrics_snippet'].toString().unescape(),
        'release_date': response['release_date'],
        'album_id': response['album_id'],
        'subtitle':
            '${response["primary_artists"].toString().trim()} - ${response["album"].toString().trim()}'
                .unescape(),

        'title': response['song'].toString().unescape(),
        // .split('(')
        // .first
        'artist': artistNames.join(', ').unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': response['image']
            .toString()
            .replaceAll('150x150', '500x500')
            .replaceAll('50x50', '500x500')
            .replaceAll('http:', 'https:'),
        'perma_url': response['perma_url'],
        'url': decode(response['encrypted_media_url'].toString())
      };
    } catch (e) {
      return {'Error': e};
    }
  }

  static Future<List<Map>> formatAlbumResponse(
    List responseList,
    String type,
  ) async {
    final List<Map> searchedAlbumList = [];
    for (int i = 0; i < responseList.length; i++) {
      Map? response;
      switch (type) {
        case 'album':
          response = await formatSingleAlbumResponse(responseList[i] as Map);
          break;
        case 'artist':
          response = await formatSingleArtistResponse(responseList[i] as Map);
          break;
        case 'playlist':
          response = await formatSinglePlaylistResponse(responseList[i] as Map);
          break;
        case 'show':
          response = await formatSingleShowResponse(responseList[i] as Map);
          break;
      }
      if (response!.containsKey('Error')) {
        log('Error at index $i inside FormatAlbumResponse: ${response["Error"]}');
      } else {
        searchedAlbumList.add(response);
      }
    }
    return searchedAlbumList;
  }

  static Future<Map> formatSingleAlbumResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'].toString().unescape(),
        'year': response['more_info']?['year'] ?? response['year'],
        'language': response['more_info']?['language'] == null
            ? response['language'].toString().capitalize()
            : response['more_info']['language'].toString().capitalize(),
        'genre': response['more_info']?['language'] == null
            ? response['language'].toString().capitalize()
            : response['more_info']['language'].toString().capitalize(),
        'album_id': response['id'],
        'subtitle': response['description'] == null
            ? response['subtitle'].toString().unescape()
            : response['description'].toString().unescape(),
        'title': response['title'].toString().unescape(),
        'artist': response['music'] == null
            ? (response['more_info']?['music']) == null
                ? (response['more_info']?['artistMap']?['primary_artists'] ==
                            null ||
                        (response['more_info']?['artistMap']?['primary_artists']
                                as List)
                            .isEmpty)
                    ? ''
                    : response['more_info']['artistMap']['primary_artists'][0]
                            ['name']
                        .toString()
                        .unescape()
                : response['more_info']['music'].toString().unescape()
            : response['music'].toString().unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': response['image']
            .toString()
            .replaceAll('150x150', '500x500')
            .replaceAll('50x50', '500x500')
            .replaceAll('http:', 'https:'),
        'count': response['more_info']?['song_pids'] == null
            ? 0
            : response['more_info']['song_pids'].toString().split(', ').length,
        'songs_pids': response['more_info']['song_pids'].toString().split(', '),
        'perma_url': response['url'].toString(),
      };
    } catch (e) {
      log('Error inside formatSingleAlbumResponse: $e');
      return {'Error': e};
    }
  }

  static Future<Map> formatSinglePlaylistResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'].toString().unescape(),
        'language': response['language'] == null
            ? response['more_info']['language'].toString().capitalize()
            : response['language'].toString().capitalize(),
        'genre': response['language'] == null
            ? response['more_info']['language'].toString().capitalize()
            : response['language'].toString().capitalize(),
        'playlistId': response['id'],
        'subtitle': response['description'] == null
            ? response['subtitle'].toString().unescape()
            : response['description'].toString().unescape(),
        'title': response['title'].toString().unescape(),
        'artist': response['extra'].toString().unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': response['image']
            .toString()
            .replaceAll('150x150', '500x500')
            .replaceAll('50x50', '500x500')
            .replaceAll('http:', 'https:'),
        'perma_url': response['url'].toString(),
      };
    } catch (e) {
      log('Error inside formatSinglePlaylistResponse: $e');
      return {'Error': e};
    }
  }

  static Future<Map> formatSingleArtistResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'] == null
            ? response['name'].toString().unescape()
            : response['title'].toString().unescape(),
        'language': response['language'].toString().capitalize(),
        'genre': response['language'].toString().capitalize(),
        'artistId': response['id'],
        'artistToken': response['url'] == null
            ? response['perma_url'].toString().split('/').last
            : response['url'].toString().split('/').last,
        'subtitle': response['description'] == null
            ? response['role'].toString().capitalize()
            : response['description'].toString().unescape(),
        'title': response['title'] == null
            ? response['name'].toString().unescape()
            : response['title'].toString().unescape(),
        // .split('(')
        // .first
        'perma_url': response['url'].toString(),
        'artist': response['title'].toString().unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': response['image']
            .toString()
            .replaceAll('150x150', '500x500')
            .replaceAll('50x50', '500x500')
            .replaceAll('http:', 'https:'),
      };
    } catch (e) {
      log('Error inside formatSingleArtistResponse: $e');
      return {'Error': e};
    }
  }

  static Future<List> formatArtistTopAlbumsResponse(List responseList) async {
    final List result = [];
    for (int i = 0; i < responseList.length; i++) {
      final Map response =
          await formatSingleArtistTopAlbumSongResponse(responseList[i] as Map);
      if (response.containsKey('Error')) {
        log('Error at index $i inside FormatArtistTopAlbumsResponse: ${response["Error"]}');
      } else {
        result.add(response);
      }
    }
    return result;
  }

  static Future<Map> formatSingleArtistTopAlbumSongResponse(
    Map response,
  ) async {
    try {
      final List artistNames = [];
      if (response['more_info']?['artistMap']?['primary_artists'] == null ||
          response['more_info']['artistMap']['primary_artists'].length == 0) {
        if (response['more_info']?['artistMap']?['featured_artists'] == null ||
            response['more_info']['artistMap']['featured_artists'].length ==
                0) {
          if (response['more_info']?['artistMap']?['artists'] == null ||
              response['more_info']['artistMap']['artists'].length == 0) {
            artistNames.add('Unknown');
          } else {
            response['more_info']['artistMap']['artists'].forEach((element) {
              artistNames.add(element['name']);
            });
          }
        } else {
          response['more_info']['artistMap']['featured_artists']
              .forEach((element) {
            artistNames.add(element['name']);
          });
        }
      } else {
        response['more_info']['artistMap']['primary_artists']
            .forEach((element) {
          artistNames.add(element['name']);
        });
      }

      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'].toString().unescape(),
        // .split('(')
        // .first
        'year': response['year'],
        'language': response['language'].toString().capitalize(),
        'genre': response['language'].toString().capitalize(),
        'album_id': response['id'],
        'subtitle': response['subtitle'].toString().unescape(),
        'title': response['title'].toString().unescape(),
        // .split('(')
        // .first
        'artist': artistNames.join(', ').unescape(),
        'album_artist': response['more_info'] == null
            ? response['music']
            : response['more_info']['music'],
        'image': response['image']
            .toString()
            .replaceAll('150x150', '500x500')
            .replaceAll('50x50', '500x500')
            .replaceAll('http:', 'https:'),
      };
    } catch (e) {
      return {'Error': e};
    }
  }

  static Future<List> formatSimilarArtistsResponse(List responseList) async {
    final List result = [];
    for (int i = 0; i < responseList.length; i++) {
      final Map response =
          await formatSingleSimilarArtistResponse(responseList[i] as Map);
      if (response.containsKey('Error')) {
        log('Error at index $i inside FormatSimilarArtistsResponse: ${response["Error"]}');
      } else {
        result.add(response);
      }
    }
    return result;
  }

  static Future<Map> formatSingleSimilarArtistResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'artist': response['name'].toString().unescape(),
        'title': response['name'].toString().unescape(),
        'subtitle': response['dominantType'].toString().capitalize(),
        'image': response['image_url']
            .toString()
            .replaceAll('150x150', '500x500')
            .replaceAll('50x50', '500x500')
            .replaceAll('http:', 'https:'),
        'artistToken': response['perma_url'].toString().split('/').last,
        'perma_url': response['perma_url'].toString(),
      };
    } catch (e) {
      return {'Error': e};
    }
  }

  static Future<Map> formatSingleShowResponse(Map response) async {
    try {
      return {
        'id': response['id'],
        'type': response['type'],
        'album': response['title'].toString().unescape(),
        'subtitle': response['description'] == null
            ? response['subtitle'].toString().unescape()
            : response['description'].toString().unescape(),
        'title': response['title'].toString().unescape(),
        'image': response['image']
            .toString()
            .replaceAll('150x150', '500x500')
            .replaceAll('50x50', '500x500')
            .replaceAll('http:', 'https:'),
      };
    } catch (e) {
      return {'Error': e};
    }
  }

  static Future<Map> formatHomePageData(Map data) async {
    try {
      if (data['new_trending'] != null) {
        data['new_trending'] = await formatSongsInList(
          data['new_trending'] as List,
          fetchDetails: false,
        );
      }
      if (data['new_albums'] != null) {
        data['new_albums'] = await formatSongsInList(
          data['new_albums'] as List,
          fetchDetails: false,
        );
      }
      if (data['city_mod'] != null) {
        data['city_mod'] = await formatSongsInList(
          data['city_mod'] as List,
          fetchDetails: true,
        );
      }
      final List promoList = [];
      final List promoListTemp = [];
      data['modules'].forEach((k, v) {
        if (k.startsWith('promo') as bool) {
          if (data[k][0]['type'] == 'song' &&
              (data[k][0]['mini_obj'] as bool? ?? false)) {
            promoListTemp.add(k.toString());
          } else {
            promoList.add(k.toString());
          }
        }
      });
      for (int i = 0; i < promoList.length; i++) {
        data[promoList[i]] = await formatSongsInList(
          data[promoList[i]] as List,
          fetchDetails: false,
        );
      }
      data['collections'] = [
        'new_trending',
        'charts',
        'new_albums',
        'top_playlists',
        'radio',
        'city_mod',
        'artist_recos',
        ...promoList
      ];
      data['collections_temp'] = promoListTemp;
    } catch (e) {
      log('Error in formatHomePageData: $e');
    }
    return data;
  }

  static Future<Map> formatPromoLists(Map data) async {
    try {
      final List promoList = data['collections_temp'] as List;
      for (int i = 0; i < promoList.length; i++) {
        data[promoList[i]] = await formatSongsInList(
          data[promoList[i]] as List,
          fetchDetails: true,
        );
      }
      data['collections'].addAll(promoList);
      data['collections_temp'] = [];
    } catch (e) {
      log('Error in formatPromoLists: $e');
    }
    return data;
  }

  static Future<List> formatSongsInList(
    List list, {
    required bool fetchDetails,
  }) async {
    if (list.isNotEmpty) {
      for (int i = 0; i < list.length; i++) {
        final Map item = list[i] as Map;
        if (item['type'] == 'song') {
          if (item['mini_obj'] as bool? ?? false) {
            if (fetchDetails) {
              Map cachedDetails = Hive.box('cache')
                  .get(item['id'].toString(), defaultValue: {}) as Map;
              if (cachedDetails.isEmpty) {
                cachedDetails =
                    await SaavnAPI().fetchSongDetails(item['id'].toString());
                Hive.box('cache')
                    .put(cachedDetails['id'].toString(), cachedDetails);
              }
              list[i] = cachedDetails;
            }
            continue;
          }
          list[i] = await formatSingleSongResponse(item);
        }
      }
    }
    list.removeWhere((value) => value == null);
    return list;
  }
}
