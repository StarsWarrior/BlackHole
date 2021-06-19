import 'dart:io';

import 'package:ext_storage/ext_storage.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class Picker {
  Future<String> selectFolder(BuildContext context, String message) async {
    PermissionStatus status = await Permission.storage.status;
    if (status.isRestricted || status.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      debugPrint(statuses[Permission.storage].toString());
    }
    status = await Permission.storage.status;
    if (status.isGranted) {
      String path = await ExtStorage.getExternalStorageDirectory();
      Directory rootPath = Directory(path);
      String temp = await FilesystemPicker.open(
            title: message ?? 'Select folder',
            context: context,
            rootDirectory: rootPath,
            fsType: FilesystemType.folder,
            pickText: 'Select this folder',
            folderIconColor: Theme.of(context).accentColor,
          ) ??
          '';
      return temp;
    }
    return '';
  }

  Future<String> selectFile(
      BuildContext context, List<String> ext, String message) async {
    PermissionStatus status = await Permission.storage.status;
    if (status.isRestricted || status.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();
      debugPrint(statuses[Permission.storage].toString());
    }
    status = await Permission.storage.status;
    if (status.isGranted) {
      String path = await ExtStorage.getExternalStorageDirectory();
      Directory rootPath = Directory(path);
      String temp = await FilesystemPicker.open(
            title: message ?? 'Select File',
            context: context,
            rootDirectory: rootPath,
            allowedExtensions: ext,
            fsType: FilesystemType.file,
            pickText: 'Select this file',
            folderIconColor: Theme.of(context).accentColor,
          ) ??
          '';
      return temp;
    }
    return '';
  }
}
