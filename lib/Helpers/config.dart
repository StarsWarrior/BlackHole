library config.globals;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class MyTheme with ChangeNotifier {
  bool _isDark = Hive.box('settings').get('darkMode') ?? true;

  String accentColor = Hive.box('settings').get('themeColor');
  int colorHue = Hive.box('settings').get('colorHue');

  void switchTheme(bool val) {
    _isDark = val;
    _isDark ? switchColor('Teal', 400) : switchColor('Light Blue', 400);
  }

  void switchColor(String color, int hue) {
    Hive.box('settings').put('themeColor', color);
    accentColor = color;
    Hive.box('settings').put('colorHue', hue);
    colorHue = hue;
    notifyListeners();
  }

  ThemeMode currentTheme() {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  int currentHue() {
    return colorHue ?? 400;
  }

  Color getColor(String color, int hue) {
    switch (color) {
      case 'Red':
        return Colors.redAccent[hue];
      case 'Teal':
        return Colors.tealAccent[hue];
      case 'Light Blue':
        return Colors.lightBlueAccent[hue];
      case 'Yellow':
        return Colors.yellowAccent[hue];
      case 'Orange':
        return Colors.orangeAccent[hue];
      case 'Blue':
        return Colors.blueAccent[hue];
      case 'Cyan':
        return Colors.cyanAccent[hue];
      case 'Lime':
        return Colors.limeAccent[hue];
      case 'Pink':
        return Colors.pinkAccent[hue];
      case 'Green':
        return Colors.greenAccent[hue];
      case 'Amber':
        return Colors.amberAccent[hue];
      case 'Indigo':
        return Colors.indigoAccent[hue];
      case 'Purple':
        return Colors.purpleAccent[hue];
      case 'Deep Orange':
        return Colors.deepOrangeAccent[hue];
      case 'Deep Purple':
        return Colors.deepPurpleAccent[hue];
      case 'Light Green':
        return Colors.lightGreenAccent[hue];

      default:
        return _isDark ? Colors.tealAccent[400] : Colors.lightBlueAccent[400];
    }
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
        return _isDark ? Colors.tealAccent[400] : Colors.lightBlueAccent[400];
    }
  }
}

MyTheme currentTheme = MyTheme();
