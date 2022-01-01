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

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Helpers/audio_query.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
    } else {
      if (int.tryParse(paths.last) != null) {
        return PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => OfflinePlayHandler(
            id: paths.last,
          ),
        );
      }
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
              songsList: value['songs'] as List,
              index: 0,
              offline: false,
              fromDownloads: false,
              recommend: true,
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
            ),
          ),
        );
      }
    });
    return Container();
  }
}

class OfflinePlayHandler extends StatelessWidget {
  final String id;
  const OfflinePlayHandler({Key? key, required this.id}) : super(key: key);

  Future<List> playOfflineSong(String id) async {
    final OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
    await offlineAudioQuery.requestPermission();

    final List<SongModel> songs = await offlineAudioQuery.getSongs();
    final int index = songs.indexWhere((i) => i.id.toString() == id);

    return [index, songs];
  }

  @override
  Widget build(BuildContext context) {
    playOfflineSong(id).then((value) {
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => PlayScreen(
            songsList: value[1] as List<SongModel>,
            index: value[0] as int,
            offline: true,
            fromDownloads: false,
            recommend: false,
            fromMiniplayer: false,
          ),
        ),
      );
    });
    return Container();
  }
}
