import 'dart:io';

import 'package:blackhole/APIs/api.dart';
import 'package:http/http.dart';

Future<void> getArtistImage({
  required String name,
  required String tempDirPath,
}) async {
  if (tempDirPath == '') return;
  final imageFile = File('$tempDirPath/images/artists/$name.jpg');
  if (!await imageFile.exists()) {
    final result = await SaavnAPI().fetchAlbums(
      searchQuery: name,
      type: 'artist',
      count: 1,
    );
    if (result.isNotEmpty && result[0]['title'].toString() == name) {
      final Uri url = Uri.parse(result[0]['image'].toString());
      final response = await get(url);
      await imageFile.create(recursive: true);
      imageFile.writeAsBytesSync(response.bodyBytes);
    }
  }
}
