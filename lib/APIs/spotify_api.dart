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

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';

class SpotifyApi {
  final List<String> _scopes = [
    'user-read-private',
    'user-read-email',
    'playlist-read-private',
    'playlist-read-collaborative',
  ];

  /// You can signup for spotify developer account and get your own clientID and clientSecret incase you don't want to use these
  final String clientID = '08de4eaf71904d1b95254fab3015d711';
  final String clientSecret = '622b4fbad33947c59b95a6ae607de11d';
  final String redirectUrl = 'app://blackhole/auth';
  final String spotifyApiBaseUrl = 'https://accounts.spotify.com/api';
  final String spotifyPlaylistBaseUrl =
      'https://api.spotify.com/v1/me/playlists';
  final String spotifyTrackBaseUrl = 'https://api.spotify.com/v1/playlists';
  final String spotifyBaseUrl = 'https://accounts.spotify.com';
  final String requestToken = 'https://accounts.spotify.com/api/token';

  String requestAuthorization() =>
      'https://accounts.spotify.com/authorize?client_id=$clientID&response_type=code&redirect_uri=$redirectUrl&scope=${_scopes.join('%20')}';

  // Future<String> authenticate() async {
  //   final url = SpotifyApi().requestAuthorization();
  //   final callbackUrlScheme = 'accounts.spotify.com';

  //   try {
  //     final result = await FlutterWebAuth.authenticate(
  //         url: url, callbackUrlScheme: callbackUrlScheme);
  // print('got result....');
  // print(result);
  //     return result;
  //   } catch (e) {
  // print('Got error: $e');
  //     return 'ERROR';
  //   }
  // }

  Future<List<String>> getAccessToken(String code) async {
    final Map<String, String> headers = {
      'Authorization':
          "Basic ${base64.encode(utf8.encode("$clientID:$clientSecret"))}",
    };

    final Map<String, String> body = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUrl
    };

    try {
      final Uri path = Uri.parse(requestToken);
      final response = await post(path, headers: headers, body: body);
      // print(response.statusCode);
      if (response.statusCode == 200) {
        final Map result = jsonDecode(response.body) as Map;
        return <String>[
          result['access_token'].toString(),
          result['refresh_token'].toString()
        ];
      }
    } catch (e) {
      // print('Error: $e');
    }
    return [];
  }

  Future<List> getUserPlaylists(String accessToken) async {
    try {
      final Uri path = Uri.parse('$spotifyPlaylistBaseUrl?limit=50');

      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List playlists = result['items'] as List;
        return playlists;
      }
    } catch (e) {
      // print('Error: $e');
    }
    return [];
  }

  Future<Map> getTracksOfPlaylist(
    String accessToken,
    String playListId,
    int offset,
  ) async {
    try {
      final Uri path = Uri.parse(
        '$spotifyTrackBaseUrl/$playListId/tracks?limit=100&offset=$offset',
      );
      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List tracks = result['items'] as List;
        final int total = result['total'] as int;
        return {'tracks': tracks, 'total': total};
      }
    } catch (e) {
      // print('Error: $e');
    }
    return {};
  }
}
