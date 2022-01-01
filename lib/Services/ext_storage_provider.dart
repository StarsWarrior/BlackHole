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
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// ignore: avoid_classes_with_only_static_members
class ExtStorageProvider {
  // asking for permission
  static Future<bool> requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      final result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  // getting external storage path
  static Future<String?> getExtStorage({required String dirName}) async {
    Directory? directory;

    try {
      // checking platform
      if (Platform.isAndroid) {
        if (await requestPermission(Permission.storage)) {
          directory = await getExternalStorageDirectory();

          // getting main path
          final String newPath = directory!.path
              .replaceFirst('Android/data/com.shadow.blackhole/files', dirName);

          directory = Directory(newPath);

          // checking if directory exist or not
          if (!await directory.exists()) {
            // if directory not exists then asking for permission to create folder
            await requestPermission(Permission.manageExternalStorage);
            //creating folder

            await directory.create(recursive: true);
          }
          if (await directory.exists()) {
            try {
              // if directory exists then returning the complete path
              return newPath;
            } catch (e) {
              rethrow;
            }
          }
        } else {
          return throw 'something went wrong';
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
        return directory.path;
      } else {
        directory = await getDownloadsDirectory();
        return directory!.path;
      }
    } catch (e) {
      rethrow;
    }
    return directory.path;
  }
}
