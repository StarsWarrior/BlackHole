library config.globals;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class MyTheme with ChangeNotifier {
  bool _isDark = Hive.box('settings').get('darkMode') ?? true;

  String accentColor = Hive.box('settings').get('themeColor');
  String canvasColor =
      Hive.box('settings').get('canvasColor', defaultValue: 'Grey');
  String cardColor =
      Hive.box('settings').get('cardColor', defaultValue: 'Grey850');

  int backGrad = Hive.box('settings').get('backGrad', defaultValue: 1);
  int cardGrad = Hive.box('settings').get('cardGrad', defaultValue: 3);
  int bottomGrad = Hive.box('settings').get('bottomGrad', defaultValue: 2);

  int colorHue = Hive.box('settings').get('colorHue');

  List<List<Color>> backOpt = [
    [
      Colors.grey[850],
      Colors.grey[900],
      Colors.black,
    ],
    [
      Colors.grey[900],
      Colors.grey[900],
      Colors.black,
    ],
    [
      Colors.grey[900],
      Colors.black,
    ],
    [
      Colors.grey[900],
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
      Colors.grey[850],
      Colors.grey[850],
      Colors.grey[900],
    ],
    [
      Colors.grey[850],
      Colors.grey[900],
      Colors.grey[900],
    ],
    [
      Colors.grey[850],
      Colors.grey[900],
      Colors.black,
    ],
    [
      Colors.grey[900],
      Colors.grey[900],
      Colors.black,
    ],
    [
      Colors.grey[900],
      Colors.black,
    ],
    [
      Colors.grey[900],
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
      Colors.grey[850].withOpacity(0.8),
      Colors.grey[900].withOpacity(0.9),
      Colors.black.withOpacity(1),
    ],
    [
      Colors.grey[900].withOpacity(0.8),
      Colors.grey[900].withOpacity(0.9),
      Colors.black.withOpacity(1),
    ],
    [
      Colors.grey[900].withOpacity(0.9),
      Colors.black.withOpacity(1),
    ],
    [
      Colors.grey[900].withOpacity(0.9),
      Colors.black.withOpacity(0.9),
      Colors.black.withOpacity(1),
    ],
    [
      Colors.black.withOpacity(0.9),
      Colors.black.withOpacity(1),
    ]
  ];

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

  Color getCanvasColor() {
    if (canvasColor == 'Black') return Colors.black;
    if (canvasColor == 'Grey') return Colors.grey[900];
    return Colors.grey[900];
  }

  void switchCanvasColor(String color) {
    Hive.box('settings').put('canvasColor', color);
    canvasColor = color;
    notifyListeners();
  }

  Color getCardColor() {
    if (cardColor == 'Grey800') return Colors.grey[800];
    if (cardColor == 'Grey850') return Colors.grey[850];
    if (cardColor == 'Grey900') return Colors.grey[900];
    if (cardColor == 'Black') return Colors.black;
    return Colors.grey[850];
  }

  void switchCardColor(String color) {
    Hive.box('settings').put('cardColor', color);
    cardColor = color;
    notifyListeners();
  }

  List<Color> getCardGradient() {
    return cardOpt[cardGrad];
  }

  List<Color> getBackGradient() {
    return backOpt[backGrad];
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
