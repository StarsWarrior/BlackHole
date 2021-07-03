import 'package:http/http.dart';

class Lyrics {
  Future<String> getLyricsLink(String song, String artist) async {
    String authority = "www.musixmatch.com";
    String unencodedPath = '/search/' + song + ' ' + artist;
    Response res = await get(Uri.https(authority, unencodedPath));
    if (res.statusCode != 200) return '';
    RegExpMatch result =
        RegExp(r'href=\"(\/lyrics\/.*?)\"').firstMatch(res.body);
    return result == null ? '' : result[1];
  }

  Future<String> scrapLink(String unencodedPath) async {
    String authority = "www.musixmatch.com";
    Response res = await get(Uri.https(authority, unencodedPath));
    if (res.statusCode != 200) return '';
    List<String> lyrics = RegExp(
            r'<span class=\"lyrics__content__ok\">(.*?)<\/span>',
            dotAll: true)
        .allMatches(res.body)
        .map((m) => m[1])
        .toList();

    return lyrics == null ? '' : lyrics.join('\n');
  }

  Future<String> getLyrics(String title, String artist) async {
    String link = await getLyricsLink(title, artist);
    String lyrics = await scrapLink(link);
    return lyrics ?? '';
  }
}
