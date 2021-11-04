import 'dart:io';

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class BackupNRestore {
  Future<void> createBackup(
    BuildContext context,
    List items,
    Map<String, List> boxNameData,
  ) async {
    final String savePath = await Picker().selectFolder(
      context,
      AppLocalizations.of(context)!.selectBackLocation,
    );
    if (savePath.trim() != '') {
      final saveDir = Directory(savePath);
      final List<File> files = [];
      final List boxNames = [];

      for (int i = 0; i < items.length; i++) {
        boxNames.addAll(boxNameData[items[i]]!);
      }

      for (int i = 0; i < boxNames.length; i++) {
        await Hive.openBox(boxNames[i].toString());

        await File(Hive.box(boxNames[i].toString()).path!)
            .copy('$savePath/${boxNames[i]}.hive');

        files.add(File('$savePath/${boxNames[i]}.hive'));
      }

      final now = DateTime.now();
      final String time =
          '${now.hour}${now.minute}_${now.day}${now.month}${now.year}';
      final zipFile = File('$savePath/BlackHole_Backup_$time.zip');

      await ZipFile.createFromFiles(
        sourceDir: saveDir,
        files: files,
        zipFile: zipFile,
      );
      for (int i = 0; i < files.length; i++) {
        files[i].delete();
      }
      ShowSnackBar()
          .showSnackBar(context, AppLocalizations.of(context)!.backupSuccess);
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
    final String savePath = await Picker().selectFile(
      context,
      ['zip'],
      AppLocalizations.of(context)!.selectBackFile,
    );
    final File zipFile = File(savePath);
    final Directory tempDir = await getTemporaryDirectory();
    final Directory destinationDir = Directory('${tempDir.path}/restore');

    try {
      ZipFile.extractToDirectory(
        zipFile: zipFile,
        destinationDir: destinationDir,
      );
      final List<FileSystemEntity> files = await destinationDir.list().toList();

      for (int i = 0; i < files.length; i++) {
        final String backupPath = files[i].path;
        final String boxName =
            backupPath.split('/').last.replaceAll('.hive', '');
        final Box box = await Hive.openBox(boxName);
        final String boxPath = box.path!;
        await box.close();

        try {
          File(backupPath).copy(boxPath);
        } finally {
          await Hive.openBox(boxName);
        }
      }
      destinationDir.delete(recursive: true);
      ShowSnackBar()
          .showSnackBar(context, AppLocalizations.of(context)!.importSuccess);
    } catch (e) {
      ShowSnackBar()
          .showSnackBar(context, AppLocalizations.of(context)!.failedImport);
    }
  }
}
