import 'dart:convert';
import 'package:http/http.dart';
// import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'dart:async';

class SpotifyApi {
  static List<String> _scopes = [
    'user-read-private',
    'user-read-email',
    'playlist-read-private',
    'playlist-read-collaborative',
  ];

  /// You can signup for spotify developer account and get your own clientID and clientSecret incase you don't want to use these
  final String clientID = "3700bda2626e4dfd8ff48dec5812e576";
  final String clientSecret = "221b0159b0284fd8a8697eb65baffcc4";
  final String redirectUrl = "http://127.0.0.1:43019/redirect";
  final String spotifyApiBaseUrl = "https://accounts.spotify.com/api";
  final String spotifyPlaylistBaseUrl =
      "https://api.spotify.com/v1/me/playlists";
  final String spotifyTrackBaseUrl = "https://api.spotify.com/v1/playlists";
  final String spotifyBaseUrl = "https://accounts.spotify.com";
  final String requestToken = 'https://accounts.spotify.com/api/token';

  String requestAuthorization() =>
      'https://accounts.spotify.com/authorize?client_id=$clientID&response_type=code&redirect_uri=$redirectUrl&scope=${_scopes.join('%20')}';

  // Future<String> authenticate() async {
  //   final url = SpotifyApi().requestAuthorization();
  //   final callbackUrlScheme = 'accounts.spotify.com';

  //   try {
  //     final result = await FlutterWebAuth.authenticate(
  //         url: url, callbackUrlScheme: callbackUrlScheme);
  //     print('got result....');
  //     print(result);
  //     return result;
  //   } catch (e) {
  //     print('Got error: $e');
  //     return 'ERROR';
  //   }
  // }

  Future<List<String>> getAccessToken(String code) async {
    Map<String, String> headers = {
      'Authorization':
          "Basic " + base64.encode(utf8.encode("$clientID:$clientSecret")),
    };

    Map<String, String> body = {
      'grant_type': 'authorization_code',
      'code': '$code',
      'redirect_uri': '$redirectUrl'
    };

    try {
      Uri path = Uri.parse(requestToken);
      final response = await post(path, headers: headers, body: body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return <String>[result['access_token'], result['refresh_token']];
      }
    } catch (e) {
      print('error ' + e.toString());
    }
    return [];
  }

  Future<List> getUserPlaylists(String accessToken) async {
    try {
      Uri path = Uri.parse("$spotifyPlaylistBaseUrl?limit=50");

      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        List playlists = result['items'];
        return playlists;
      }
    } catch (e) {
      print('error ' + e.toString());
    }
    return [];
  }

  Future<List> getTracksOfPlaylist(
      String accessToken, String playListId, int offset) async {
    try {
      Uri path = Uri.parse(
          "$spotifyTrackBaseUrl/$playListId/tracks?limit=100&offset=$offset");
      final response = await get(
        path,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        List tracks = result['items'].toList();
        return tracks;
      }
    } catch (e) {
      print('error ' + e.toString());
    }
    return [];
  }
}
