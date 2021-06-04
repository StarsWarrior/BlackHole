import 'dart:io';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Download with ChangeNotifier {
  String preferredDownloadQuality =
      Hive.box('settings').get('downloadQuality') ?? '320 kbps';
  double progress = 0.0;
  String currentDownloadId = '';
  String lastDownloadId = '';

  prepareDownload(BuildContext context, Map data) async {
    PermissionStatus status = await Permission.storage.status;
    if (status.isPermanentlyDenied || status.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.accessMediaLocation,
        Permission.mediaLibrary,
      ].request();
      debugPrint(statuses[Permission.storage].toString());
    }
    status = await Permission.storage.status;
    if (status.isGranted) {
      print('permission granted');
    }
    final String filename = data['title'] + " - " + data['artist'] + ".m4a";
    String dlPath = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_MUSIC);
    bool exists = await File(dlPath + "/" + filename).exists();
    if (exists) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Already Exists",
              style: TextStyle(color: Theme.of(context).accentColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Do you want to download it again?',
                      // style: TextStyle(color: Theme.of(context).accentColor),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  primary: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[700],
                ),
                child: Text("Yes"),
                onPressed: () {
                  Navigator.pop(context);
                  downloadSong(context, dlPath, filename, data);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  primary: Theme.of(context).accentColor,
                  backgroundColor: Theme.of(context).accentColor,
                ),
                child: Text(
                  "No",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(
                width: 5,
              ),
            ],
          );
        },
      );
    } else {
      downloadSong(context, dlPath, filename, data);
    }
  }

  downloadSong(
      BuildContext context, String dlPath, String filename, Map data) async {
    progress = null;
    notifyListeners();
    String filepath;
    String filepath2;
    List<int> _bytes = [];
    final artname = data['title'] + "artwork.jpg";
    Directory appDir = await getApplicationDocumentsDirectory();
    String appPath = appDir.path;
    try {
      await File(dlPath + "/" + filename)
          .create(recursive: true)
          .then((value) => filepath = value.path);
      print("created audio file");
      await File(appPath + "/" + artname)
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    } catch (e) {
      await [
        Permission.manageExternalStorage,
      ].request();
      await File(dlPath + "/" + filename)
          .create(recursive: true)
          .then((value) => filepath = value.path);
      print("created audio file");
      await File(appPath + "/" + artname)
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    }
    debugPrint('Audio path $filepath');
    debugPrint('Image path $filepath2');
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     elevation: 6,
    //     backgroundColor: Colors.grey[900],
    //     behavior: SnackBarBehavior.floating,
    //     content: Text(
    //       'Downloading your song in $preferredDownloadQuality',
    //       style: TextStyle(color: Colors.white),
    //     ),
    //     action: SnackBarAction(
    //       textColor: Theme.of(context).accentColor,
    //       label: 'Ok',
    //       onPressed: () {},
    //     ),
    //   ),
    // );
    String kUrl = data['url'].replaceAll(
        "_96.", "_${preferredDownloadQuality.replaceAll(' kbps', '')}.");
    final response = await Client().send(Request('GET', Uri.parse(kUrl)));
    int total = response.contentLength ?? 0;
    int recieved = 0;
    response.stream.asBroadcastStream();
    response.stream.listen((value) {
      _bytes.addAll(value);
      try {
        recieved += value.length;
        progress = recieved / total;
        notifyListeners();
      } catch (e) {}
    }).onDone(() async {
      final file = File("${(filepath)}");
      await file.writeAsBytes(_bytes);

      HttpClientRequest request2 =
          await HttpClient().getUrl(Uri.parse(data['image']));
      HttpClientResponse response2 = await request2.close();
      final bytes2 = await consolidateHttpClientResponseBytes(response2);
      File file2 = File(filepath2);

      await file2.writeAsBytes(bytes2);
      debugPrint("Started tag editing");

      final Tag tag = Tag(
        title: data['title'],
        artist: data['artist'],
        artwork: filepath2.toString(),
        album: data['album'],
        genre: data['language'],
        year: data['year'],
        comment: 'BlackHole',
      );

      final tagger = Audiotagger();
      await tagger.writeTags(
        path: filepath,
        tag: tag,
      );
      await Future.delayed(const Duration(seconds: 1), () {});
      if (await file2.exists()) {
        await file2.delete();
      }
      debugPrint("Done");
      lastDownloadId = data['id'];
      progress = 0.0;
      notifyListeners();

      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   elevation: 6,
      //   backgroundColor: Colors.grey[900],
      //   behavior: SnackBarBehavior.floating,
      //   content: Text(
      //     '"${mediaItem.title.toString()}" has been downloaded',
      //     style: TextStyle(color: Colors.white),
      //   ),
      //   action: SnackBarAction(
      //     textColor: Theme.of(context).accentColor,
      //     label: 'Ok',
      //     onPressed: () {},
      //   ),
      // ));
    });
  }
}
