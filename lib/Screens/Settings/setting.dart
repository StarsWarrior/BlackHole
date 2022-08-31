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

import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/popup.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/backup_restore.dart';
import 'package:blackhole/Helpers/config.dart';
// import 'package:blackhole/Helpers/countrycodes.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Helpers/supabase.dart';
import 'package:blackhole/Screens/Home/saavn.dart' as home_screen;
import 'package:blackhole/Screens/Settings/player_gradient.dart';
// import 'package:blackhole/Screens/Top Charts/top.dart' as top_screen;
import 'package:blackhole/Services/ext_storage_provider.dart';
import 'package:blackhole/main.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingPage extends StatefulWidget {
  final Function? callback;
  const SettingPage({this.callback});
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String? appVersion;
  final Box settingsBox = Hive.box('settings');
  final MyTheme currentTheme = GetIt.I<MyTheme>();
  String downloadPath = Hive.box('settings')
      .get('downloadPath', defaultValue: '/storage/emulated/0/Music') as String;
  String autoBackPath = Hive.box('settings').get(
    'autoBackPath',
    defaultValue: '/storage/emulated/0/BlackHole/Backups',
  ) as String;
  final ValueNotifier<bool> includeOrExclude = ValueNotifier<bool>(
    Hive.box('settings').get('includeOrExclude', defaultValue: false) as bool,
  );
  List includedExcludedPaths = Hive.box('settings')
      .get('includedExcludedPaths', defaultValue: []) as List;
  List blacklistedHomeSections = Hive.box('settings')
      .get('blacklistedHomeSections', defaultValue: []) as List;
  String streamingQuality = Hive.box('settings')
      .get('streamingQuality', defaultValue: '96 kbps') as String;
  String ytQuality =
      Hive.box('settings').get('ytQuality', defaultValue: 'Low') as String;
  String downloadQuality = Hive.box('settings')
      .get('downloadQuality', defaultValue: '320 kbps') as String;
  String ytDownloadQuality = Hive.box('settings')
      .get('ytDownloadQuality', defaultValue: 'High') as String;
  String lang =
      Hive.box('settings').get('lang', defaultValue: 'English') as String;
  String canvasColor =
      Hive.box('settings').get('canvasColor', defaultValue: 'Grey') as String;
  String cardColor =
      Hive.box('settings').get('cardColor', defaultValue: 'Grey900') as String;
  String theme =
      Hive.box('settings').get('theme', defaultValue: 'Default') as String;
  Map userThemes =
      Hive.box('settings').get('userThemes', defaultValue: {}) as Map;
  String region =
      Hive.box('settings').get('region', defaultValue: 'India') as String;
  bool useProxy =
      Hive.box('settings').get('useProxy', defaultValue: false) as bool;
  String themeColor =
      Hive.box('settings').get('themeColor', defaultValue: 'Teal') as String;
  int colorHue = Hive.box('settings').get('colorHue', defaultValue: 400) as int;
  int downFilename =
      Hive.box('settings').get('downFilename', defaultValue: 0) as int;
  List<String> languages = [
    'Hindi',
    'English',
    'Punjabi',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Bengali',
    'Kannada',
    'Bhojpuri',
    'Malayalam',
    'Urdu',
    'Haryanvi',
    'Rajasthani',
    'Odia',
    'Assamese'
  ];
  List miniButtonsOrder = Hive.box('settings').get(
    'miniButtonsOrder',
    defaultValue: ['Like', 'Previous', 'Play/Pause', 'Next', 'Download'],
  ) as List;
  List preferredLanguage = Hive.box('settings')
      .get('preferredLanguage', defaultValue: ['Hindi'])?.toList() as List;
  List preferredMiniButtons = Hive.box('settings').get(
    'preferredMiniButtons',
    defaultValue: ['Like', 'Play/Pause', 'Next'],
  )?.toList() as List;

  @override
  void initState() {
    main();
    super.initState();
  }

  Future<void> main() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    setState(
      () {},
    );
  }

  bool compareVersion(String latestVersion, String currentVersion) {
    bool update = false;
    final List<String> latestList = latestVersion.split('.');
    final List<String> currentList = currentVersion.split('.');

    for (int i = 0; i < latestList.length; i++) {
      try {
        if (int.parse(latestList[i]) > int.parse(currentList[i])) {
          update = true;
          break;
        }
      } catch (e) {
        break;
      }
    }

    return update;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> userThemesList = <String>[
      'Default',
      ...userThemes.keys.map((theme) => theme as String),
      'Custom',
    ];

    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            elevation: 0,
            stretch: true,
            pinned: true,
            backgroundColor: Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.secondary
                : null,
            expandedHeight: MediaQuery.of(context).size.height / 4.5,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.dstIn,
                child: Center(
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!
                        .settings,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            15,
                            15,
                            15,
                            0,
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .theme,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .darkMode,
                          ),
                          keyName: 'darkMode',
                          defaultValue: true,
                          onChanged: (bool val, Box box) {
                            box.put(
                              'useSystemTheme',
                              false,
                            );
                            currentTheme.switchTheme(
                              isDark: val,
                              useSystemTheme: false,
                            );
                            switchToCustomTheme();
                          },
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .useSystemTheme,
                          ),
                          keyName: 'useSystemTheme',
                          defaultValue: true,
                          onChanged: (bool val, Box box) {
                            currentTheme.switchTheme(useSystemTheme: val);
                            switchToCustomTheme();
                          },
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .accent,
                          ),
                          subtitle: Text('$themeColor, $colorHue'),
                          trailing: Padding(
                            padding: const EdgeInsets.all(
                              10.0,
                            ),
                            child: Container(
                              height: 25,
                              width: 25,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  100.0,
                                ),
                                color: Theme.of(context).colorScheme.secondary,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[900]!,
                                    blurRadius: 5.0,
                                    offset: const Offset(
                                      0.0,
                                      3.0,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              isDismissible: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (BuildContext context) {
                                final List<String> colors = [
                                  'Purple',
                                  'Deep Purple',
                                  'Indigo',
                                  'Blue',
                                  'Light Blue',
                                  'Cyan',
                                  'Teal',
                                  'Green',
                                  'Light Green',
                                  'Lime',
                                  'Yellow',
                                  'Amber',
                                  'Orange',
                                  'Deep Orange',
                                  'Red',
                                  'Pink',
                                  'White',
                                ];
                                return BottomGradientContainer(
                                  borderRadius: BorderRadius.circular(
                                    20.0,
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      10,
                                      0,
                                      10,
                                    ),
                                    itemCount: colors.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 15.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            for (int hue in [
                                              100,
                                              200,
                                              400,
                                              700
                                            ])
                                              GestureDetector(
                                                onTap: () {
                                                  themeColor = colors[index];
                                                  colorHue = hue;
                                                  currentTheme.switchColor(
                                                    colors[index],
                                                    colorHue,
                                                  );
                                                  setState(
                                                    () {},
                                                  );
                                                  switchToCustomTheme();
                                                  Navigator.pop(context);
                                                },
                                                child: Container(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.125,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.125,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      100.0,
                                                    ),
                                                    color: MyTheme().getColor(
                                                      colors[index],
                                                      hue,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color:
                                                            Colors.grey[900]!,
                                                        blurRadius: 5.0,
                                                        offset: const Offset(
                                                          0.0,
                                                          3.0,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  child: (themeColor ==
                                                              colors[index] &&
                                                          colorHue == hue)
                                                      ? const Icon(
                                                          Icons.done_rounded,
                                                        )
                                                      : const SizedBox(),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                          dense: true,
                        ),
                        Visibility(
                          visible:
                              Theme.of(context).brightness == Brightness.dark,
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .bgGrad,
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .bgGradSub,
                                ),
                                trailing: Padding(
                                  padding: const EdgeInsets.all(
                                    10.0,
                                  ),
                                  child: Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        100.0,
                                      ),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? currentTheme.getBackGradient()
                                            : [
                                                Colors.white,
                                                Theme.of(context).canvasColor,
                                              ],
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.white24,
                                          blurRadius: 5.0,
                                          offset: Offset(
                                            0.0,
                                            3.0,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  final List<List<Color>> gradients =
                                      currentTheme.backOpt;
                                  PopupDialog().showPopup(
                                    context: context,
                                    child: SizedBox(
                                      width: 500,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          30,
                                          0,
                                          10,
                                        ),
                                        itemCount: gradients.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              left: 20.0,
                                              right: 20.0,
                                              bottom: 15.0,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                settingsBox.put(
                                                  'backGrad',
                                                  index,
                                                );
                                                currentTheme.backGrad = index;
                                                widget.callback!();
                                                switchToCustomTheme();
                                                Navigator.pop(context);
                                                setState(
                                                  () {},
                                                );
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.125,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.125,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    15.0,
                                                  ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: gradients[index],
                                                  ),
                                                ),
                                                child: (currentTheme
                                                            .getBackGradient() ==
                                                        gradients[index])
                                                    ? const Icon(
                                                        Icons.done_rounded,
                                                      )
                                                    : const SizedBox(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                dense: true,
                              ),
                              ListTile(
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .cardGrad,
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .cardGradSub,
                                ),
                                trailing: Padding(
                                  padding: const EdgeInsets.all(
                                    10.0,
                                  ),
                                  child: Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        100.0,
                                      ),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? currentTheme.getCardGradient()
                                            : [
                                                Colors.white,
                                                Theme.of(context).canvasColor,
                                              ],
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.white24,
                                          blurRadius: 5.0,
                                          offset: Offset(
                                            0.0,
                                            3.0,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  final List<List<Color>> gradients =
                                      currentTheme.cardOpt;
                                  PopupDialog().showPopup(
                                    context: context,
                                    child: SizedBox(
                                      width: 500,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          30,
                                          0,
                                          10,
                                        ),
                                        itemCount: gradients.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              left: 20.0,
                                              right: 20.0,
                                              bottom: 15.0,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                settingsBox.put(
                                                  'cardGrad',
                                                  index,
                                                );
                                                currentTheme.cardGrad = index;
                                                widget.callback!();
                                                switchToCustomTheme();
                                                Navigator.pop(context);
                                                setState(
                                                  () {},
                                                );
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.125,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.125,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    15.0,
                                                  ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: gradients[index],
                                                  ),
                                                ),
                                                child: (currentTheme
                                                            .getCardGradient() ==
                                                        gradients[index])
                                                    ? const Icon(
                                                        Icons.done_rounded,
                                                      )
                                                    : const SizedBox(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                dense: true,
                              ),
                              ListTile(
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .bottomGrad,
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .bottomGradSub,
                                ),
                                trailing: Padding(
                                  padding: const EdgeInsets.all(
                                    10.0,
                                  ),
                                  child: Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        100.0,
                                      ),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? currentTheme.getBottomGradient()
                                            : [
                                                Colors.white,
                                                Theme.of(context).canvasColor,
                                              ],
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.white24,
                                          blurRadius: 5.0,
                                          offset: Offset(
                                            0.0,
                                            3.0,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  final List<List<Color>> gradients =
                                      currentTheme.backOpt;
                                  PopupDialog().showPopup(
                                    context: context,
                                    child: SizedBox(
                                      width: 500,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          30,
                                          0,
                                          10,
                                        ),
                                        itemCount: gradients.length,
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              left: 20.0,
                                              right: 20.0,
                                              bottom: 15.0,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                settingsBox.put(
                                                  'bottomGrad',
                                                  index,
                                                );
                                                currentTheme.bottomGrad = index;
                                                switchToCustomTheme();
                                                Navigator.pop(context);
                                                setState(
                                                  () {},
                                                );
                                              },
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.125,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.125,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    15.0,
                                                  ),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: gradients[index],
                                                  ),
                                                ),
                                                child: (currentTheme
                                                            .getBottomGradient() ==
                                                        gradients[index])
                                                    ? const Icon(
                                                        Icons.done_rounded,
                                                      )
                                                    : const SizedBox(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                                dense: true,
                              ),
                              ListTile(
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .canvasColor,
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .canvasColorSub,
                                ),
                                onTap: () {},
                                trailing: DropdownButton(
                                  value: canvasColor,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .color,
                                  ),
                                  underline: const SizedBox(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      switchToCustomTheme();
                                      setState(
                                        () {
                                          currentTheme
                                              .switchCanvasColor(newValue);
                                          canvasColor = newValue;
                                        },
                                      );
                                    }
                                  },
                                  items: <String>['Grey', 'Black']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                                dense: true,
                              ),
                              ListTile(
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .cardColor,
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .cardColorSub,
                                ),
                                onTap: () {},
                                trailing: DropdownButton(
                                  value: cardColor,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .color,
                                  ),
                                  underline: const SizedBox(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      switchToCustomTheme();
                                      setState(
                                        () {
                                          currentTheme
                                              .switchCardColor(newValue);
                                          cardColor = newValue;
                                        },
                                      );
                                    }
                                  },
                                  items: <String>[
                                    'Grey800',
                                    'Grey850',
                                    'Grey900',
                                    'Black'
                                  ].map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .useAmoled,
                          ),
                          dense: true,
                          onTap: () {
                            currentTheme.switchTheme(
                              useSystemTheme: false,
                              isDark: true,
                            );
                            Hive.box('settings').put('darkMode', true);

                            settingsBox.put('backGrad', 4);
                            currentTheme.backGrad = 4;
                            settingsBox.put('cardGrad', 6);
                            currentTheme.cardGrad = 6;
                            settingsBox.put('bottomGrad', 4);
                            currentTheme.bottomGrad = 4;

                            currentTheme.switchCanvasColor('Black');
                            canvasColor = 'Black';

                            currentTheme.switchCardColor('Grey900');
                            cardColor = 'Grey900';

                            themeColor = 'White';
                            colorHue = 400;
                            currentTheme.switchColor(
                              'White',
                              colorHue,
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .currentTheme,
                          ),
                          trailing: DropdownButton(
                            value: theme,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color,
                            ),
                            underline: const SizedBox(),
                            onChanged: (String? themeChoice) {
                              if (themeChoice != null) {
                                const deflt = 'Default';

                                currentTheme.setInitialTheme(themeChoice);

                                setState(
                                  () {
                                    theme = themeChoice;
                                    if (themeChoice == 'Custom') return;
                                    final selectedTheme =
                                        userThemes[themeChoice];

                                    settingsBox.put(
                                      'backGrad',
                                      themeChoice == deflt
                                          ? 2
                                          : selectedTheme['backGrad'],
                                    );
                                    currentTheme.backGrad = themeChoice == deflt
                                        ? 2
                                        : selectedTheme['backGrad'] as int;

                                    settingsBox.put(
                                      'cardGrad',
                                      themeChoice == deflt
                                          ? 4
                                          : selectedTheme['cardGrad'],
                                    );
                                    currentTheme.cardGrad = themeChoice == deflt
                                        ? 4
                                        : selectedTheme['cardGrad'] as int;

                                    settingsBox.put(
                                      'bottomGrad',
                                      themeChoice == deflt
                                          ? 3
                                          : selectedTheme['bottomGrad'],
                                    );
                                    currentTheme.bottomGrad = themeChoice ==
                                            deflt
                                        ? 3
                                        : selectedTheme['bottomGrad'] as int;

                                    currentTheme.switchCanvasColor(
                                      themeChoice == deflt
                                          ? 'Grey'
                                          : selectedTheme['canvasColor']
                                              as String,
                                      notify: false,
                                    );
                                    canvasColor = themeChoice == deflt
                                        ? 'Grey'
                                        : selectedTheme['canvasColor']
                                            as String;

                                    currentTheme.switchCardColor(
                                      themeChoice == deflt
                                          ? 'Grey900'
                                          : selectedTheme['cardColor']
                                              as String,
                                      notify: false,
                                    );
                                    cardColor = themeChoice == deflt
                                        ? 'Grey900'
                                        : selectedTheme['cardColor'] as String;

                                    themeColor = themeChoice == deflt
                                        ? 'Teal'
                                        : selectedTheme['accentColor']
                                            as String;
                                    colorHue = themeChoice == deflt
                                        ? 400
                                        : selectedTheme['colorHue'] as int;

                                    currentTheme.switchColor(
                                      themeColor,
                                      colorHue,
                                      notify: false,
                                    );

                                    currentTheme.switchTheme(
                                      useSystemTheme: !(themeChoice == deflt) &&
                                          selectedTheme['useSystemTheme']
                                              as bool,
                                      isDark: themeChoice == deflt ||
                                          selectedTheme['isDark'] as bool,
                                    );
                                  },
                                );
                              }
                            },
                            selectedItemBuilder: (BuildContext context) {
                              return userThemesList.map<Widget>((String item) {
                                return Text(item);
                              }).toList();
                            },
                            items: userThemesList.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      flex: 2,
                                      child: Text(
                                        value,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (value != 'Default' && value != 'Custom')
                                      Flexible(
                                        child: IconButton(
                                          //padding: EdgeInsets.zero,
                                          iconSize: 18,
                                          splashRadius: 18,
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    10.0,
                                                  ),
                                                ),
                                                title: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .deleteTheme,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                                ),
                                                content: Text(
                                                  '${AppLocalizations.of(
                                                    context,
                                                  )!.deleteThemeSubtitle} $value?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        Navigator.of(context)
                                                            .pop,
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .cancel,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: Theme.of(
                                                                context,
                                                              )
                                                                  .colorScheme
                                                                  .secondary ==
                                                              Colors.white
                                                          ? Colors.black
                                                          : null,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondary,
                                                    ),
                                                    onPressed: () {
                                                      currentTheme
                                                          .deleteTheme(value);
                                                      if (currentTheme
                                                              .getInitialTheme() ==
                                                          value) {
                                                        currentTheme
                                                            .setInitialTheme(
                                                          'Custom',
                                                        );
                                                        theme = 'Custom';
                                                      }
                                                      setState(
                                                        () {
                                                          userThemes =
                                                              currentTheme
                                                                  .getThemes();
                                                        },
                                                      );
                                                      ShowSnackBar()
                                                          .showSnackBar(
                                                        context,
                                                        AppLocalizations.of(
                                                          context,
                                                        )!
                                                            .themeDeleted,
                                                      );
                                                      return Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .delete,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 5.0,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.delete_rounded,
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              );
                            }).toList(),
                            isDense: true,
                          ),
                          dense: true,
                        ),
                        Visibility(
                          visible: theme == 'Custom',
                          child: ListTile(
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!
                                  .saveTheme,
                            ),
                            onTap: () {
                              final initialThemeName = '${AppLocalizations.of(
                                context,
                              )!.theme} ${userThemes.length + 1}';
                              showTextInputDialog(
                                context: context,
                                title: AppLocalizations.of(
                                  context,
                                )!
                                    .enterThemeName,
                                onSubmitted: (value) {
                                  if (value == '') return;
                                  currentTheme.saveTheme(value);
                                  currentTheme.setInitialTheme(value);
                                  setState(
                                    () {
                                      userThemes = currentTheme.getThemes();
                                      theme = value;
                                    },
                                  );
                                  ShowSnackBar().showSnackBar(
                                    context,
                                    AppLocalizations.of(
                                      context,
                                    )!
                                        .themeSaved,
                                  );
                                  Navigator.of(context).pop();
                                },
                                keyboardType: TextInputType.text,
                                initialText: initialThemeName,
                              );
                            },
                            dense: true,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            15,
                            15,
                            15,
                            0,
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .ui,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .playerScreenBackground,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .playerScreenBackgroundSub,
                          ),
                          dense: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) =>
                                    const PlayerGradientSelection(),
                              ),
                            );
                          },
                        ),

                        // BoxSwitchTile(
                        //   title: Text(
                        //     AppLocalizations.of(
                        //       context,
                        //     )!
                        //         .useBlurForNowPlaying,
                        //   ),
                        //   subtitle: Text(
                        //     AppLocalizations.of(
                        //       context,
                        //     )!
                        //         .useBlurForNowPlayingSub,
                        //   ),
                        //   keyName: 'useBlurForNowPlaying',
                        //   defaultValue: true,
                        //   isThreeLine: true,
                        // ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .useDenseMini,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .useDenseMiniSub,
                          ),
                          keyName: 'useDenseMini',
                          defaultValue: false,
                          isThreeLine: false,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .miniButtons,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .miniButtonsSub,
                          ),
                          dense: true,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final List checked =
                                    List.from(preferredMiniButtons);
                                final List<String> order =
                                    List.from(miniButtonsOrder);
                                return StatefulBuilder(
                                  builder: (
                                    BuildContext context,
                                    StateSetter setStt,
                                  ) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          15.0,
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: 500,
                                        child: ReorderableListView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.fromLTRB(
                                            0,
                                            10,
                                            0,
                                            10,
                                          ),
                                          onReorder:
                                              (int oldIndex, int newIndex) {
                                            if (oldIndex < newIndex) {
                                              newIndex--;
                                            }
                                            final temp = order.removeAt(
                                              oldIndex,
                                            );
                                            order.insert(newIndex, temp);
                                            setStt(
                                              () {},
                                            );
                                          },
                                          header: Center(
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .changeOrder,
                                            ),
                                          ),
                                          children: order.map((e) {
                                            return CheckboxListTile(
                                              key: Key(e),
                                              dense: true,
                                              activeColor: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              checkColor: Theme.of(context)
                                                          .colorScheme
                                                          .secondary ==
                                                      Colors.white
                                                  ? Colors.black
                                                  : null,
                                              value: checked.contains(e),
                                              title: Text(e),
                                              onChanged: (bool? value) {
                                                setStt(
                                                  () {
                                                    value!
                                                        ? checked.add(e)
                                                        : checked.remove(e);
                                                  },
                                                );
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!
                                                .cancel,
                                          ),
                                        ),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(context)
                                                        .colorScheme
                                                        .secondary ==
                                                    Colors.white
                                                ? Colors.black
                                                : null,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () {
                                                final List temp = [];
                                                for (int i = 0;
                                                    i < order.length;
                                                    i++) {
                                                  if (checked
                                                      .contains(order[i])) {
                                                    temp.add(order[i]);
                                                  }
                                                }
                                                preferredMiniButtons = temp;
                                                miniButtonsOrder = order;
                                                Navigator.pop(context);
                                                Hive.box('settings').put(
                                                  'preferredMiniButtons',
                                                  preferredMiniButtons,
                                                );
                                                Hive.box('settings').put(
                                                  'miniButtonsOrder',
                                                  order,
                                                );
                                              },
                                            );
                                          },
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!
                                                .ok,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 5,
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),

                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .blacklistedHomeSections,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .blacklistedHomeSectionsSub,
                          ),
                          dense: true,
                          onTap: () {
                            final GlobalKey<AnimatedListState> listKey =
                                GlobalKey<AnimatedListState>();
                            showModalBottomSheet(
                              isDismissible: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (BuildContext context) {
                                return BottomGradientContainer(
                                  borderRadius: BorderRadius.circular(
                                    20.0,
                                  ),
                                  child: AnimatedList(
                                    physics: const BouncingScrollPhysics(),
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      10,
                                      0,
                                      10,
                                    ),
                                    key: listKey,
                                    initialItemCount:
                                        blacklistedHomeSections.length + 1,
                                    itemBuilder: (cntxt, idx, animation) {
                                      return (idx == 0)
                                          ? ListTile(
                                              title: Text(
                                                AppLocalizations.of(context)!
                                                    .addNew,
                                              ),
                                              leading: const Icon(
                                                CupertinoIcons.add,
                                              ),
                                              onTap: () async {
                                                showTextInputDialog(
                                                  context: context,
                                                  title: AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .enterText,
                                                  keyboardType:
                                                      TextInputType.text,
                                                  onSubmitted: (String value) {
                                                    Navigator.pop(context);
                                                    blacklistedHomeSections.add(
                                                      value
                                                          .trim()
                                                          .toLowerCase(),
                                                    );
                                                    Hive.box('settings').put(
                                                      'blacklistedHomeSections',
                                                      blacklistedHomeSections,
                                                    );
                                                    listKey.currentState!
                                                        .insertItem(
                                                      blacklistedHomeSections
                                                          .length,
                                                    );
                                                  },
                                                );
                                              },
                                            )
                                          : SizeTransition(
                                              sizeFactor: animation,
                                              child: ListTile(
                                                leading: const Icon(
                                                  CupertinoIcons.folder,
                                                ),
                                                title: Text(
                                                  blacklistedHomeSections[
                                                          idx - 1]
                                                      .toString(),
                                                ),
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                    CupertinoIcons.clear,
                                                    size: 15.0,
                                                  ),
                                                  tooltip: 'Remove',
                                                  onPressed: () {
                                                    blacklistedHomeSections
                                                        .removeAt(idx - 1);
                                                    Hive.box('settings').put(
                                                      'blacklistedHomeSections',
                                                      blacklistedHomeSections,
                                                    );
                                                    listKey.currentState!
                                                        .removeItem(
                                                      idx,
                                                      (
                                                        context,
                                                        animation,
                                                      ) =>
                                                          Container(),
                                                    );
                                                  },
                                                ),
                                              ),
                                            );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .showPlaylists,
                          ),
                          keyName: 'showPlaylist',
                          defaultValue: true,
                          onChanged: (val, box) {
                            widget.callback!();
                          },
                        ),

                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .showLast,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .showLastSub,
                          ),
                          keyName: 'showRecent',
                          defaultValue: true,
                          onChanged: (val, box) {
                            widget.callback!();
                          },
                        ),
                        // BoxSwitchTile(
                        //   title: Text(
                        //     AppLocalizations.of(
                        //       context,
                        //     )!
                        //         .showHistory,
                        //   ),
                        //   subtitle: Text(
                        //     AppLocalizations.of(
                        //       context,
                        //     )!
                        //         .showHistorySub,
                        //   ),
                        //   keyName: 'showHistory',
                        //   defaultValue: true,
                        // ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .enableGesture,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .enableGestureSub,
                          ),
                          keyName: 'enableGesture',
                          defaultValue: true,
                          isThreeLine: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            15,
                            15,
                            15,
                            0,
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .musicPlayback,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .musicLang,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .musicLangSub,
                          ),
                          trailing: SizedBox(
                            width: 150,
                            child: Text(
                              preferredLanguage.isEmpty
                                  ? 'None'
                                  : preferredLanguage.join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                          dense: true,
                          onTap: () {
                            showModalBottomSheet(
                              isDismissible: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (BuildContext context) {
                                final List checked =
                                    List.from(preferredLanguage);
                                return StatefulBuilder(
                                  builder: (
                                    BuildContext context,
                                    StateSetter setStt,
                                  ) {
                                    return BottomGradientContainer(
                                      borderRadius: BorderRadius.circular(
                                        20.0,
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ListView.builder(
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              shrinkWrap: true,
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                0,
                                                10,
                                                0,
                                                10,
                                              ),
                                              itemCount: languages.length,
                                              itemBuilder: (context, idx) {
                                                return CheckboxListTile(
                                                  activeColor: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                  checkColor: Theme.of(context)
                                                              .colorScheme
                                                              .secondary ==
                                                          Colors.white
                                                      ? Colors.black
                                                      : null,
                                                  value: checked.contains(
                                                    languages[idx],
                                                  ),
                                                  title: Text(
                                                    languages[idx],
                                                  ),
                                                  onChanged: (bool? value) {
                                                    value!
                                                        ? checked
                                                            .add(languages[idx])
                                                        : checked.remove(
                                                            languages[idx],
                                                          );
                                                    setStt(
                                                      () {},
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .cancel,
                                                ),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                ),
                                                onPressed: () {
                                                  setState(
                                                    () {
                                                      preferredLanguage =
                                                          checked;
                                                      Navigator.pop(context);
                                                      Hive.box('settings').put(
                                                        'preferredLanguage',
                                                        checked,
                                                      );
                                                      home_screen.fetched =
                                                          false;
                                                      home_screen
                                                              .preferredLanguage =
                                                          preferredLanguage;
                                                      widget.callback!();
                                                    },
                                                  );
                                                  if (preferredLanguage
                                                      .isEmpty) {
                                                    ShowSnackBar().showSnackBar(
                                                      context,
                                                      AppLocalizations.of(
                                                        context,
                                                      )!
                                                          .noLangSelected,
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .ok,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        // ListTile(
                        //   title: Text(
                        //     AppLocalizations.of(
                        //       context,
                        //     )!
                        //         .chartLocation,
                        //   ),
                        //   subtitle: Text(
                        //     AppLocalizations.of(
                        //       context,
                        //     )!
                        //         .chartLocationSub,
                        //   ),
                        //   trailing: SizedBox(
                        //     width: 150,
                        //     child: Text(
                        //       region,
                        //       textAlign: TextAlign.end,
                        //     ),
                        //   ),
                        //   dense: true,
                        //   onTap: () async {
                        //     region = await SpotifyCountry()
                        //         .changeCountry(context: context);
                        //     setState(
                        //       () {},
                        //     );
                        //   },
                        // ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .streamQuality,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .streamQualitySub,
                          ),
                          onTap: () {},
                          trailing: DropdownButton(
                            value: streamingQuality,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color,
                            ),
                            underline: const SizedBox(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(
                                  () {
                                    streamingQuality = newValue;
                                    Hive.box('settings')
                                        .put('streamingQuality', newValue);
                                  },
                                );
                              }
                            },
                            items: <String>['96 kbps', '160 kbps', '320 kbps']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          dense: true,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .ytStreamQuality,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .ytStreamQualitySub,
                          ),
                          onTap: () {},
                          trailing: DropdownButton(
                            value: ytQuality,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color,
                            ),
                            underline: const SizedBox(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(
                                  () {
                                    ytQuality = newValue;
                                    Hive.box('settings')
                                        .put('ytQuality', newValue);
                                  },
                                );
                              }
                            },
                            items: <String>['Low', 'High']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                          dense: true,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .loadLast,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .loadLastSub,
                          ),
                          keyName: 'loadStart',
                          defaultValue: true,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .resetOnSkip,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .resetOnSkipSub,
                          ),
                          keyName: 'resetOnSkip',
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .enforceRepeat,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .enforceRepeatSub,
                          ),
                          keyName: 'enforceRepeat',
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .autoplay,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .autoplaySub,
                          ),
                          keyName: 'autoplay',
                          defaultValue: true,
                          isThreeLine: true,
                        ),
                        // BoxSwitchTile(
                        //   title: Text(
                        //     AppLocalizations.of(
                        //       context,
                        //     )!
                        //         .cacheSong,
                        //   ),
                        //   subtitle: Text(
                        //     AppLocalizations.of(
                        //       context,
                        //     )!
                        //         .cacheSongSub,
                        //   ),
                        //   keyName: 'cacheSong',
                        //   defaultValue: false,
                        // ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            15,
                            15,
                            15,
                            0,
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .down,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .downQuality,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .downQualitySub,
                          ),
                          onTap: () {},
                          trailing: DropdownButton(
                            value: downloadQuality,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color,
                            ),
                            underline: const SizedBox(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(
                                  () {
                                    downloadQuality = newValue;
                                    Hive.box('settings')
                                        .put('downloadQuality', newValue);
                                  },
                                );
                              }
                            },
                            items: <String>['96 kbps', '160 kbps', '320 kbps']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                ),
                              );
                            }).toList(),
                          ),
                          dense: true,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .ytDownQuality,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .ytDownQualitySub,
                          ),
                          onTap: () {},
                          trailing: DropdownButton(
                            value: ytDownloadQuality,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color,
                            ),
                            underline: const SizedBox(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(
                                  () {
                                    ytDownloadQuality = newValue;
                                    Hive.box('settings')
                                        .put('ytDownloadQuality', newValue);
                                  },
                                );
                              }
                            },
                            items: <String>['Low', 'High']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                ),
                              );
                            }).toList(),
                          ),
                          dense: true,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .downLocation,
                          ),
                          subtitle: Text(downloadPath),
                          trailing: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () async {
                              downloadPath =
                                  await ExtStorageProvider.getExtStorage(
                                        dirName: 'Music',
                                      ) ??
                                      '/storage/emulated/0/Music';
                              Hive.box('settings')
                                  .put('downloadPath', downloadPath);
                              setState(
                                () {},
                              );
                            },
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!
                                  .reset,
                            ),
                          ),
                          onTap: () async {
                            final String temp = await Picker.selectFolder(
                              context: context,
                              message: AppLocalizations.of(
                                context,
                              )!
                                  .selectDownLocation,
                            );
                            if (temp.trim() != '') {
                              downloadPath = temp;
                              Hive.box('settings').put('downloadPath', temp);
                              setState(
                                () {},
                              );
                            } else {
                              ShowSnackBar().showSnackBar(
                                context,
                                AppLocalizations.of(
                                  context,
                                )!
                                    .noFolderSelected,
                              );
                            }
                          },
                          dense: true,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .downFilename,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .downFilenameSub,
                          ),
                          dense: true,
                          onTap: () {
                            showModalBottomSheet(
                              isDismissible: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (BuildContext context) {
                                return BottomGradientContainer(
                                  borderRadius: BorderRadius.circular(
                                    20.0,
                                  ),
                                  child: ListView(
                                    physics: const BouncingScrollPhysics(),
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      10,
                                      0,
                                      10,
                                    ),
                                    children: [
                                      CheckboxListTile(
                                        activeColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        title: Text(
                                          '${AppLocalizations.of(context)!.title} - ${AppLocalizations.of(context)!.artist}',
                                        ),
                                        value: downFilename == 0,
                                        selected: downFilename == 0,
                                        onChanged: (bool? val) {
                                          if (val ?? false) {
                                            downFilename = 0;
                                            settingsBox.put('downFilename', 0);
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      CheckboxListTile(
                                        activeColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        title: Text(
                                          '${AppLocalizations.of(context)!.artist} - ${AppLocalizations.of(context)!.title}',
                                        ),
                                        value: downFilename == 1,
                                        selected: downFilename == 1,
                                        onChanged: (val) {
                                          if (val ?? false) {
                                            downFilename = 1;
                                            settingsBox.put('downFilename', 1);
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                      CheckboxListTile(
                                        activeColor: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        title: Text(
                                          AppLocalizations.of(context)!.title,
                                        ),
                                        value: downFilename == 2,
                                        selected: downFilename == 2,
                                        onChanged: (val) {
                                          if (val ?? false) {
                                            downFilename = 2;
                                            settingsBox.put('downFilename', 2);
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .createAlbumFold,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .createAlbumFoldSub,
                          ),
                          keyName: 'createDownloadFolder',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .createYtFold,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .createYtFoldSub,
                          ),
                          keyName: 'createYoutubeFolder',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .downLyrics,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .downLyricsSub,
                          ),
                          keyName: 'downloadLyrics',
                          defaultValue: false,
                          isThreeLine: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            15,
                            15,
                            15,
                            0,
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .others,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .lang,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .langSub,
                          ),
                          onTap: () {},
                          trailing: DropdownButton(
                            value: lang,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color,
                            ),
                            underline: const SizedBox(),
                            onChanged: (String? newValue) {
                              final Map<String, String> codes = {
                                'Chinese': 'zh',
                                'Czech': 'cs',
                                'Dutch': 'nl',
                                'English': 'en',
                                'French': 'fr',
                                'German': 'de',
                                'Hebrew': 'he',
                                'Hindi': 'hi',
                                'Hungarian': 'hu',
                                'Indonesian': 'id',
                                'Italian': 'it',
                                'Polish': 'pl',
                                'Portuguese': 'pt',
                                'Russian': 'ru',
                                'Spanish': 'es',
                                'Tamil': 'ta',
                                'Turkish': 'tr',
                                'Ukrainian': 'uk',
                                'Urdu': 'ur',
                              };
                              if (newValue != null) {
                                setState(
                                  () {
                                    lang = newValue;
                                    MyApp.of(context).setLocale(
                                      Locale.fromSubtags(
                                        languageCode: codes[newValue]!,
                                      ),
                                    );
                                    Hive.box('settings').put('lang', newValue);
                                  },
                                );
                              }
                            },
                            items: <String>[
                              'Chinese',
                              'Czech',
                              'Dutch',
                              'English',
                              'French',
                              'German',
                              'Hebrew',
                              'Hindi',
                              'Hungarian',
                              'Indonesian',
                              'Italian',
                              'Polish',
                              'Portuguese',
                              'Russian',
                              'Spanish',
                              'Tamil',
                              'Turkish',
                              'Ukrainian',
                              'Urdu',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                ),
                              );
                            }).toList(),
                          ),
                          dense: true,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .includeExcludeFolder,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .includeExcludeFolderSub,
                          ),
                          dense: true,
                          onTap: () {
                            final GlobalKey<AnimatedListState> listKey =
                                GlobalKey<AnimatedListState>();
                            showModalBottomSheet(
                              isDismissible: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (BuildContext context) {
                                return BottomGradientContainer(
                                  borderRadius: BorderRadius.circular(
                                    20.0,
                                  ),
                                  child: AnimatedList(
                                    physics: const BouncingScrollPhysics(),
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.fromLTRB(
                                      0,
                                      10,
                                      0,
                                      10,
                                    ),
                                    key: listKey,
                                    initialItemCount:
                                        includedExcludedPaths.length + 2,
                                    itemBuilder: (cntxt, idx, animation) {
                                      if (idx == 0) {
                                        return ValueListenableBuilder(
                                          valueListenable: includeOrExclude,
                                          builder: (
                                            BuildContext context,
                                            bool value,
                                            Widget? widget,
                                          ) {
                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: <Widget>[
                                                    ChoiceChip(
                                                      label: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!
                                                            .excluded,
                                                      ),
                                                      selectedColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                              .withOpacity(0.2),
                                                      labelStyle: TextStyle(
                                                        color: !value
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .secondary
                                                            : Theme.of(context)
                                                                .textTheme
                                                                .bodyText1!
                                                                .color,
                                                        fontWeight: !value
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                      selected: !value,
                                                      onSelected:
                                                          (bool selected) {
                                                        includeOrExclude.value =
                                                            !selected;
                                                        settingsBox.put(
                                                          'includeOrExclude',
                                                          !selected,
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(
                                                      width: 5,
                                                    ),
                                                    ChoiceChip(
                                                      label: Text(
                                                        AppLocalizations.of(
                                                          context,
                                                        )!
                                                            .included,
                                                      ),
                                                      selectedColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondary
                                                              .withOpacity(0.2),
                                                      labelStyle: TextStyle(
                                                        color: value
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .secondary
                                                            : Theme.of(context)
                                                                .textTheme
                                                                .bodyText1!
                                                                .color,
                                                        fontWeight: value
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                      selected: value,
                                                      onSelected:
                                                          (bool selected) {
                                                        includeOrExclude.value =
                                                            selected;
                                                        settingsBox.put(
                                                          'includeOrExclude',
                                                          selected,
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 5.0,
                                                    top: 5.0,
                                                    bottom: 10.0,
                                                  ),
                                                  child: Text(
                                                    value
                                                        ? AppLocalizations.of(
                                                            context,
                                                          )!
                                                            .includedDetails
                                                        : AppLocalizations.of(
                                                            context,
                                                          )!
                                                            .excludedDetails,
                                                    textAlign: TextAlign.start,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                      if (idx == 1) {
                                        return ListTile(
                                          title: Text(
                                            AppLocalizations.of(context)!
                                                .addNew,
                                          ),
                                          leading: const Icon(
                                            CupertinoIcons.add,
                                          ),
                                          onTap: () async {
                                            final String temp =
                                                await Picker.selectFolder(
                                              context: context,
                                            );
                                            if (temp.trim() != '' &&
                                                !includedExcludedPaths
                                                    .contains(temp)) {
                                              includedExcludedPaths.add(temp);
                                              Hive.box('settings').put(
                                                'includedExcludedPaths',
                                                includedExcludedPaths,
                                              );
                                              listKey.currentState!.insertItem(
                                                includedExcludedPaths.length,
                                              );
                                            } else {
                                              if (temp.trim() == '') {
                                                Navigator.pop(context);
                                              }
                                              ShowSnackBar().showSnackBar(
                                                context,
                                                temp.trim() == ''
                                                    ? 'No folder selected'
                                                    : 'Already added',
                                              );
                                            }
                                          },
                                        );
                                      }

                                      return SizeTransition(
                                        sizeFactor: animation,
                                        child: ListTile(
                                          leading: const Icon(
                                            CupertinoIcons.folder,
                                          ),
                                          title: Text(
                                            includedExcludedPaths[idx - 2]
                                                .toString(),
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(
                                              CupertinoIcons.clear,
                                              size: 15.0,
                                            ),
                                            tooltip: 'Remove',
                                            onPressed: () {
                                              includedExcludedPaths
                                                  .removeAt(idx - 2);
                                              Hive.box('settings').put(
                                                'includedExcludedPaths',
                                                includedExcludedPaths,
                                              );
                                              listKey.currentState!.removeItem(
                                                idx,
                                                (context, animation) =>
                                                    Container(),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .minAudioLen,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .minAudioLenSub,
                          ),
                          dense: true,
                          onTap: () {
                            showTextInputDialog(
                              context: context,
                              title: AppLocalizations.of(
                                context,
                              )!
                                  .minAudioAlert,
                              initialText: (Hive.box('settings')
                                          .get('minDuration', defaultValue: 10)
                                      as int)
                                  .toString(),
                              keyboardType: TextInputType.number,
                              onSubmitted: (String value) {
                                if (value.trim() == '') {
                                  value = '0';
                                }
                                Hive.box('settings')
                                    .put('minDuration', int.parse(value));
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .liveSearch,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .liveSearchSub,
                          ),
                          keyName: 'liveSearch',
                          isThreeLine: false,
                          defaultValue: true,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .useDown,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .useDownSub,
                          ),
                          keyName: 'useDown',
                          isThreeLine: true,
                          defaultValue: true,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .getLyricsOnline,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .getLyricsOnlineSub,
                          ),
                          keyName: 'getLyricsOnline',
                          isThreeLine: true,
                          defaultValue: true,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .supportEq,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .supportEqSub,
                          ),
                          keyName: 'supportEq',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .stopOnClose,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .stopOnCloseSub,
                          ),
                          isThreeLine: true,
                          keyName: 'stopForegroundService',
                          defaultValue: true,
                        ),
                        // const BoxSwitchTile(
                        //   title: Text('Remove Service from foreground when paused'),
                        //   subtitle: Text(
                        //       "If turned on, you can slide notification when paused to stop the service. But Service can also be stopped by android to release memory. If you don't want android to stop service while paused, turn it off\nDefault: On\n"),
                        //   isThreeLine: true,
                        //   keyName: 'stopServiceOnPause',
                        //   defaultValue: true,
                        // ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .checkUpdate,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .checkUpdateSub,
                          ),
                          keyName: 'checkUpdate',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .useProxy,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .useProxySub,
                          ),
                          keyName: 'useProxy',
                          defaultValue: false,
                          isThreeLine: true,
                          onChanged: (bool val, Box box) {
                            useProxy = val;
                            setState(
                              () {},
                            );
                          },
                        ),
                        Visibility(
                          visible: useProxy,
                          child: ListTile(
                            title: Text(
                              AppLocalizations.of(
                                context,
                              )!
                                  .proxySet,
                            ),
                            subtitle: Text(
                              AppLocalizations.of(
                                context,
                              )!
                                  .proxySetSub,
                            ),
                            dense: true,
                            trailing: Text(
                              '${Hive.box('settings').get("proxyIp")}:${Hive.box('settings').get("proxyPort")}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  final controller = TextEditingController(
                                    text: settingsBox.get('proxyIp').toString(),
                                  );
                                  final controller2 = TextEditingController(
                                    text:
                                        settingsBox.get('proxyPort').toString(),
                                  );
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        10.0,
                                      ),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .ipAdd,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextField(
                                          autofocus: true,
                                          controller: controller,
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .port,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextField(
                                          autofocus: true,
                                          controller: controller2,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .cancel,
                                        ),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context)
                                                      .colorScheme
                                                      .secondary ==
                                                  Colors.white
                                              ? Colors.black
                                              : null,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                        onPressed: () {
                                          settingsBox.put(
                                            'proxyIp',
                                            controller.text.trim(),
                                          );
                                          settingsBox.put(
                                            'proxyPort',
                                            int.parse(
                                              controller2.text.trim(),
                                            ),
                                          );
                                          Navigator.pop(context);
                                          setState(
                                            () {},
                                          );
                                        },
                                        child: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .ok,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .clearCache,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .clearCacheSub,
                          ),
                          trailing: SizedBox(
                            height: 70.0,
                            width: 70.0,
                            child: Center(
                              child: FutureBuilder(
                                future: File(Hive.box('cache').path!).length(),
                                builder: (
                                  BuildContext context,
                                  AsyncSnapshot<int> snapshot,
                                ) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    return Text(
                                      '${((snapshot.data ?? 0) / (1024 * 1024)).toStringAsFixed(2)} MB',
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          dense: true,
                          isThreeLine: true,
                          onTap: () async {
                            Hive.box('cache').clear();
                            setState(
                              () {},
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            15,
                            15,
                            15,
                            0,
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .backNRest,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .createBack,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .createBackSub,
                          ),
                          dense: true,
                          onTap: () {
                            showModalBottomSheet(
                              isDismissible: true,
                              backgroundColor: Colors.transparent,
                              context: context,
                              builder: (BuildContext context) {
                                final List playlistNames =
                                    Hive.box('settings').get(
                                  'playlistNames',
                                  defaultValue: ['Favorite Songs'],
                                ) as List;
                                if (!playlistNames.contains('Favorite Songs')) {
                                  playlistNames.insert(0, 'Favorite Songs');
                                  settingsBox.put(
                                    'playlistNames',
                                    playlistNames,
                                  );
                                }

                                final List<String> persist = [
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .settings,
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .playlists,
                                ];

                                final List<String> checked = [
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .settings,
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .downs,
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .playlists,
                                ];

                                final List<String> items = [
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .settings,
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .playlists,
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .downs,
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .cache,
                                ];

                                final Map<String, List> boxNames = {
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .settings: ['settings'],
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .cache: ['cache'],
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .downs: ['downloads'],
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .playlists: playlistNames,
                                };
                                return StatefulBuilder(
                                  builder: (
                                    BuildContext context,
                                    StateSetter setStt,
                                  ) {
                                    return BottomGradientContainer(
                                      borderRadius: BorderRadius.circular(
                                        20.0,
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ListView.builder(
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              shrinkWrap: true,
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                0,
                                                10,
                                                0,
                                                10,
                                              ),
                                              itemCount: items.length,
                                              itemBuilder: (context, idx) {
                                                return CheckboxListTile(
                                                  activeColor: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                  checkColor: Theme.of(context)
                                                              .colorScheme
                                                              .secondary ==
                                                          Colors.white
                                                      ? Colors.black
                                                      : null,
                                                  value: checked.contains(
                                                    items[idx],
                                                  ),
                                                  title: Text(
                                                    items[idx],
                                                  ),
                                                  onChanged: persist
                                                          .contains(items[idx])
                                                      ? null
                                                      : (bool? value) {
                                                          value!
                                                              ? checked.add(
                                                                  items[idx],
                                                                )
                                                              : checked.remove(
                                                                  items[idx],
                                                                );
                                                          setStt(
                                                            () {},
                                                          );
                                                        },
                                                );
                                              },
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .cancel,
                                                ),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                ),
                                                onPressed: () {
                                                  createBackup(
                                                    context,
                                                    checked,
                                                    boxNames,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .ok,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .restore,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .restoreSub,
                          ),
                          dense: true,
                          onTap: () async {
                            await restore(context);
                            currentTheme.refresh();
                          },
                        ),
                        BoxSwitchTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .autoBack,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .autoBackSub,
                          ),
                          keyName: 'autoBackup',
                          defaultValue: false,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .autoBackLocation,
                          ),
                          subtitle: Text(autoBackPath),
                          trailing: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () async {
                              autoBackPath =
                                  await ExtStorageProvider.getExtStorage(
                                        dirName: 'BlackHole/Backups',
                                      ) ??
                                      '/storage/emulated/0/BlackHole/Backups';
                              Hive.box('settings')
                                  .put('autoBackPath', autoBackPath);
                              setState(
                                () {},
                              );
                            },
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!
                                  .reset,
                            ),
                          ),
                          onTap: () async {
                            final String temp = await Picker.selectFolder(
                              context: context,
                              message: AppLocalizations.of(
                                context,
                              )!
                                  .selectBackLocation,
                            );
                            if (temp.trim() != '') {
                              autoBackPath = temp;
                              Hive.box('settings').put('autoBackPath', temp);
                              setState(
                                () {},
                              );
                            } else {
                              ShowSnackBar().showSnackBar(
                                context,
                                AppLocalizations.of(
                                  context,
                                )!
                                    .noFolderSelected,
                              );
                            }
                          },
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            15,
                            15,
                            15,
                            0,
                          ),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .about,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .version,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .versionSub,
                          ),
                          onTap: () {
                            ShowSnackBar().showSnackBar(
                              context,
                              AppLocalizations.of(
                                context,
                              )!
                                  .checkingUpdate,
                              noAction: true,
                            );

                            SupaBase().getUpdate().then(
                              (Map value) async {
                                if (compareVersion(
                                  value['LatestVersion'].toString(),
                                  appVersion!,
                                )) {
                                  List? abis = await Hive.box('settings')
                                      .get('supportedAbis') as List?;

                                  if (abis == null) {
                                    final DeviceInfoPlugin deviceInfo =
                                        DeviceInfoPlugin();
                                    final AndroidDeviceInfo androidDeviceInfo =
                                        await deviceInfo.androidInfo;
                                    abis = androidDeviceInfo.supportedAbis;
                                    await Hive.box('settings')
                                        .put('supportedAbis', abis);
                                  }
                                  ShowSnackBar().showSnackBar(
                                    context,
                                    AppLocalizations.of(context)!
                                        .updateAvailable,
                                    duration: const Duration(seconds: 15),
                                    action: SnackBarAction(
                                      textColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      label:
                                          AppLocalizations.of(context)!.update,
                                      onPressed: () {
                                        Navigator.pop(context);
                                        if (abis!.contains('arm64-v8a')) {
                                          launchUrl(
                                            Uri.parse(
                                              value['arm64-v8a'] as String,
                                            ),
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } else {
                                          if (abis.contains('armeabi-v7a')) {
                                            launchUrl(
                                              Uri.parse(
                                                value['armeabi-v7a'] as String,
                                              ),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          } else {
                                            launchUrl(
                                              Uri.parse(
                                                value['universal'] as String,
                                              ),
                                              mode: LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  );
                                } else {
                                  ShowSnackBar().showSnackBar(
                                    context,
                                    AppLocalizations.of(
                                      context,
                                    )!
                                        .latest,
                                  );
                                }
                              },
                            );
                          },
                          trailing: Text(
                            'v$appVersion',
                            style: const TextStyle(fontSize: 12),
                          ),
                          dense: true,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .shareApp,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .shareAppSub,
                          ),
                          onTap: () {
                            Share.share(
                              '${AppLocalizations.of(
                                context,
                              )!.shareAppText}: https://github.com/Sangwan5688/BlackHole',
                            );
                          },
                          dense: true,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .likedWork,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .buyCoffee,
                          ),
                          dense: true,
                          onTap: () {
                            launchUrl(
                              Uri.parse(
                                'https://www.buymeacoffee.com/ankitsangwan',
                              ),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .donateGpay,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .donateGpaySub,
                          ),
                          dense: true,
                          isThreeLine: true,
                          onTap: () {
                            const String upiUrl =
                                'upi://pay?pa=ankit.sangwan.5688@oksbi&pn=BlackHole';
                            launchUrl(
                              Uri.parse(upiUrl),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          onLongPress: () {
                            copyToClipboard(
                              context: context,
                              text: 'ankit.sangwan.5688@oksbi',
                              displayText: AppLocalizations.of(
                                context,
                              )!
                                  .upiCopied,
                            );
                          },
                          trailing: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () {
                              copyToClipboard(
                                context: context,
                                text: 'ankit.sangwan.5688@oksbi',
                                displayText: AppLocalizations.of(
                                  context,
                                )!
                                    .upiCopied,
                              );
                            },
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!
                                  .copy,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .contactUs,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .contactUsSub,
                          ),
                          dense: true,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return SizedBox(
                                  height: 100,
                                  child: GradientContainer(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                MdiIcons.gmail,
                                              ),
                                              iconSize: 40,
                                              tooltip: AppLocalizations.of(
                                                context,
                                              )!
                                                  .gmail,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launchUrl(
                                                  Uri.parse(
                                                    'https://mail.google.com/mail/?extsrc=mailto&url=mailto%3A%3Fto%3Dblackholeyoucantescape%40gmail.com%26subject%3DRegarding%2520Mobile%2520App',
                                                  ),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              },
                                            ),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .gmail,
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                MdiIcons.telegram,
                                              ),
                                              iconSize: 40,
                                              tooltip: AppLocalizations.of(
                                                context,
                                              )!
                                                  .tg,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launchUrl(
                                                  Uri.parse(
                                                    'https://t.me/joinchat/fHDC1AWnOhw0ZmI9',
                                                  ),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              },
                                            ),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .tg,
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                MdiIcons.instagram,
                                              ),
                                              iconSize: 40,
                                              tooltip: AppLocalizations.of(
                                                context,
                                              )!
                                                  .insta,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launchUrl(
                                                  Uri.parse(
                                                    'https://instagram.com/sangwan5688',
                                                  ),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              },
                                            ),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .insta,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .joinTg,
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .joinTgSub,
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return SizedBox(
                                  height: 100,
                                  child: GradientContainer(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                MdiIcons.telegram,
                                              ),
                                              iconSize: 40,
                                              tooltip: AppLocalizations.of(
                                                context,
                                              )!
                                                  .tgGp,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launchUrl(
                                                  Uri.parse(
                                                    'https://t.me/joinchat/fHDC1AWnOhw0ZmI9',
                                                  ),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              },
                                            ),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .tgGp,
                                            ),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                MdiIcons.telegram,
                                              ),
                                              iconSize: 40,
                                              tooltip: AppLocalizations.of(
                                                context,
                                              )!
                                                  .tgCh,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launchUrl(
                                                  Uri.parse(
                                                    'https://t.me/blackhole_official',
                                                  ),
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              },
                                            ),
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              )!
                                                  .tgCh,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          dense: true,
                        ),
                        ListTile(
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!
                                .moreInfo,
                          ),
                          dense: true,
                          onTap: () {
                            Navigator.pushNamed(context, '/about');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    5,
                    30,
                    5,
                    20,
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!
                          .madeBy,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void switchToCustomTheme() {
    const custom = 'Custom';
    if (theme != custom) {
      currentTheme.setInitialTheme(custom);
      setState(
        () {
          theme = custom;
        },
      );
    }
  }
}

class BoxSwitchTile extends StatelessWidget {
  const BoxSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.keyName,
    required this.defaultValue,
    this.isThreeLine,
    this.onChanged,
  });

  final Text title;
  final Text? subtitle;
  final String keyName;
  final bool defaultValue;
  final bool? isThreeLine;
  final Function(bool, Box box)? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (BuildContext context, Box box, Widget? widget) {
        return SwitchListTile(
          activeColor: Theme.of(context).colorScheme.secondary,
          title: title,
          subtitle: subtitle,
          isThreeLine: isThreeLine ?? false,
          dense: true,
          value: box.get(keyName, defaultValue: defaultValue) as bool? ??
              defaultValue,
          onChanged: (val) {
            box.put(keyName, val);
            onChanged?.call(val, box);
          },
        );
      },
    );
  }
}

// NO LONGER AVAILABLE
// class SpotifyCountry {
//   Future<String> changeCountry({required BuildContext context}) async {
//     String region =
//         Hive.box('settings').get('region', defaultValue: 'India') as String;
//     await showModalBottomSheet(
//       isDismissible: true,
//       backgroundColor: Colors.transparent,
//       context: context,
//       builder: (BuildContext context) {
//         const Map<String, String> codes = CountryCodes.countryCodes;
//         final List<String> countries = codes.keys.toList();
//         return BottomGradientContainer(
//           borderRadius: BorderRadius.circular(
//             20.0,
//           ),
//           child: ListView.builder(
//             physics: const BouncingScrollPhysics(),
//             shrinkWrap: true,
//             padding: const EdgeInsets.fromLTRB(
//               0,
//               10,
//               0,
//               10,
//             ),
//             itemCount: countries.length,
//             itemBuilder: (context, idx) {
//               return ListTileTheme(
//                 selectedColor: Theme.of(context).colorScheme.secondary,
//                 child: ListTile(
//                   title: Text(
//                     countries[idx],
//                   ),
//                   leading: Radio(
//                     value: countries[idx],
//                     groupValue: region,
//                     onChanged: (value) {
//                       top_screen.items = [];
//                       region = countries[idx];
//                       top_screen.fetched = false;
//                       Hive.box('settings').put('region', region);
//                       Navigator.pop(context);
//                     },
//                   ),
//                   selected: region == countries[idx],
//                   onTap: () {
//                     top_screen.items = [];
//                     region = countries[idx];
//                     top_screen.fetched = false;
//                     Hive.box('settings').put('region', region);
//                     Navigator.pop(context);
//                   },
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//     return region;
//   }
// }
