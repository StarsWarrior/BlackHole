library config.globals;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class MyTheme with ChangeNotifier {
  bool _isDark =
      Hive.box('settings').get('darkMode', defaultValue: true) as bool;

  bool _useSystemTheme =
      Hive.box('settings').get('useSystemTheme', defaultValue: false) as bool;

  String accentColor =
      Hive.box('settings').get('themeColor', defaultValue: 'Teal') as String;
  String canvasColor =
      Hive.box('settings').get('canvasColor', defaultValue: 'Grey') as String;
  String cardColor =
      Hive.box('settings').get('cardColor', defaultValue: 'Grey850') as String;

  int backGrad = Hive.box('settings').get('backGrad', defaultValue: 1) as int;
  int cardGrad = Hive.box('settings').get('cardGrad', defaultValue: 3) as int;
  int bottomGrad =
      Hive.box('settings').get('bottomGrad', defaultValue: 2) as int;

  int colorHue = Hive.box('settings').get('colorHue', defaultValue: 400) as int;
  Color? playGradientColor;

  List<List<Color>> backOpt = [
    [
      Colors.grey[850]!,
      Colors.grey[900]!,
      Colors.black,
    ],
    [
      Colors.grey[900]!,
      Colors.grey[900]!,
      Colors.black,
    ],
    [
      Colors.grey[900]!,
      Colors.black,
    ],
    [
      Colors.grey[900]!,
      Colors.black,
      Colors.black,
    ],
    [
      Colors.black,
      Colors.black,
    ]
  ];

  List<List<Color>> cardOpt = [
    [
      Colors.grey[850]!,
      Colors.grey[850]!,
      Colors.grey[900]!,
    ],
    [
      Colors.grey[850]!,
      Colors.grey[900]!,
      Colors.grey[900]!,
    ],
    [
      Colors.grey[850]!,
      Colors.grey[900]!,
      Colors.black,
    ],
    [
      Colors.grey[900]!,
      Colors.grey[900]!,
      Colors.black,
    ],
    [
      Colors.grey[900]!,
      Colors.black,
    ],
    [
      Colors.grey[900]!,
      Colors.black,
      Colors.black,
    ],
    [
      Colors.black,
      Colors.black,
    ]
  ];

  List<List<Color>> transOpt = [
    [
      Colors.grey[850]!.withOpacity(0.8),
      Colors.grey[900]!.withOpacity(0.9),
      Colors.black.withOpacity(1),
    ],
    [
      Colors.grey[900]!.withOpacity(0.8),
      Colors.grey[900]!.withOpacity(0.9),
      Colors.black.withOpacity(1),
    ],
    [
      Colors.grey[900]!.withOpacity(0.9),
      Colors.black.withOpacity(1),
    ],
    [
      Colors.grey[900]!.withOpacity(0.9),
      Colors.black.withOpacity(0.9),
      Colors.black.withOpacity(1),
    ],
    [
      Colors.black.withOpacity(0.9),
      Colors.black.withOpacity(1),
    ]
  ];

  void switchTheme({bool? useSystemTheme, bool? isDark, bool notify = true}) {
    if (isDark != null) {
      _isDark = isDark;
    }
    if (useSystemTheme != null) {
      _useSystemTheme = useSystemTheme;
    }
    Hive.box('settings').put('darkMode', _isDark);
    Hive.box('settings').put('useSystemTheme', _useSystemTheme);
    if (notify) notifyListeners();
  }

  void switchColor(String color, int hue, {bool notify = true}) {
    Hive.box('settings').put('themeColor', color);
    accentColor = color;
    Hive.box('settings').put('colorHue', hue);
    colorHue = hue;
    if (notify) notifyListeners();
  }

  ThemeMode currentTheme() {
    if (_useSystemTheme == true) {
      return ThemeMode.system;
    } else {
      return _isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  int currentHue() {
    return colorHue;
  }

  Future<void> setLastPlayGradient(Color? color) async {
    playGradientColor = color;
  }

  Color getColor(String color, int hue) {
    switch (color) {
      case 'Red':
        return Colors.redAccent[hue]!;
      case 'Teal':
        return Colors.tealAccent[hue]!;
      case 'Light Blue':
        return Colors.lightBlueAccent[hue]!;
      case 'Yellow':
        return Colors.yellowAccent[hue]!;
      case 'Orange':
        return Colors.orangeAccent[hue]!;
      case 'Blue':
        return Colors.blueAccent[hue]!;
      case 'Cyan':
        return Colors.cyanAccent[hue]!;
      case 'Lime':
        return Colors.limeAccent[hue]!;
      case 'Pink':
        return Colors.pinkAccent[hue]!;
      case 'Green':
        return Colors.greenAccent[hue]!;
      case 'Amber':
        return Colors.amberAccent[hue]!;
      case 'Indigo':
        return Colors.indigoAccent[hue]!;
      case 'Purple':
        return Colors.purpleAccent[hue]!;
      case 'Deep Orange':
        return Colors.deepOrangeAccent[hue]!;
      case 'Deep Purple':
        return Colors.deepPurpleAccent[hue]!;
      case 'Light Green':
        return Colors.lightGreenAccent[hue]!;
      case 'White':
        return Colors.white;

      default:
        return _isDark ? Colors.tealAccent[400]! : Colors.lightBlueAccent[400]!;
    }
  }

  Color getCanvasColor() {
    if (canvasColor == 'Black') return Colors.black;
    if (canvasColor == 'Grey') return Colors.grey[900]!;
    return Colors.grey[900]!;
  }

  void switchCanvasColor(String color, {bool notify = true}) {
    Hive.box('settings').put('canvasColor', color);
    canvasColor = color;
    if (notify) notifyListeners();
  }

  Color getCardColor() {
    if (cardColor == 'Grey800') return Colors.grey[800]!;
    if (cardColor == 'Grey850') return Colors.grey[850]!;
    if (cardColor == 'Grey900') return Colors.grey[900]!;
    if (cardColor == 'Black') return Colors.black;
    return Colors.grey[850]!;
  }

  void switchCardColor(String color, {bool notify = true}) {
    Hive.box('settings').put('cardColor', color);
    cardColor = color;
    if (notify) notifyListeners();
  }

  List<Color> getCardGradient({bool miniplayer = false}) {
    final List<Color> output = cardOpt[cardGrad];
    if (miniplayer && output.length > 2) {
      output.removeAt(0);
    }
    return output;
  }

  List<Color> getBackGradient() {
    return backOpt[backGrad];
  }

  Color getPlayGradient() {
    return backOpt[backGrad].last;
  }

  List<Color> getTransBackGradient() {
    return transOpt[backGrad];
  }

  List<Color> getBottomGradient() {
    return backOpt[bottomGrad];
  }

  Color currentColor() {
    switch (accentColor) {
      case 'Red':
        return Colors.redAccent[currentHue()]!;
      case 'Teal':
        return Colors.tealAccent[currentHue()]!;
      case 'Light Blue':
        return Colors.lightBlueAccent[currentHue()]!;
      case 'Yellow':
        return Colors.yellowAccent[currentHue()]!;
      case 'Orange':
        return Colors.orangeAccent[currentHue()]!;
      case 'Blue':
        return Colors.blueAccent[currentHue()]!;
      case 'Cyan':
        return Colors.cyanAccent[currentHue()]!;
      case 'Lime':
        return Colors.limeAccent[currentHue()]!;
      case 'Pink':
        return Colors.pinkAccent[currentHue()]!;
      case 'Green':
        return Colors.greenAccent[currentHue()]!;
      case 'Amber':
        return Colors.amberAccent[currentHue()]!;
      case 'Indigo':
        return Colors.indigoAccent[currentHue()]!;
      case 'Purple':
        return Colors.purpleAccent[currentHue()]!;
      case 'Deep Orange':
        return Colors.deepOrangeAccent[currentHue()]!;
      case 'Deep Purple':
        return Colors.deepPurpleAccent[currentHue()]!;
      case 'Light Green':
        return Colors.lightGreenAccent[currentHue()]!;
      case 'White':
        return Colors.white;

      default:
        return _isDark ? Colors.tealAccent[400]! : Colors.lightBlueAccent[400]!;
    }
  }

  void saveTheme(String themeName) {
    final userThemes =
        Hive.box('settings').get('userThemes', defaultValue: {}) as Map;
    Hive.box('settings').put('userThemes', {
      ...userThemes,
      themeName: {
        'isDark': _isDark,
        'useSystemTheme': _useSystemTheme,
        'accentColor': accentColor,
        'canvasColor': canvasColor,
        'cardColor': cardColor,
        'backGrad': backGrad,
        'cardGrad': cardGrad,
        'bottomGrad': bottomGrad,
        'colorHue': colorHue,
      }
    });
  }

  void deleteTheme(String themeName) {
    final userThemes =
        Hive.box('settings').get('userThemes', defaultValue: {}) as Map;
    userThemes.remove(themeName);

    Hive.box('settings').put('userThemes', {...userThemes});
  }

  Map getThemes() {
    return Hive.box('settings').get('userThemes', defaultValue: {}) as Map;
  }

  void setInitialTheme(String themeName) {
    Hive.box('settings').put('theme', themeName);
  }

  String getInitialTheme() {
    return Hive.box('settings').get('theme') as String;
  }
}

MyTheme currentTheme = MyTheme();
