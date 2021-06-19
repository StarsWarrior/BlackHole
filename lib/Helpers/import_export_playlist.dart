import 'dart:convert';
import 'dart:io';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Helpers/songs_count.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ExportPlaylist {
  void exportPlaylist(BuildContext context, String playlistName) async {
    String temp =
        await Picker().selectFolder(context, 'Select Export Location');
    if (temp == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 6,
          backgroundColor: Colors.grey[900],
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed to Export "$playlistName"',
            style: TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            textColor: Theme.of(context).accentColor,
            label: 'Ok',
            onPressed: () {},
          ),
        ),
      );
      return;
    }
    await Hive.openBox(playlistName);
    Box playlistBox = Hive.box(playlistName);
    Map _songsMap = playlistBox?.toMap();
    String _songs = json.encode(_songsMap);
    File file =
        await File(temp + "/" + playlistName + '.json').create(recursive: true);
    await file.writeAsString(_songs.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Exported "$playlistName"',
          style: TextStyle(color: Colors.white),
        ),
        action: SnackBarAction(
          textColor: Theme.of(context).accentColor,
          label: 'Ok',
          onPressed: () {},
        ),
      ),
    );
  }
}

class ImportPlaylist {
  Future<List> importPlaylist(BuildContext context, List playlistNames) async {
    try {
      String temp = await Picker()
          .selectFile(context, ['.json'], 'Select json file to import');
      if (temp == '') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 6,
            backgroundColor: Colors.grey[900],
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Failed to import playlist',
              style: TextStyle(color: Colors.white),
            ),
            action: SnackBarAction(
              textColor: Theme.of(context).accentColor,
              label: 'Ok',
              onPressed: () {},
            ),
          ),
        );
        return playlistNames;
      }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 6,
          backgroundColor: Colors.grey[900],
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Successfully Imported "$playlistName"',
            style: TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            textColor: Theme.of(context).accentColor,
            label: 'Ok',
            onPressed: () {},
          ),
        ),
      );
      return playlistNames;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 6,
          backgroundColor: Colors.grey[900],
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed to import playlist',
            style: TextStyle(color: Colors.white),
          ),
          action: SnackBarAction(
            textColor: Theme.of(context).accentColor,
            label: 'Ok',
            onPressed: () {},
          ),
        ),
      );
      print("Error in Import: $e");
    }
    return playlistNames;
  }
}
