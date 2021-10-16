import 'dart:io';

import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/backup_restore.dart';
import 'package:blackhole/Helpers/config.dart';
import 'package:blackhole/Helpers/countrycodes.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Helpers/supabase.dart';
import 'package:blackhole/Screens/Home/saavn.dart' as home_screen;
import 'package:blackhole/Screens/Top Charts/top.dart' as top_screen;
import 'package:blackhole/Services/ext_storage_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info/package_info.dart';
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
  Box settingsBox = Hive.box('settings');
  String downloadPath = Hive.box('settings')
      .get('downloadPath', defaultValue: '/storage/emulated/0/Music') as String;
  // List dirPaths =
  // Hive.box('settings').get('blacklistedPaths', defaultValue: []) as List;
  String streamingQuality = Hive.box('settings')
      .get('streamingQuality', defaultValue: '96 kbps') as String;
  String downloadQuality = Hive.box('settings')
      .get('downloadQuality', defaultValue: '320 kbps') as String;
  String canvasColor =
      Hive.box('settings').get('canvasColor', defaultValue: 'Grey') as String;
  String cardColor =
      Hive.box('settings').get('cardColor', defaultValue: 'Grey850') as String;
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
  List preferredLanguage = Hive.box('settings')
      .get('preferredLanguage', defaultValue: ['Hindi'])?.toList() as List;

  @override
  void initState() {
    main();
    super.initState();
  }

  Future<void> main() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    setState(() {});
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
      body: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
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
                  AppLocalizations.of(context)!.settings,
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
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                  child: GradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                          child: Text(
                            AppLocalizations.of(context)!.theme,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        BoxSwitchTile(
                            title: Text(AppLocalizations.of(context)!.darkMode),
                            keyName: 'darkMode',
                            defaultValue: true,
                            onChanged: (bool val, Box box) {
                              box.put('useSystemTheme', false);
                              currentTheme.switchTheme(
                                  isDark: val, useSystemTheme: false);
                              switchToCustomTheme();
                            }),
                        BoxSwitchTile(
                            title: Text(
                                AppLocalizations.of(context)!.useSystemTheme),
                            keyName: 'useSystemTheme',
                            defaultValue: true,
                            onChanged: (bool val, Box box) {
                              currentTheme.switchTheme(useSystemTheme: val);
                              switchToCustomTheme();
                            }),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.accent),
                          subtitle: Text('$themeColor, $colorHue'),
                          trailing: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              height: 25,
                              width: 25,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100.0),
                                color: Theme.of(context).colorScheme.secondary,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[900]!,
                                    blurRadius: 5.0,
                                    offset: const Offset(0.0, 3.0),
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
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 10, 0, 10),
                                      itemCount: colors.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 15.0),
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
                                                      themeColor =
                                                          colors[index];
                                                      colorHue = hue;
                                                      currentTheme.switchColor(
                                                          colors[index],
                                                          colorHue);
                                                      setState(() {});
                                                      switchToCustomTheme();
                                                      Navigator.pop(context);
                                                    },
                                                    child: Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.125,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.125,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    100.0),
                                                        color: MyTheme()
                                                            .getColor(
                                                                colors[index],
                                                                hue),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .grey[900]!,
                                                            blurRadius: 5.0,
                                                            offset:
                                                                const Offset(
                                                                    0.0, 3.0),
                                                          )
                                                        ],
                                                      ),
                                                      child: (themeColor ==
                                                                  colors[
                                                                      index] &&
                                                              colorHue == hue)
                                                          ? const Icon(Icons
                                                              .done_rounded)
                                                          : const SizedBox(),
                                                    )),
                                            ],
                                          ),
                                        );
                                      }),
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
                                title:
                                    Text(AppLocalizations.of(context)!.bgGrad),
                                subtitle: Text(
                                    AppLocalizations.of(context)!.bgGradSub),
                                trailing: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(100.0),
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
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey[900]!,
                                          blurRadius: 5.0,
                                          offset: const Offset(0.0, 3.0),
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
                                      final List<List<Color>> gradients =
                                          currentTheme.backOpt;
                                      return BottomGradientContainer(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        child: ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 10, 0, 10),
                                            itemCount: gradients.length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 15.0),
                                                child: GestureDetector(
                                                    onTap: () {
                                                      settingsBox.put(
                                                          'backGrad', index);
                                                      currentTheme.backGrad =
                                                          index;
                                                      widget.callback!();
                                                      switchToCustomTheme();
                                                      Navigator.pop(context);
                                                      setState(() {});
                                                    },
                                                    child: Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.125,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.125,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    100.0),
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors:
                                                              gradients[index],
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .grey[900]!,
                                                            blurRadius: 5.0,
                                                            offset:
                                                                const Offset(
                                                                    0.0, 3.0),
                                                          )
                                                        ],
                                                      ),
                                                      child: (currentTheme
                                                                  .getBackGradient() ==
                                                              gradients[index])
                                                          ? const Icon(Icons
                                                              .done_rounded)
                                                          : const SizedBox(),
                                                    )),
                                              );
                                            }),
                                      );
                                    },
                                  );
                                },
                                dense: true,
                              ),
                              ListTile(
                                title: Text(
                                    AppLocalizations.of(context)!.cardGrad),
                                subtitle: Text(
                                    AppLocalizations.of(context)!.cardGradSub),
                                trailing: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(100.0),
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
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey[900]!,
                                          blurRadius: 5.0,
                                          offset: const Offset(0.0, 3.0),
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
                                      final List<List<Color>> gradients =
                                          currentTheme.cardOpt;
                                      return BottomGradientContainer(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        child: ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 10, 0, 10),
                                            itemCount: gradients.length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 15.0),
                                                child: GestureDetector(
                                                    onTap: () {
                                                      settingsBox.put(
                                                          'cardGrad', index);
                                                      currentTheme.cardGrad =
                                                          index;
                                                      widget.callback!();
                                                      switchToCustomTheme();
                                                      Navigator.pop(context);
                                                      setState(() {});
                                                    },
                                                    child: Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.125,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.125,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    100.0),
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors:
                                                              gradients[index],
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .grey[900]!,
                                                            blurRadius: 5.0,
                                                            offset:
                                                                const Offset(
                                                                    0.0, 3.0),
                                                          )
                                                        ],
                                                      ),
                                                      child: (currentTheme
                                                                  .getCardGradient() ==
                                                              gradients[index])
                                                          ? const Icon(Icons
                                                              .done_rounded)
                                                          : const SizedBox(),
                                                    )),
                                              );
                                            }),
                                      );
                                    },
                                  );
                                },
                                dense: true,
                              ),
                              ListTile(
                                title: Text(
                                    AppLocalizations.of(context)!.bottomGrad),
                                subtitle: Text(AppLocalizations.of(context)!
                                    .bottomGradSub),
                                trailing: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(100.0),
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
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey[900]!,
                                          blurRadius: 5.0,
                                          offset: const Offset(0.0, 3.0),
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
                                      final List<List<Color>> gradients =
                                          currentTheme.backOpt;
                                      return BottomGradientContainer(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        child: ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 10, 0, 10),
                                            itemCount: gradients.length,
                                            itemBuilder: (context, index) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 15.0),
                                                child: GestureDetector(
                                                    onTap: () {
                                                      settingsBox.put(
                                                          'bottomGrad', index);
                                                      currentTheme.bottomGrad =
                                                          index;
                                                      switchToCustomTheme();
                                                      Navigator.pop(context);
                                                      setState(() {});
                                                    },
                                                    child: Container(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.125,
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.125,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    100.0),
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors:
                                                              gradients[index],
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .grey[900]!,
                                                            blurRadius: 5.0,
                                                            offset:
                                                                const Offset(
                                                                    0.0, 3.0),
                                                          )
                                                        ],
                                                      ),
                                                      child: (currentTheme
                                                                  .getBottomGradient() ==
                                                              gradients[index])
                                                          ? const Icon(Icons
                                                              .done_rounded)
                                                          : const SizedBox(),
                                                    )),
                                              );
                                            }),
                                      );
                                    },
                                  );
                                },
                                dense: true,
                              ),
                              ListTile(
                                title: Text(
                                    AppLocalizations.of(context)!.canvasColor),
                                subtitle: Text(AppLocalizations.of(context)!
                                    .canvasColorSub),
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
                                      setState(() {
                                        currentTheme
                                            .switchCanvasColor(newValue);
                                        canvasColor = newValue;
                                      });
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
                                    AppLocalizations.of(context)!.cardColor),
                                subtitle: Text(
                                    AppLocalizations.of(context)!.cardColorSub),
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
                                      setState(() {
                                        currentTheme.switchCardColor(newValue);
                                        cardColor = newValue;
                                      });
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
                        BoxSwitchTile(
                          title:
                              Text(AppLocalizations.of(context)!.useDominant),
                          subtitle: Text(
                              AppLocalizations.of(context)!.useDominantSub),
                          keyName: 'useImageColor',
                          defaultValue: true,
                          isThreeLine: true,
                        ),
                        ListTile(
                            title:
                                Text(AppLocalizations.of(context)!.useAmoled),
                            dense: true,
                            onTap: () {
                              currentTheme.switchTheme(
                                  useSystemTheme: false, isDark: true);
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
                              currentTheme.switchColor('White', colorHue);
                            }),
                        ListTile(
                          title:
                              Text(AppLocalizations.of(context)!.currentTheme),
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

                                setState(() {
                                  theme = themeChoice;
                                  if (themeChoice == 'Custom') return;
                                  final selectedTheme = userThemes[themeChoice];

                                  settingsBox.put(
                                    'backGrad',
                                    themeChoice == deflt
                                        ? 1
                                        : selectedTheme['backGrad'],
                                  );
                                  currentTheme.backGrad = themeChoice == deflt
                                      ? 1
                                      : selectedTheme['backGrad'] as int;

                                  settingsBox.put(
                                    'cardGrad',
                                    themeChoice == deflt
                                        ? 3
                                        : selectedTheme['cardGrad'],
                                  );
                                  currentTheme.cardGrad = themeChoice == deflt
                                      ? 3
                                      : selectedTheme['cardGrad'] as int;

                                  settingsBox.put(
                                    'bottomGrad',
                                    themeChoice == deflt
                                        ? 2
                                        : selectedTheme['bottomGrad'],
                                  );
                                  currentTheme.bottomGrad = themeChoice == deflt
                                      ? 2
                                      : selectedTheme['bottomGrad'] as int;

                                  currentTheme.switchCanvasColor(
                                      themeChoice == deflt
                                          ? 'Grey'
                                          : selectedTheme['canvasColor']
                                              as String,
                                      notify: false);
                                  canvasColor = themeChoice == deflt
                                      ? 'Grey'
                                      : selectedTheme['canvasColor'] as String;

                                  currentTheme.switchCardColor(
                                      themeChoice == deflt
                                          ? 'Grey850'
                                          : selectedTheme['cardColor']
                                              as String,
                                      notify: false);
                                  cardColor = themeChoice == deflt
                                      ? 'Grey850'
                                      : selectedTheme['cardColor'] as String;

                                  themeColor = themeChoice == deflt
                                      ? 'Teal'
                                      : selectedTheme['accentColor'] as String;
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
                                        selectedTheme['useSystemTheme'] as bool,
                                    isDark: themeChoice == deflt ||
                                        selectedTheme['isDark'] as bool,
                                  );
                                });
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
                                                title: Text(
                                                  AppLocalizations.of(context)!
                                                      .deleteTheme,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                                ),
                                                content: Text(
                                                    '${AppLocalizations.of(context)!.deleteThemeSubtitle} $value?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        Navigator.of(context)
                                                            .pop,
                                                    child: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .cancel),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      currentTheme
                                                          .deleteTheme(value);
                                                      if (currentTheme
                                                              .getInitialTheme() ==
                                                          value) {
                                                        currentTheme
                                                            .setInitialTheme(
                                                                'Custom');
                                                        theme = 'Custom';
                                                      }
                                                      setState(() {
                                                        userThemes =
                                                            currentTheme
                                                                .getThemes();
                                                      });
                                                      ShowSnackBar()
                                                          .showSnackBar(
                                                        context,
                                                        AppLocalizations.of(
                                                                context)!
                                                            .themeDeleted,
                                                      );
                                                      return Navigator.of(
                                                              context)
                                                          .pop();
                                                    },
                                                    child: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .delete,
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .error,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          icon: Icon(
                                            Icons.delete,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
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
                            title:
                                Text(AppLocalizations.of(context)!.saveTheme),
                            onTap: () {
                              final initialThemeName =
                                  '${AppLocalizations.of(context)!.theme} ${userThemes.length + 1}';
                              TextInputDialog().showTextInputDialog(
                                context: context,
                                title: AppLocalizations.of(context)!
                                    .enterThemeName,
                                onSubmitted: (value) {
                                  if (value == '') return;
                                  currentTheme.saveTheme(value);
                                  currentTheme.setInitialTheme(value);
                                  setState(() {
                                    userThemes = currentTheme.getThemes();
                                    theme = value;
                                  });
                                  ShowSnackBar().showSnackBar(
                                    context,
                                    AppLocalizations.of(context)!.themeSaved,
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                child: GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                        child: Text(
                          AppLocalizations.of(context)!.musicPlayback,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.musicLang),
                        subtitle:
                            Text(AppLocalizations.of(context)!.musicLangSub),
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
                                return StatefulBuilder(builder:
                                    (BuildContext context, StateSetter setStt) {
                                  return BottomGradientContainer(
                                    borderRadius: BorderRadius.circular(20.0),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: ListView.builder(
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              shrinkWrap: true,
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 10, 0, 10),
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
                                                  value: checked
                                                      .contains(languages[idx]),
                                                  title: Text(languages[idx]),
                                                  onChanged: (bool? value) {
                                                    value!
                                                        ? checked
                                                            .add(languages[idx])
                                                        : checked.remove(
                                                            languages[idx]);
                                                    setStt(() {});
                                                  },
                                                );
                                              }),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                primary: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                  AppLocalizations.of(context)!
                                                      .cancel),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                primary: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  preferredLanguage = checked;
                                                  Navigator.pop(context);
                                                  Hive.box('settings').put(
                                                      'preferredLanguage',
                                                      checked);
                                                  home_screen.fetched = false;
                                                  home_screen
                                                          .preferredLanguage =
                                                      preferredLanguage;
                                                  widget.callback!();
                                                });
                                                if (preferredLanguage.isEmpty) {
                                                  ShowSnackBar().showSnackBar(
                                                    context,
                                                    AppLocalizations.of(
                                                            context)!
                                                        .noLangSelected,
                                                  );
                                                }
                                              },
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .ok,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                });
                              });
                        },
                      ),
                      ListTile(
                          title:
                              Text(AppLocalizations.of(context)!.chartLocation),
                          subtitle: Text(
                              AppLocalizations.of(context)!.chartLocationSub),
                          trailing: SizedBox(
                            width: 150,
                            child: Text(
                              region,
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
                                  final Map<String, String> codes =
                                      CountryCodes().countryCodes;
                                  final List<String> countries =
                                      codes.keys.toList();
                                  return BottomGradientContainer(
                                    borderRadius: BorderRadius.circular(20.0),
                                    child: ListView.builder(
                                        physics: const BouncingScrollPhysics(),
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 10, 0, 10),
                                        itemCount: countries.length,
                                        itemBuilder: (context, idx) {
                                          return ListTileTheme(
                                            selectedColor: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                      left: 25.0, right: 25.0),
                                              title: Text(countries[idx]),
                                              trailing: region == countries[idx]
                                                  ? const Icon(
                                                      Icons.check_rounded)
                                                  : const SizedBox(),
                                              selected:
                                                  region == countries[idx],
                                              onTap: () {
                                                top_screen.items = [];
                                                region = countries[idx];
                                                top_screen.fetched = false;
                                                Hive.box('settings')
                                                    .put('region', region);

                                                Navigator.pop(context);
                                                widget.callback!();
                                                setState(() {});
                                              },
                                            ),
                                          );
                                        }),
                                  );
                                });
                          }),
                      ListTile(
                        title:
                            Text(AppLocalizations.of(context)!.streamQuality),
                        subtitle: Text(
                            AppLocalizations.of(context)!.streamQualitySub),
                        onTap: () {},
                        trailing: DropdownButton(
                          value: streamingQuality,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodyText1!.color,
                          ),
                          underline: const SizedBox(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                streamingQuality = newValue;
                                Hive.box('settings')
                                    .put('streamingQuality', newValue);
                              });
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
                      BoxSwitchTile(
                        title: Text(AppLocalizations.of(context)!.loadLast),
                        subtitle:
                            Text(AppLocalizations.of(context)!.loadLastSub),
                        keyName: 'loadStart',
                        defaultValue: true,
                      ),
                      BoxSwitchTile(
                        title:
                            Text(AppLocalizations.of(context)!.enforceRepeat),
                        subtitle: Text(
                            AppLocalizations.of(context)!.enforceRepeatSub),
                        keyName: 'enforceRepeat',
                        defaultValue: false,
                      ),
                      BoxSwitchTile(
                        title: Text(AppLocalizations.of(context)!.autoplay),
                        subtitle:
                            Text(AppLocalizations.of(context)!.autoplaySub),
                        keyName: 'autoplay',
                        defaultValue: true,
                      ),
                      //   ListTile(
                      //       title: const Text('BlackList Location'),
                      //       subtitle: const Text(
                      //           'Locations blacklisted from "My Music" section'),
                      //       dense: true,
                      //       onTap: () {
                      //         final GlobalKey<AnimatedListState> _listKey =
                      //             GlobalKey<AnimatedListState>();
                      //         showModalBottomSheet(
                      //             isDismissible: true,
                      //             backgroundColor: Colors.transparent,
                      //             context: context,
                      //             builder: (BuildContext context) {
                      //               return BottomGradientContainer(
                      //                 borderRadius: BorderRadius.circular(20.0),
                      //                 child: AnimatedList(
                      //                   physics: const BouncingScrollPhysics(),
                      //                   shrinkWrap: true,
                      //                   padding: const EdgeInsets.fromLTRB(
                      //                       0, 10, 0, 10),
                      //                   key: _listKey,
                      //                   initialItemCount: dirPaths.length + 1,
                      //                   itemBuilder: (cntxt, idx, animation) {
                      //                     return (idx == 0)
                      //                         ? ListTile(
                      //                             title:
                      //                                 const Text('Add Location'),
                      //                             leading: const Icon(
                      //                                 CupertinoIcons.add),
                      //                             onTap: () async {
                      //                               final String temp =
                      //                                   await Picker()
                      //                                       .selectFolder(context,
                      //                                           'Select Folder');
                      //                               if (temp.trim() != '' &&
                      //                                   !dirPaths
                      //                                       .contains(temp)) {
                      //                                 dirPaths.add(temp);
                      //                                 Hive.box('settings').put(
                      //                                     'blacklistedPaths',
                      //                                     dirPaths);
                      //                                 _listKey.currentState!
                      //                                     .insertItem(
                      //                                         dirPaths.length);
                      //                               } else {
                      //                                 if (temp.trim() == '') {
                      //                                   Navigator.pop(context);
                      //                                 }
                      //                                 ShowSnackBar().showSnackBar(
                      //                                   context,
                      //                                   temp.trim() == ''
                      //                                       ? 'No folder selected'
                      //                                       : 'Already added',
                      //                                 );
                      //                               }
                      //                             },
                      //                           )
                      //                         : SizeTransition(
                      //                             sizeFactor: animation,
                      //                             child: ListTile(
                      //                               leading: const Icon(
                      //                                   CupertinoIcons.folder),
                      //                               title: Text(dirPaths[idx - 1]
                      //                                   .toString()),
                      //                               trailing: IconButton(
                      //                                 icon: const Icon(
                      //                                   CupertinoIcons.clear,
                      //                                   size: 15.0,
                      //                                 ),
                      //                                 tooltip: 'Remove',
                      //                                 onPressed: () {
                      //                                   dirPaths
                      //                                       .removeAt(idx - 1);
                      //                                   Hive.box('settings').put(
                      //                                       'blacklistedPaths',
                      //                                       dirPaths);
                      //                                   _listKey.currentState!
                      //                                       .removeItem(
                      //                                           idx,
                      //                                           (context,
                      //                                                   animation) =>
                      //                                               Container());
                      //                                 },
                      //                               ),
                      //                             ),
                      //                           );
                      //                   },
                      //                 ),
                      //               );
                      //             });
                      //       })
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                child: GradientCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                          child: Text(
                            AppLocalizations.of(context)!.down,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title:
                              Text(AppLocalizations.of(context)!.downQuality),
                          subtitle: Text(
                              AppLocalizations.of(context)!.downQualitySub),
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
                                setState(() {
                                  downloadQuality = newValue;
                                  Hive.box('settings')
                                      .put('downloadQuality', newValue);
                                });
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
                          title:
                              Text(AppLocalizations.of(context)!.downLocation),
                          subtitle: Text(downloadPath),
                          trailing: TextButton(
                            style: TextButton.styleFrom(
                              primary: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                            ),
                            onPressed: () async {
                              downloadPath =
                                  await ExtStorageProvider.getExtStorage(
                                          dirName: 'Music') ??
                                      '/storage/emulated/0/Music';
                              Hive.box('settings')
                                  .put('downloadPath', downloadPath);
                              setState(() {});
                            },
                            child: Text(AppLocalizations.of(context)!.reset),
                          ),
                          onTap: () async {
                            final String temp = await Picker().selectFolder(
                                context,
                                AppLocalizations.of(context)!
                                    .selectDownLocation);
                            if (temp.trim() != '') {
                              downloadPath = temp;
                              Hive.box('settings').put('downloadPath', temp);
                              setState(() {});
                            } else {
                              ShowSnackBar().showSnackBar(
                                context,
                                AppLocalizations.of(context)!.noFolderSelected,
                              );
                            }
                          },
                          dense: true,
                        ),
                        BoxSwitchTile(
                          title: Text(
                              AppLocalizations.of(context)!.createAlbumFold),
                          subtitle: Text(
                              AppLocalizations.of(context)!.createAlbumFoldSub),
                          keyName: 'createDownloadFolder',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title:
                              Text(AppLocalizations.of(context)!.createYtFold),
                          subtitle: Text(
                              AppLocalizations.of(context)!.createYtFoldSub),
                          keyName: 'createYoutubeFolder',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title: Text(AppLocalizations.of(context)!.downLyrics),
                          subtitle:
                              Text(AppLocalizations.of(context)!.downLyricsSub),
                          keyName: 'downloadLyrics',
                          defaultValue: false,
                          isThreeLine: true,
                        ),
                      ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                child: GradientCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                          child: Text(
                            AppLocalizations.of(context)!.others,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                            title: Text(
                                '\n${AppLocalizations.of(context)!.minAudioLen}'),
                            subtitle: Text(
                                AppLocalizations.of(context)!.minAudioLenSub),
                            dense: true,
                            onTap: () {
                              TextInputDialog().showTextInputDialog(
                                  context: context,
                                  title: AppLocalizations.of(context)!
                                      .minAudioAlert,
                                  initialText: (Hive.box('settings').get(
                                          'minDuration',
                                          defaultValue: 10) as int)
                                      .toString(),
                                  keyboardType: TextInputType.number,
                                  onSubmitted: (String value) {
                                    if (value.trim() == '') {
                                      value = '0';
                                    }
                                    Hive.box('settings')
                                        .put('minDuration', int.parse(value));
                                    Navigator.pop(context);
                                  });
                            }),
                        BoxSwitchTile(
                          title: Text(AppLocalizations.of(context)!.supportEq),
                          subtitle:
                              Text(AppLocalizations.of(context)!.supportEqSub),
                          keyName: 'supportEq',
                          isThreeLine: true,
                          defaultValue: true,
                        ),
                        BoxSwitchTile(
                            title: Text(AppLocalizations.of(context)!.showLast),
                            subtitle:
                                Text(AppLocalizations.of(context)!.showLastSub),
                            keyName: 'showRecent',
                            defaultValue: true,
                            onChanged: (val, box) {
                              widget.callback!();
                            }),
                        BoxSwitchTile(
                          title:
                              Text(AppLocalizations.of(context)!.showHistory),
                          subtitle: Text(
                              AppLocalizations.of(context)!.showHistorySub),
                          keyName: 'showHistory',
                          defaultValue: true,
                        ),
                        BoxSwitchTile(
                          title:
                              Text(AppLocalizations.of(context)!.stopOnClose),
                          subtitle: Text(
                              AppLocalizations.of(context)!.stopOnCloseSub),
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
                          title:
                              Text(AppLocalizations.of(context)!.checkUpdate),
                          subtitle: Text(
                              AppLocalizations.of(context)!.checkUpdateSub),
                          keyName: 'checkUpdate',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title: Text(AppLocalizations.of(context)!.useProxy),
                          subtitle:
                              Text(AppLocalizations.of(context)!.useProxySub),
                          keyName: 'useProxy',
                          defaultValue: false,
                          isThreeLine: true,
                          onChanged: (bool val, Box box) {
                            useProxy = val;
                            setState(() {});
                          },
                        ),
                        Visibility(
                          visible: useProxy,
                          child: ListTile(
                            title: Text(AppLocalizations.of(context)!.proxySet),
                            subtitle:
                                Text(AppLocalizations.of(context)!.proxySetSub),
                            dense: true,
                            trailing: Text(
                              '${Hive.box('settings').get("proxyIp")}:${Hive.box('settings').get("proxyPort")}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  final _controller = TextEditingController(
                                      text: settingsBox
                                          .get('proxyIp')
                                          .toString());
                                  final _controller2 = TextEditingController(
                                      text: settingsBox
                                          .get('proxyPort')
                                          .toString());
                                  return AlertDialog(
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .ipAdd,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary),
                                            ),
                                          ],
                                        ),
                                        TextField(
                                          autofocus: true,
                                          controller: _controller,
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .port,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary),
                                            ),
                                          ],
                                        ),
                                        TextField(
                                          autofocus: true,
                                          controller: _controller2,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          primary:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .cancel),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          primary: Theme.of(context)
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
                                          settingsBox.put('proxyIp',
                                              _controller.text.trim());
                                          settingsBox.put(
                                              'proxyPort',
                                              int.parse(
                                                  _controller2.text.trim()));
                                          Navigator.pop(context);
                                          setState(() {});
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!.ok,
                                          style: const TextStyle(
                                              color: Colors.white),
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
                            title:
                                Text(AppLocalizations.of(context)!.clearCache),
                            subtitle: Text(
                                AppLocalizations.of(context)!.clearCacheSub),
                            trailing: SizedBox(
                              height: 70.0,
                              width: 70.0,
                              child: Center(
                                child: FutureBuilder(
                                    future:
                                        File(Hive.box('cache').path!).length(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<int> snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        return Text(
                                            '${((snapshot.data ?? 0) / (1024 * 1024)).toStringAsFixed(2)} MB');
                                      }
                                      return const Text('');
                                    }),
                              ),
                            ),
                            dense: true,
                            isThreeLine: true,
                            onTap: () async {
                              Hive.box('cache').clear();
                              setState(() {});
                            }),
                      ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                child: GradientCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                          child: Text(
                            AppLocalizations.of(context)!.backNRest,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.createBack),
                          subtitle:
                              Text(AppLocalizations.of(context)!.createBackSub),
                          dense: true,
                          onTap: () {
                            showModalBottomSheet(
                                isDismissible: true,
                                backgroundColor: Colors.transparent,
                                context: context,
                                builder: (BuildContext context) {
                                  final List playlistNames =
                                      Hive.box('settings').get('playlistNames',
                                              defaultValue: ['Favorite Songs'])
                                          as List;
                                  if (!playlistNames
                                      .contains('Favorite Songs')) {
                                    playlistNames.insert(0, 'Favorite Songs');
                                    settingsBox.put(
                                        'playlistNames', playlistNames);
                                  }

                                  final List<String> persist = [
                                    AppLocalizations.of(context)!.settings,
                                    AppLocalizations.of(context)!.playlists,
                                  ];

                                  final List<String> checked = [
                                    AppLocalizations.of(context)!.settings,
                                    AppLocalizations.of(context)!.downs,
                                    AppLocalizations.of(context)!.playlists,
                                  ];

                                  final List<String> items = [
                                    AppLocalizations.of(context)!.settings,
                                    AppLocalizations.of(context)!.playlists,
                                    AppLocalizations.of(context)!.downs,
                                    AppLocalizations.of(context)!.cache,
                                  ];

                                  final Map<String, List> boxNames = {
                                    AppLocalizations.of(context)!.settings: [
                                      'settings'
                                    ],
                                    AppLocalizations.of(context)!.cache: [
                                      'cache'
                                    ],
                                    AppLocalizations.of(context)!.downs: [
                                      'downloads'
                                    ],
                                    AppLocalizations.of(context)!.playlists:
                                        playlistNames,
                                  };
                                  return StatefulBuilder(builder:
                                      (BuildContext context,
                                          StateSetter setStt) {
                                    return BottomGradientContainer(
                                      borderRadius: BorderRadius.circular(20.0),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ListView.builder(
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                shrinkWrap: true,
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        0, 10, 0, 10),
                                                itemCount: items.length,
                                                itemBuilder: (context, idx) {
                                                  return CheckboxListTile(
                                                    activeColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary,
                                                    checkColor: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .secondary ==
                                                            Colors.white
                                                        ? Colors.black
                                                        : null,
                                                    value: checked
                                                        .contains(items[idx]),
                                                    title: Text(items[idx]),
                                                    onChanged: persist.contains(
                                                            items[idx])
                                                        ? null
                                                        : (bool? value) {
                                                            value!
                                                                ? checked.add(
                                                                    items[idx])
                                                                : checked.remove(
                                                                    items[idx]);
                                                            setStt(() {});
                                                          },
                                                  );
                                                }),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  primary: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text(AppLocalizations.of(
                                                        context)!
                                                    .cancel),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  primary: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                                onPressed: () {
                                                  BackupNRestore().createBackup(
                                                      context,
                                                      checked,
                                                      boxNames);
                                                  Navigator.pop(context);
                                                },
                                                child: Text(
                                                  AppLocalizations.of(context)!
                                                      .ok,
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary ==
                                                              Colors.white
                                                          ? Colors.black
                                                          : null,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  });
                                });
                          },
                        ),
                        ListTile(
                          title: Text(AppLocalizations.of(context)!.restore),
                          subtitle:
                              Text(AppLocalizations.of(context)!.restoreSub),
                          dense: true,
                          onTap: () {
                            BackupNRestore().restore(context);
                          },
                        ),
                        // BoxSwitchTile(
                        //   title: Text(AppLocalizations.of(context)!.autoBack),
                        //   subtitle:
                        //       Text(AppLocalizations.of(context)!.autoBackSub),
                        //   keyName: 'autoBackup',
                        //   defaultValue: false,
                        // ),
                      ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                child: GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                        child: Text(
                          AppLocalizations.of(context)!.about,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.version),
                        subtitle:
                            Text(AppLocalizations.of(context)!.versionSub),
                        onTap: () {
                          SupaBase().getUpdate().then((Map value) {
                            if (compareVersion(
                                value['LatestVersion'].toString(),
                                appVersion!)) {
                              ShowSnackBar().showSnackBar(
                                context,
                                AppLocalizations.of(context)!.updateAvailable,
                                action: SnackBarAction(
                                  textColor:
                                      Theme.of(context).colorScheme.secondary,
                                  label: AppLocalizations.of(context)!.update,
                                  onPressed: () {
                                    launch(value['LatestUrl'].toString());
                                  },
                                ),
                              );
                            } else {
                              ShowSnackBar().showSnackBar(
                                context,
                                AppLocalizations.of(context)!.latest,
                              );
                            }
                          });
                        },
                        trailing: Text(
                          'v$appVersion',
                          style: const TextStyle(fontSize: 12),
                        ),
                        dense: true,
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.shareApp),
                        subtitle:
                            Text(AppLocalizations.of(context)!.shareAppSub),
                        onTap: () {
                          Share.share(
                              '${AppLocalizations.of(context)!.shareAppText}: https://github.com/Sangwan5688/BlackHole');
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.likedWork),
                        subtitle: Text(AppLocalizations.of(context)!.buyCoffee),
                        dense: true,
                        onTap: () {
                          launch('https://www.buymeacoffee.com/ankitsangwan');
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.donateGpay),
                        subtitle:
                            Text(AppLocalizations.of(context)!.donateGpaySub),
                        dense: true,
                        isThreeLine: true,
                        onTap: () {
                          const String upiUrl =
                              'upi://pay?pa=8570094149@okbizaxis&pn=BlackHole&mc=5732&aid=uGICAgIDn98OpSw&tr=BCR2DN6T37O6DB3Q';
                          launch(upiUrl);
                        },
                        onLongPress: () {
                          Clipboard.setData(const ClipboardData(
                              text: 'ankit.sangwan.5688@oksbi'));
                          ShowSnackBar().showSnackBar(
                            context,
                            AppLocalizations.of(context)!.upiCopied,
                          );
                        },
                        trailing: TextButton(
                          style: TextButton.styleFrom(
                            primary:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.grey[700],
                          ),
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return const Dialog(
                                      elevation: 10,
                                      backgroundColor: Colors.transparent,
                                      child: Image(
                                          image:
                                              AssetImage('assets/gpayQR.png')));
                                });
                          },
                          child: Text(
                            AppLocalizations.of(context)!.showQr,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.contactUs),
                        subtitle:
                            Text(AppLocalizations.of(context)!.contactUsSub),
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
                                              icon: const Icon(MdiIcons.gmail),
                                              iconSize: 40,
                                              tooltip:
                                                  AppLocalizations.of(context)!
                                                      .gmail,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://mail.google.com/mail/?extsrc=mailto&url=mailto%3A%3Fto%3Dblackholeyoucantescape%40gmail.com%26subject%3DRegarding%2520Mobile%2520App');
                                              },
                                            ),
                                            Text(AppLocalizations.of(context)!
                                                .gmail),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon:
                                                  const Icon(MdiIcons.telegram),
                                              iconSize: 40,
                                              tooltip:
                                                  AppLocalizations.of(context)!
                                                      .tg,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://t.me/joinchat/fHDC1AWnOhw0ZmI9');
                                              },
                                            ),
                                            Text(AppLocalizations.of(context)!
                                                .tg),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  MdiIcons.instagram),
                                              iconSize: 40,
                                              tooltip:
                                                  AppLocalizations.of(context)!
                                                      .insta,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://instagram.com/sangwan5688');
                                              },
                                            ),
                                            Text(AppLocalizations.of(context)!
                                                .insta),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                        },
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.joinTg),
                        subtitle: Text(AppLocalizations.of(context)!.joinTgSub),
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
                                              icon:
                                                  const Icon(MdiIcons.telegram),
                                              iconSize: 40,
                                              tooltip:
                                                  AppLocalizations.of(context)!
                                                      .tgGp,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://t.me/joinchat/fHDC1AWnOhw0ZmI9');
                                              },
                                            ),
                                            Text(AppLocalizations.of(context)!
                                                .tgGp),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon:
                                                  const Icon(MdiIcons.telegram),
                                              iconSize: 40,
                                              tooltip:
                                                  AppLocalizations.of(context)!
                                                      .tgCh,
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://t.me/blackhole_official');
                                              },
                                            ),
                                            Text(AppLocalizations.of(context)!
                                                .tgCh),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: Text(AppLocalizations.of(context)!.moreInfo),
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
                padding: const EdgeInsets.fromLTRB(5, 30, 5, 20),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.madeBy,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void switchToCustomTheme() {
    const custom = 'Custom';
    if (theme != custom) {
      currentTheme.setInitialTheme(custom);
      setState(() {
        theme = custom;
      });
    }
  }
}

class BoxSwitchTile extends StatelessWidget {
  const BoxSwitchTile({
    Key? key,
    required this.title,
    this.subtitle,
    required this.keyName,
    required this.defaultValue,
    this.isThreeLine,
    this.onChanged,
  }) : super(key: key);

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
                if (onChanged != null) {
                  onChanged!(val, box);
                }
              });
        });
  }
}
