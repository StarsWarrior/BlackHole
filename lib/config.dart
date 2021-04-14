library config.globals;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class MyTheme with ChangeNotifier {
  bool _isDark = Hive.box('settings').get('darkMode') ?? true;

  String accentColor = Hive.box('settings').get('themeColor');
  int colorHue = Hive.box('settings').get('colorHue');

  void switchTheme(val) {
    _isDark = val;
    _isDark ? switchColor('Teal') : switchColor('Blue');
    // notifyListeners();
  }

  void switchColor(val) {
    Hive.box('settings').put('themeColor', val);
    accentColor = val;
    switchHue(400);
    // notifyListeners();
  }

  void switchHue(val) {
    Hive.box('settings').put('colorHue', val);
    colorHue = val;
    notifyListeners();
  }

  ThemeMode currentTheme() {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  int currentHue() {
    return colorHue ?? 400;
  }

  Color currentColor() {
    switch (accentColor) {
      case 'Red':
        return Colors.redAccent[currentHue()];
      case 'Teal':
        return Colors.tealAccent[currentHue()];
      case 'Light Blue':
        return Colors.lightBlueAccent[currentHue()];
      case 'Yellow':
        return Colors.yellowAccent[currentHue()];
      case 'Orange':
        return Colors.orangeAccent[currentHue()];
      case 'Blue':
        return Colors.blueAccent[currentHue()];
      case 'Cyan':
        return Colors.cyanAccent[currentHue()];
      case 'Lime':
        return Colors.limeAccent[currentHue()];
      case 'Pink':
        return Colors.pinkAccent[currentHue()];
      case 'Green':
        return Colors.greenAccent[currentHue()];
      case 'Amber':
        return Colors.amberAccent[currentHue()];
      case 'Indigo':
        return Colors.indigoAccent[currentHue()];
      case 'Purple':
        return Colors.purpleAccent[currentHue()];
      case 'Deep Orange':
        return Colors.deepOrangeAccent[currentHue()];
      case 'Deep Purple':
        return Colors.deepPurpleAccent[currentHue()];
      case 'Light Green':
        return Colors.lightGreenAccent[currentHue()];

      default:
        return _isDark ? Colors.tealAccent[400] : Colors.blueAccent[400];
    }
  }
}

MyTheme currentTheme = MyTheme();
// MyTheme currentColor = MyTheme();
