import 'dart:convert';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:http/http.dart';

class Lyrics {
  Future<String> getSaavnLyrics(String id) async {
    final Uri lyricsUrl = Uri.https('www.jiosaavn.com',
        '/api.php?__call=lyrics.getLyrics&lyrics_id=$id&ctx=web6dot0&api_version=4&_format=json');
    final Response res =
        await get(lyricsUrl, headers: {'Accept': 'application/json'});

    final List<String> rawLyrics = res.body.split('-->');
    final fetchedLyrics = json.decode(rawLyrics[1]);
    final String lyrics =
        fetchedLyrics['lyrics'].toString().replaceAll('<br>', '\n');
    return lyrics;
  }

  Future<String> getOffLyrics(String path) async {
    final Audiotagger tagger = Audiotagger();
    final Tag? tags = await tagger.readTags(path: path);
    return tags?.lyrics ?? '';
  }

  Future<String> getLyricsLink(String song, String artist) async {
    const String authority = 'www.musixmatch.com';
    final String unencodedPath = '/search/$song $artist';
    final Response res = await get(Uri.https(authority, unencodedPath));
    if (res.statusCode != 200) return '';
    final RegExpMatch? result =
        RegExp(r'href=\"(\/lyrics\/.*?)\"').firstMatch(res.body);
    return result == null ? '' : result[1]!;
  }

  Future<String> scrapLink(String unencodedPath) async {
    const String authority = 'www.musixmatch.com';
    final Response res = await get(Uri.https(authority, unencodedPath));
    if (res.statusCode != 200) return '';
    final List<String?> lyrics = RegExp(
            r'<span class=\"lyrics__content__ok\">(.*?)<\/span>',
            dotAll: true)
        .allMatches(res.body)
        .map((m) => m[1])
        .toList();

    return lyrics.isEmpty ? '' : lyrics.join('\n');
  }

  Future<String> getLyrics(String title, String artist) async {
    final String link = await getLyricsLink(title, artist);
    final String lyrics = await scrapLink(link);
    return lyrics;
  }
}
