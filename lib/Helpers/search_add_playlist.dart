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
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/Helpers/playlist.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// ignore: avoid_classes_with_only_static_members
class SearchAddPlaylist {
  static Future<Map> addYtPlaylist(String inLink) async {
    final String link = '$inLink&';
    try {
      final RegExpMatch? id = RegExp(r'.*list\=(.*?)&').firstMatch(link);
      if (id != null) {
        final Playlist metadata =
            await YouTubeServices().getPlaylistDetails(id[1]!);
        final List<Video> tracks =
            await YouTubeServices().getPlaylistSongs(id[1]!);
        return {
          'title': metadata.title,
          'image': metadata.thumbnails.standardResUrl,
          'author': metadata.author,
          'description': metadata.description,
          'tracks': tracks,
          'count': tracks.length,
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  static Stream<Map> songsAdder(String playName, List tracks) async* {
    int _done = 0;
    for (final track in tracks) {
      String? trackName;
      try {
        trackName = (track as Video).title;
        yield {'done': ++_done, 'name': trackName};
      } catch (e) {
        yield {'done': ++_done, 'name': ''};
      }
      try {
        final List result =
            await SaavnAPI().fetchTopSearchResult(trackName!.split('|')[0]);
        addMapToPlaylist(playName, result[0] as Map);
      } catch (e) {
        // print('Error in $_done: $e');
      }
    }
  }

  static Future<void> showProgress(
    int _total,
    BuildContext cxt,
    Stream songAdd,
  ) async {
    await showModalBottomSheet(
      isDismissible: false,
      backgroundColor: Colors.transparent,
      context: cxt,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStt) {
            return BottomGradientContainer(
              child: SizedBox(
                height: 300,
                width: 300,
                child: StreamBuilder<Object>(
                  stream: songAdd as Stream<Object>?,
                  builder: (ctxt, AsyncSnapshot snapshot) {
                    final Map? data = snapshot.data as Map?;
                    final int _done = (data ?? const {})['done'] as int? ?? 0;
                    final String name =
                        (data ?? const {})['name'] as String? ?? '';
                    if (_done == _total) Navigator.pop(ctxt);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Center(
                          child: Text(
                            AppLocalizations.of(context)!.convertingSongs,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(
                          height: 80,
                          width: 80,
                          child: Stack(
                            children: [
                              Center(
                                child: Text('$_done / $_total'),
                              ),
                              Center(
                                child: SizedBox(
                                  height: 77,
                                  width: 77,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(ctxt).colorScheme.secondary,
                                    ),
                                    value: _done / _total,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
