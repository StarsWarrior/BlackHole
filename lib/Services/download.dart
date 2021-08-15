import 'dart:io';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:blackhole/Helpers/lyrics.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class Download with ChangeNotifier {
  String preferredDownloadQuality =
      Hive.box('settings').get('downloadQuality') ?? '320 kbps';
  String downloadFormat = 'm4a';
  // Hive.box('settings').get('downloadFormat', defaultValue: 'm4a');
  double progress = 0.0;
  String currentDownloadId = '';
  String lastDownloadId = '';
  String dlPath = Hive.box('settings').get('downloadPath', defaultValue: '');
  bool downloadLyrics =
      Hive.box('settings').get('downloadLyrics', defaultValue: false);

  Future<String> getLyrics(Map data) async {
    if (data["has_lyrics"] == "true") {
      return Lyrics().getSaavnLyrics(data["id"]);
    } else {
      return Lyrics()
          .getLyrics(data['title'].toString(), data['artist'].toString());
    }
  }

  Future<void> prepareDownload(BuildContext context, Map data) async {
    if (!Platform.isWindows) {
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
    }
    RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    data['title'] = data['title'].toString().split("(From")[0].trim();
    String filename = data['title'] + " - " + data['artist'];

    if (filename.length > 200) {
      String temp = filename.substring(0, 200);
      List tempList = temp.split(", ");
      tempList.removeLast();
      filename = tempList.join(", ");
    }

    filename = filename.replaceAll(avoid, "").replaceAll("  ", " ") + ".m4a";
    if (dlPath == '') {
      if (Platform.isWindows) {
        Directory temp = await getDownloadsDirectory();
        dlPath = temp.path;
      } else
        dlPath = await ExtStorage.getExternalStoragePublicDirectory(
            ExtStorage.DIRECTORY_MUSIC);
    }

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
                Container(
                  width: 400,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '"${data['title']}" already exists.\nDo you want to download it again?',
                        softWrap: true,
                      ),
                    ],
                  ),
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
                child: Text(
                  "No",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  lastDownloadId = data['id'];
                  Navigator.pop(context);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  primary: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey[700],
                ),
                child: Text("Yes, but Replace Old"),
                onPressed: () async {
                  Navigator.pop(context);
                  downloadSong(context, dlPath, filename, data);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  primary: Colors.white,
                  backgroundColor: Theme.of(context).accentColor,
                ),
                child: Text("Yes"),
                onPressed: () async {
                  Navigator.pop(context);
                  while (await File(dlPath + "/" + filename).exists()) {
                    filename = filename.replaceAll('.m4a', ' (1).m4a');
                  }
                  downloadSong(context, dlPath, filename, data);
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

  Future<void> downloadSong(
      BuildContext context, String dlPath, String filename, Map data) async {
    ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);
    progress = null;
    notifyListeners();
    String filepath;
    String filepath2;
    String appPath;
    List<int> _bytes = [];
    String lyrics;
    final artname = filename.replaceAll(".m4a", "artwork.jpg");
    if (!Platform.isWindows) {
      Directory appDir = await getApplicationDocumentsDirectory();
      appPath = appDir.path;
    } else {
      Directory temp = await getDownloadsDirectory();
      appPath = temp.path;
    }
    if (data['url'].toString().contains('google')) {
      filename = filename.replaceAll('.m4a', '.weba');
    }
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
    try {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          elevation: 6,
          backgroundColor: Colors.grey[900],
          behavior: SnackBarBehavior.floating,
          content: Text(
            filepath.endsWith('.weba')
                ? 'Downloading "${data['title'].toString()}" in Best Quality Available'
                : 'Downloading "${data['title'].toString()}" in $preferredDownloadQuality',
            style: TextStyle(color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          action: SnackBarAction(
            textColor: Theme.of(context).accentColor,
            label: 'Ok',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      print("Failed to show Snackbar: $e");
    }

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
      try {
        lyrics = downloadLyrics ? await getLyrics(data) : '';
      } catch (e) {
        print('Error fetching lyrics: $e');
        lyrics = '';
      }

      if (filepath.endsWith('.weba')) {
        List<String> _argsList;

        scaffoldMessenger.showSnackBar(SnackBar(
          elevation: 6,
          backgroundColor: Colors.grey[900],
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Converting "weba" to "$downloadFormat"',
            style: TextStyle(color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          action: SnackBarAction(
            textColor: Theme.of(context).accentColor,
            label: 'Ok',
            onPressed: () {},
          ),
        ));

        // if (downloadFormat == 'mp3')
        //   _argsList = [
        //     "-y",
        //     "-i",
        //     "$filepath",
        //     "-c:a",
        //     "libmp3lame",
        //     "-b:a",
        //     "256k",
        //     "${filepath.replaceAll('.weba', '.mp3')}"
        //   ];
        if (downloadFormat == 'm4a')
          _argsList = [
            "-y",
            "-i",
            "$filepath",
            "-c:a",
            "aac",
            "-b:a",
            "256k",
            "${filepath.replaceAll('.weba', '.m4a')}"
          ];
        await FlutterFFmpeg().executeWithArguments(_argsList);

        filepath = filepath.replaceAll(".weba", ".$downloadFormat");
      }

      debugPrint("Started tag editing");
      final Tag tag = Tag(
        title: data['title'],
        artist: data['artist'],
        albumArtist:
            data['album_artist'] ?? data['artist'].toString()?.split(', ')[0],
        artwork: filepath2.toString(),
        album: data['album'],
        genre: data['language'],
        year: data['year'],
        lyrics: lyrics,
        comment: 'BlackHole',
      );
      try {
        final tagger = Audiotagger();
        await tagger.writeTags(
          path: filepath,
          tag: tag,
        );
        await Future.delayed(const Duration(seconds: 1), () {});
        if (await file2.exists()) {
          await file2.delete();
        }
      } catch (e) {
        print("Failed to edit tags");
      }
      debugPrint("Done");
      lastDownloadId = data['id'];
      progress = 0.0;
      notifyListeners();

      scaffoldMessenger.showSnackBar(SnackBar(
        elevation: 6,
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        content: Text(
          '"${data['title'].toString()}" has been downloaded',
          style: TextStyle(color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          textColor: Theme.of(context).accentColor,
          label: 'Ok',
          onPressed: () {},
        ),
      ));
    });
  }
}
