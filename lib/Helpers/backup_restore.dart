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

import 'dart:io';

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> createBackup(
  BuildContext context,
  List items,
  Map<String, List> boxNameData, {
  String? path,
  String? fileName,
  bool showDialog = true,
}) async {
  if (!Platform.isWindows) {
    PermissionStatus status = await Permission.storage.status;
    if (status.isDenied) {
      await [
        Permission.storage,
        Permission.accessMediaLocation,
        Permission.mediaLibrary,
      ].request();
    }
    status = await Permission.storage.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }
  final String savePath = path ??
      await Picker.selectFolder(
        context: context,
        message: AppLocalizations.of(context)!.selectBackLocation,
      );
  if (savePath.trim() != '') {
    try {
      final saveDir = Directory(savePath);
      final List<File> files = [];
      final List boxNames = [];

      for (int i = 0; i < items.length; i++) {
        boxNames.addAll(boxNameData[items[i]]!);
      }

      for (int i = 0; i < boxNames.length; i++) {
        await Hive.openBox(boxNames[i].toString());
        try {
          await File(Hive.box(boxNames[i].toString()).path!)
              .copy('$savePath/${boxNames[i]}.hive');
        } catch (e) {
          await [
            Permission.manageExternalStorage,
          ].request();
          await File(Hive.box(boxNames[i].toString()).path!)
              .copy('$savePath/${boxNames[i]}.hive');
        }

        files.add(File('$savePath/${boxNames[i]}.hive'));
      }

      final now = DateTime.now();
      final String time =
          '${now.hour}${now.minute}_${now.day}${now.month}${now.year}';
      final zipFile =
          File('$savePath/${fileName ?? "BlackHole_Backup_$time"}.zip');

      await ZipFile.createFromFiles(
        sourceDir: saveDir,
        files: files,
        zipFile: zipFile,
      );
      for (int i = 0; i < files.length; i++) {
        files[i].delete();
      }
      if (showDialog) {
        ShowSnackBar().showSnackBar(
          context,
          AppLocalizations.of(context)!.backupSuccess,
        );
      }
    } catch (e) {
      ShowSnackBar().showSnackBar(
        context,
        '${AppLocalizations.of(context)!.failedCreateBackup}\nError: $e',
      );
    }
  } else {
    ShowSnackBar().showSnackBar(
      context,
      AppLocalizations.of(context)!.noFolderSelected,
    );
  }
}

Future<void> restore(
  BuildContext context,
) async {
  final String savePath = await Picker.selectFile(
    context: context,
    ext: ['zip'],
    message: AppLocalizations.of(context)!.selectBackFile,
  );
  final File zipFile = File(savePath);
  final Directory tempDir = await getTemporaryDirectory();
  final Directory destinationDir = Directory('${tempDir.path}/restore');

  try {
    await ZipFile.extractToDirectory(
      zipFile: zipFile,
      destinationDir: destinationDir,
    );
    final List<FileSystemEntity> files = await destinationDir.list().toList();

    for (int i = 0; i < files.length; i++) {
      final String backupPath = files[i].path;
      final String boxName = backupPath.split('/').last.replaceAll('.hive', '');
      final Box box = await Hive.openBox(boxName);
      final String boxPath = box.path!;
      await box.close();

      try {
        await File(backupPath).copy(boxPath);
      } finally {
        await Hive.openBox(boxName);
      }
    }
    destinationDir.delete(recursive: true);
    ShowSnackBar()
        .showSnackBar(context, AppLocalizations.of(context)!.importSuccess);
  } catch (e) {
    ShowSnackBar().showSnackBar(
      context,
      '${AppLocalizations.of(context)!.failedImport}\nError: $e',
    );
  }
}
