import 'dart:io';

import 'package:flutter/services.dart';

// ignore: avoid_classes_with_only_static_members
class NativeMethod {
  static const MethodChannel intent = MethodChannel('intentChannel');

  static Future<void> openVideo(String audioPath) async {
    if (await File(audioPath).exists()) {
      intent.invokeMethod('openAudio', {'audioPath': audioPath});
    }
  }
}
