import 'dart:convert';
import 'dart:io';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Helpers/songs_count.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ExportPlaylist {
  void exportPlaylist(BuildContext context, String playlistName) async {
    String temp = await Picker().selectFolder(context);
    if (temp == '') return;
    await Hive.openBox(playlistName);
    Box playlistBox = Hive.box(playlistName);
    Map _songsMap = playlistBox?.toMap();
    String _songs = json.encode(_songsMap);
    File file =
        await File(temp + "/" + playlistName + '.json').create(recursive: true);
    await file.writeAsString(_songs.toString());
  }
}

class ImportPlaylist {
  Future<List> importPlaylist(BuildContext context, List playlistNames) async {
    try {
      String temp = await Picker().selectFile(context, ['.json']);
      if (temp == '') return playlistNames;

      String playlistName = temp.split('/').last.split('.json').first;
      File file = File(temp);
      String finString = await file.readAsString();
      final Map _songsMap = json.decode(finString);
      List _songs = _songsMap.values.toList();
      // playlistBox.put(mediaItem.id.toString(), info);
      // Hive.box(play)

      if (playlistName.trim() == '')
        playlistName = 'Playlist ${playlistNames.length}';
      if (playlistNames.contains(playlistName))
        playlistName = playlistName + ' (1)';
      playlistNames.add(playlistName);

      await Hive.openBox(playlistName);
      Box playlistBox = Hive.box(playlistName);
      await playlistBox.putAll(_songsMap);

      AddSongsCount().addSong(
        playlistName,
        _songs.length,
        _songs.length >= 4
            ? _songs.sublist(0, 4)
            : _songs.sublist(0, _songs.length),
      );
      return playlistNames;
    } catch (e) {
      print("Error in Import: $e");
    }
    return playlistNames;
  }
}
