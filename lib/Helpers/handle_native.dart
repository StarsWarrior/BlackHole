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

import 'package:blackhole/Helpers/route_handler.dart';
import 'package:flutter/material.dart';

Future<void> handleSharedText(String sharedText, BuildContext context) async {
  // print(sharedText);
  // TODO: ADD SUPPORT FOR ALL SAAVN, YOUTUBE AND SPOTIFY LINKS
  if (sharedText.contains('saavn')) {
    final RegExpMatch? songResult =
        RegExp(r'.*saavn.com.*?\/(song)\/.*?\/(.*)').firstMatch('$sharedText?');
    if (songResult != null) {
      // print('Its a song');
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => SaavnUrlHandler(
            token: songResult[2]!,
            type: songResult[1]!,
          ),
        ),
      );
    } else {
      final RegExpMatch? playlistResult =
          RegExp(r'.*saavn.com\/?s?\/(featured|playlist|album)\/.*\/(.*_)?[?/]')
              .firstMatch('$sharedText?');
      if (playlistResult != null) {
        // print('Its a ${playlistResult[1]} with id: ${splaylistResult[2]!}');
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => SaavnUrlHandler(
              token: playlistResult[2]!,
              type: playlistResult[1]!,
            ),
          ),
        );
      }
    }
  } else if (sharedText.contains('spotify')) {
    // print('it is a spotify link');
  } else if (sharedText.contains('youtube')) {
    // print('it is a youtube link');
  }
}
