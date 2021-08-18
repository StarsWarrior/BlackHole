import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Helpers/songs_count.dart';

class ExportPlaylist {
  Future<void> exportPlaylist(
      BuildContext context, String playlistName, String showName) async {
    final String dirPath =
        await Picker().selectFolder(context, 'Select Export Location');
    if (dirPath == '') {
      ShowSnackBar().showSnackBar(
        context,
        'Failed to Export "$showName"',
      );
      return;
    }
    await Hive.openBox(playlistName);
    final Box playlistBox = Hive.box(playlistName);
    final Map _songsMap = playlistBox.toMap();
    final String _songs = json.encode(_songsMap);
    final File file =
        await File('$dirPath/$showName.json').create(recursive: true);
    await file.writeAsString(_songs);
    ShowSnackBar().showSnackBar(
      context,
      'Exported "$showName"',
    );
  }

  Future<void> sharePlaylist(
      BuildContext context, String playlistName, String showName) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String temp = appDir.path;

    await Hive.openBox(playlistName);
    final Box playlistBox = Hive.box(playlistName);
    final Map _songsMap = playlistBox.toMap();
    final String _songs = json.encode(_songsMap);
    final File file =
        await File('$temp/$showName.json').create(recursive: true);
    await file.writeAsString(_songs.toString());

    await Share.shareFiles([file.path], text: 'Have a look at my playlist!');
    await Future.delayed(const Duration(seconds: 10), () {});
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class ImportPlaylist {
  Future<List> importPlaylist(BuildContext context, List playlistNames) async {
    try {
      final String temp = await Picker()
          .selectFile(context, ['json'], 'Select json file to import');
      if (temp == '') {
        ShowSnackBar().showSnackBar(
          context,
          'Failed to import playlist',
        );
        return playlistNames;
      }

      String playlistName = temp.split('/').last.split('.json').first;
      final File file = File(temp);
      final String finString = await file.readAsString();
      final Map _songsMap = json.decode(finString) as Map;
      final List _songs = _songsMap.values.toList();
      // playlistBox.put(mediaItem.id.toString(), info);
      // Hive.box(play)

      if (playlistName.trim() == '') {
        playlistName = 'Playlist ${playlistNames.length}';
      }
      if (playlistNames.contains(playlistName)) {
        playlistName = '$playlistName (1)';
      }
      playlistNames.add(playlistName);

      await Hive.openBox(playlistName);
      final Box playlistBox = Hive.box(playlistName);
      await playlistBox.putAll(_songsMap);

      AddSongsCount().addSong(
        playlistName,
        _songs.length,
        _songs.length >= 4
            ? _songs.sublist(0, 4)
            : _songs.sublist(0, _songs.length),
      );
      ShowSnackBar().showSnackBar(
        context,
        'Successfully Imported "$playlistName"',
      );
      return playlistNames;
    } catch (e) {
      ShowSnackBar().showSnackBar(
        context,
        'Failed to import playlist',
      );
    }
    return playlistNames;
  }
}
