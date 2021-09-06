import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:flutter/material.dart';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';

class HandleRoute {
  Route? handleRoute(String? url) {
    final List<String> paths = url?.replaceAll('?', '/').split('/') ?? [];
    if (paths.isNotEmpty &&
        paths.length > 3 &&
        (paths[1] == 'song' || paths[1] == 'album' || paths[1] == 'featured') &&
        paths[3].trim() != '') {
      return PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => SongUrlHandler(
          token: paths[3],
          type: paths[1] == 'featured' ? 'playlist' : paths[1],
        ),
      );
    }

    return null;
  }
}

class SongUrlHandler extends StatelessWidget {
  final String token;
  final String type;
  const SongUrlHandler({Key? key, required this.token, required this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    SaavnAPI().getSongFromToken(token, type).then((value) {
      if (type == 'song') {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => PlayScreen(
              data: {
                'response': value['songs'],
                'index': 0,
                'offline': false,
              },
              fromMiniplayer: false,
            ),
          ),
        );
      }
      if (type == 'album' || type == 'playlist') {
        Navigator.push(
          context,
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => SongsListPage(
                    listItem: value,
                  )),
        );
      }
    });
    return Container();
  }
}
