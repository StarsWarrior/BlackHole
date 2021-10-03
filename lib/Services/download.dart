import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/lyrics.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Download with ChangeNotifier {
  int? rememberOption;
  final ValueNotifier<bool> remember = ValueNotifier<bool>(false);
  String preferredDownloadQuality = Hive.box('settings')
      .get('downloadQuality', defaultValue: '320 kbps') as String;
  String downloadFormat = 'm4a';
  // Hive.box('settings').get('downloadFormat', defaultValue: 'm4a');
  bool createDownloadFolder = Hive.box('settings')
      .get('createDownloadFolder', defaultValue: false) as bool;
  bool createYoutubeFolder = Hive.box('settings')
      .get('createYoutubeFolder', defaultValue: false) as bool;
  double? progress = 0.0;
  String lastDownloadId = '';
  bool downloadLyrics =
      Hive.box('settings').get('downloadLyrics', defaultValue: false) as bool;
  bool download = true;

  Future<String> getLyrics(Map data) async {
    if (data['has_lyrics'] == 'true') {
      return Lyrics().getSaavnLyrics(data['id'].toString());
    } else {
      return Lyrics()
          .getLyrics(data['title'].toString(), data['artist'].toString());
    }
  }

  Future<void> prepareDownload(BuildContext context, Map data,
      {bool createFolder = false, String? folderName}) async {
    download = true;
    if (!Platform.isWindows) {
      PermissionStatus status = await Permission.storage.status;
      if (status.isPermanentlyDenied || status.isDenied) {
        final Map<Permission, PermissionStatus> statuses = await [
          Permission.storage,
          Permission.accessMediaLocation,
          Permission.mediaLibrary,
        ].request();
        debugPrint(statuses[Permission.storage].toString());
      }
      status = await Permission.storage.status;
    }
    final RegExp avoid = RegExp(r'[\.\\\*\:\"\?#/;\|]');
    data['title'] = data['title'].toString().split('(From')[0].trim();
    String filename = '${data["title"]} - ${data["artist"]}';
    String dlPath =
        Hive.box('settings').get('downloadPath', defaultValue: '') as String;
    if (filename.length > 200) {
      final String temp = filename.substring(0, 200);
      final List tempList = temp.split(', ');
      tempList.removeLast();
      filename = tempList.join(', ');
    }

    filename = '${filename.replaceAll(avoid, "").replaceAll("  ", " ")}.m4a';
    if (dlPath == '') {
      if (Platform.isWindows) {
        final Directory? temp = await getDownloadsDirectory();
        dlPath = temp!.path;
      } else {
        final String? temp = await ExtStorage.getExternalStoragePublicDirectory(
            ExtStorage.DIRECTORY_MUSIC);
        dlPath = temp!;
      }
    }
    if (data['url'].toString().contains('google') && createYoutubeFolder) {
      dlPath = '$dlPath/YouTube';
      if (!await Directory(dlPath).exists()) {
        await Directory(dlPath).create();
      }
    }

    if (createFolder && createDownloadFolder && folderName != null) {
      final String foldername = folderName.replaceAll(avoid, '');
      dlPath = '$dlPath/$foldername';
      if (!await Directory(dlPath).exists()) {
        await Directory(dlPath).create();
      }
    }

    final bool exists = await File('$dlPath/$filename').exists();
    if (exists) {
      if (remember.value == true && rememberOption != null) {
        switch (rememberOption) {
          case 0:
            lastDownloadId = data['id'].toString();
            break;
          case 1:
            downloadSong(context, dlPath, filename, data);
            break;
          case 2:
            while (await File('$dlPath/$filename').exists()) {
              filename = filename.replaceAll('.m4a', ' (1).m4a');
            }
            break;
          default:
            lastDownloadId = data['id'].toString();
            break;
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text(
                  'Already Exists',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '"${data['title']}" already exists.\nDo you want to download it again?',
                      softWrap: true,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
                actions: [
                  Column(
                    children: [
                      ValueListenableBuilder(
                          valueListenable: remember,
                          builder: (BuildContext context, bool value,
                              Widget? child) {
                            return Row(
                              children: [
                                Checkbox(
                                  activeColor:
                                      Theme.of(context).colorScheme.secondary,
                                  value: remember.value,
                                  onChanged: (bool? value) {
                                    remember.value = value ?? false;
                                  },
                                ),
                                const Text('Remember my choice'),
                              ],
                            );
                          }),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              primary: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () {
                              lastDownloadId = data['id'].toString();
                              Navigator.pop(context);
                              rememberOption = 0;
                            },
                            child: const Text(
                              'No',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              primary: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              Hive.box('downloads').delete(data['id']);
                              downloadSong(context, dlPath, filename, data);
                              rememberOption = 1;
                            },
                            child: const Text('Yes, but Replace Old'),
                          ),
                          const SizedBox(width: 5.0),
                          TextButton(
                            style: TextButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              while (await File('$dlPath/$filename').exists()) {
                                filename =
                                    filename.replaceAll('.m4a', ' (1).m4a');
                              }
                              rememberOption = 2;
                              downloadSong(context, dlPath, filename, data);
                            },
                            child: Text(
                              'Yes',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary ==
                                              Colors.white
                                          ? Colors.black
                                          : null),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ]);
          },
        );
      }
    } else {
      downloadSong(context, dlPath, filename, data);
    }
  }

  Future<void> downloadSong(
      BuildContext context, String? dlPath, String fileName, Map data) async {
    progress = null;
    notifyListeners();
    String filename = fileName;
    String? filepath;
    late String filepath2;
    String appPath;
    final List<int> _bytes = [];
    String lyrics;
    final artname = filename.replaceAll('.m4a', '.jpg');
    if (!Platform.isWindows) {
      final Directory appDir = await getTemporaryDirectory();
      appPath = appDir.path;
    } else {
      final Directory? temp = await getDownloadsDirectory();
      appPath = temp!.path;
    }
    if (data['url'].toString().contains('google')) {
      filename = filename.replaceAll('.m4a', '.opus');
    }
    try {
      await File('$dlPath/$filename')
          .create(recursive: true)
          .then((value) => filepath = value.path);
      // print('created audio file');

      await File('$appPath/$artname')
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    } catch (e) {
      await [
        Permission.manageExternalStorage,
      ].request();
      await File('$dlPath/$filename')
          .create(recursive: true)
          .then((value) => filepath = value.path);
      // print('created audio file');
      await File('$appPath/$artname')
          .create(recursive: true)
          .then((value) => filepath2 = value.path);
    }
    debugPrint('Audio path $filepath');
    debugPrint('Image path $filepath2');

    final String kUrl = data['url'].toString().replaceAll(
        '_96.', "_${preferredDownloadQuality.replaceAll(' kbps', '')}.");
    final client = Client();
    final response = await client.send(Request('GET', Uri.parse(kUrl)));
    final int total = response.contentLength ?? 0;
    int recieved = 0;
    response.stream.asBroadcastStream();
    response.stream.listen((value) {
      _bytes.addAll(value);
      try {
        recieved += value.length;
        progress = recieved / total;
        notifyListeners();
        if (!download) {
          client.close();
        }
      } catch (e) {
        // print('Error: $e');
      }
    }).onDone(() async {
      if (download) {
        final file = File(filepath!);
        await file.writeAsBytes(_bytes);

        final client = HttpClient();
        final HttpClientRequest request2 =
            await client.getUrl(Uri.parse(data['image'].toString()));
        final HttpClientResponse response2 = await request2.close();
        final bytes2 = await consolidateHttpClientResponseBytes(response2);
        final File file2 = File(filepath2);

        await file2.writeAsBytes(bytes2);
        try {
          lyrics = downloadLyrics ? await getLyrics(data) : '';
        } catch (e) {
          // print('Error fetching lyrics: $e');
          lyrics = '';
        }

        if (filepath!.endsWith('.opus')) {
          // List<String>? _argsList;
          // ShowSnackBar().showSnackBar(
          //   context,
          //   'Converting "opus" to "$downloadFormat"',
          // );

          // if (downloadFormat == 'mp3')
          //   _argsList = [
          //     "-y",
          //     "-i",
          //     "$filepath",
          //     "-c:a",
          //     "libmp3lame",
          //     "-b:a",
          //     "256k",
          //     "${filepath.replaceAll('.opus', '.mp3')}"
          //   ];
          // if (downloadFormat == 'm4a') {
          //   _argsList = [
          //     '-y',
          //     '-i',
          //     filepath!,
          //     '-c:a',
          //     'aac',
          //     '-b:a',
          //     '256k',
          //     filepath!.replaceAll('.opus', '.m4a')
          //   ];
          // }
          // await FlutterFFmpeg().executeWithArguments(_argsList);
          // await File(filepath!).delete();
          // filepath = filepath!.replaceAll('.opus', '.$downloadFormat');
        }

        debugPrint('Started tag editing');
        final Tag tag = Tag(
          title: data['title'].toString(),
          artist: data['artist'].toString(),
          albumArtist: data['album_artist']?.toString() ??
              data['artist']?.toString().split(', ')[0],
          artwork: filepath2.toString(),
          album: data['album'].toString(),
          genre: data['language'].toString(),
          year: data['year'].toString(),
          lyrics: lyrics,
          comment: 'BlackHole',
        );
        try {
          final tagger = Audiotagger();
          await tagger.writeTags(
            path: filepath!,
            tag: tag,
          );
          // await Future.delayed(const Duration(seconds: 1), () async {
          //   if (await file2.exists()) {
          //     await file2.delete();
          //   }
          // });
        } catch (e) {
          // print('Failed to edit tags');
        }
        client.close();
        debugPrint('Done');
        lastDownloadId = data['id'].toString();
        progress = 0.0;
        notifyListeners();
        try {
          ShowSnackBar().showSnackBar(
            context,
            '"${data['title'].toString()}" has been downloaded',
          );
        } catch (e) {
          // ignore: avoid_print
          print('Failed to show Snackbar');
        }

        final songData = {
          'id': data['id'].toString(),
          'title': data['title'].toString(),
          'subtitle': data['subtitle'].toString(),
          'artist': data['artist'].toString(),
          'albumArtist': data['album_artist']?.toString() ??
              data['artist']?.toString().split(', ')[0],
          'album': data['album'].toString(),
          'genre': data['language'].toString(),
          'year': data['year'].toString(),
          'lyrics': lyrics,
          'duration': data['duration'],
          'release_date': data['release_date'].toString(),
          'album_id': data['album_id'].toString(),
          'perma_url': data['perma_url'].toString(),
          'quality': preferredDownloadQuality,
          'path': filepath,
          'image': filepath2,
          'image_url': data['image'].toString(),
          'fromYt': data['url'].toString().contains('google'),
          'dateAdded': DateTime.now().toString(),
        };
        Hive.box('downloads').put(songData['id'], songData);
      } else {
        download = true;
        progress = 0.0;
      }
    });
  }
}
