import 'dart:io';

import 'package:flutter/services.dart';

// ignore: avoid_classes_with_only_static_members
class NativeMethod {
  static const MethodChannel sharedTextChannel =
      MethodChannel('com.shadow.blackhole/sharedTextChannel');
  static const MethodChannel registermediaChannel =
      MethodChannel('com.shadow.blackhole/registerMedia');
  static const MethodChannel intentChannel =
      MethodChannel('com.shadow.blackhole/intentChannel');

  static Future<void> handleIntent() async {
    // final _intent = await sharedTextChannel.invokeMethod('getSharedText');
    // if (_intent != null) {
    //   print('IntentHandler: Result: $_intent');
    // } else {
    //   print('intent is null');
    // }
  }

  static Future<void> handleAudioIntent(String audioPath) async {
    if (await File(audioPath).exists()) {
      intentChannel.invokeMethod('openAudio', {'audioPath': audioPath});
    }
  }
}
