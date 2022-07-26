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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// ignore: avoid_classes_with_only_static_members
class Picker {
  static Future<String> selectFolder({
    required BuildContext context,
    String? message,
  }) async {
    final String? temp =
        await FilePicker.platform.getDirectoryPath(dialogTitle: message);
    return (temp == '/' || temp == null) ? '' : temp;
  }

  static Future<String> selectFile({
    required BuildContext context,
    // List<String>? ext,
    String? message,
  }) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      // allowedExtensions: ext,
      dialogTitle: message,
    );

    if (result != null) {
      final File file = File(result.files.first.path!);
      return file.path == '/' ? '' : file.path;
    }
    return '';
  }
}
