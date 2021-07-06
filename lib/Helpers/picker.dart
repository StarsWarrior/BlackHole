import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class Picker {
  Future<String> selectFolder(BuildContext context, String message) async {
    String temp = await FilePicker.platform.getDirectoryPath();
    return (temp == '/' || temp == null) ? '' : temp;
  }

  Future<String> selectFile(
      BuildContext context, List<String> ext, String message) async {
    FilePickerResult result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ext);

    if (result != null) {
      File file = File(result.files.first.path);
      return file.path == '/' ? '' : file.path;
    }
    return '';
  }
}
