import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// ignore: avoid_classes_with_only_static_members
class Picker {
  static Future<String> selectFolder(
    BuildContext context,
    String message,
  ) async {
    final String? temp = await FilePicker.platform.getDirectoryPath();
    return (temp == '/' || temp == null) ? '' : temp;
  }

  static Future<String> selectFile(
    BuildContext context,
    List<String> ext,
    String message,
  ) async {
    final FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ext);

    if (result != null) {
      final File file = File(result.files.first.path!);
      return file.path == '/' ? '' : file.path;
    }
    return '';
  }
}
