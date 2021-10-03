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
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              child: const Center(
                child: Text(
                  'Settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                child: GradientCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                        child: Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      BoxSwitchTile(
                          title: const Text('Dark Mode'),
                          keyName: 'darkMode',
                          defaultValue: true,
                          onChanged: (bool val) {
                            currentTheme.switchTheme(isDark: val);
                            themeColor = val ? 'Teal' : 'Light Blue';
                            colorHue = 400;
                          }),
                      ListTile(
                        title: const Text('Accent Color & Hue'),
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
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 10, 0, 10),
                                    itemCount: colors.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 15.0),
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
                                                        colorHue);
                                                    setState(() {});
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
                                                          BorderRadius.circular(
                                                              100.0),
                                                      color: MyTheme().getColor(
                                                          colors[index], hue),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Colors.grey[900]!,
                                                          blurRadius: 5.0,
                                                          offset: const Offset(
                                                              0.0, 3.0),
                                                        )
                                                      ],
                                                    ),
                                                    child: (themeColor ==
                                                                colors[index] &&
                                                            colorHue == hue)
                                                        ? const Icon(
                                                            Icons.done_rounded)
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
                              title: const Text('Background Gradient'),
                              subtitle: const Text(
                                  'Gradient used as background everywhere'),
                              trailing: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  height: 25,
                                  width: 25,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100.0),
                                    color:
                                        Theme.of(context).colorScheme.secondary,
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
                                      borderRadius: BorderRadius.circular(20.0),
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
                                                          BorderRadius.circular(
                                                              100.0),
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors:
                                                            gradients[index],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Colors.grey[900]!,
                                                          blurRadius: 5.0,
                                                          offset: const Offset(
                                                              0.0, 3.0),
                                                        )
                                                      ],
                                                    ),
                                                    child: (currentTheme
                                                                .getBackGradient() ==
                                                            gradients[index])
                                                        ? const Icon(
                                                            Icons.done_rounded)
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
                              title: const Text('Card Gradient'),
                              subtitle: const Text('Gradient used in Cards'),
                              trailing: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  height: 25,
                                  width: 25,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100.0),
                                    color:
                                        Theme.of(context).colorScheme.secondary,
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
                                      borderRadius: BorderRadius.circular(20.0),
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
                                                          BorderRadius.circular(
                                                              100.0),
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors:
                                                            gradients[index],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Colors.grey[900]!,
                                                          blurRadius: 5.0,
                                                          offset: const Offset(
                                                              0.0, 3.0),
                                                        )
                                                      ],
                                                    ),
                                                    child: (currentTheme
                                                                .getCardGradient() ==
                                                            gradients[index])
                                                        ? const Icon(
                                                            Icons.done_rounded)
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
                              title: const Text('Bottom Sheets Gradient'),
                              subtitle:
                                  const Text('Gradient used in Bottom Sheets'),
                              trailing: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Container(
                                  height: 25,
                                  width: 25,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100.0),
                                    color:
                                        Theme.of(context).colorScheme.secondary,
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
                                      borderRadius: BorderRadius.circular(20.0),
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
                                                          BorderRadius.circular(
                                                              100.0),
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                        colors:
                                                            gradients[index],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Colors.grey[900]!,
                                                          blurRadius: 5.0,
                                                          offset: const Offset(
                                                              0.0, 3.0),
                                                        )
                                                      ],
                                                    ),
                                                    child: (currentTheme
                                                                .getBottomGradient() ==
                                                            gradients[index])
                                                        ? const Icon(
                                                            Icons.done_rounded)
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
                              title: const Text('Canvas Color'),
                              subtitle:
                                  const Text('Color of Background Canvas'),
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
                                    setState(() {
                                      currentTheme.switchCanvasColor(newValue);
                                      canvasColor = newValue;
                                    });
                                  }
                                },
                                items: <String>[
                                  'Grey',
                                  'Black'
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                              dense: true,
                            ),
                            ListTile(
                              title: const Text('Card Color'),
                              subtitle: const Text(
                                  'Color of Search Bar, Alert Dialogs, Cards'),
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
                                ].map<DropdownMenuItem<String>>((String value) {
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
                      const BoxSwitchTile(
                        title: Text('Use Dominant Color for Play Screen'),
                        subtitle: Text(
                            'Dominant Color from Image will be used for Play Screen Background. If turned off, default background Gradient will be used'),
                        keyName: 'useImageColor',
                        defaultValue: true,
                        isThreeLine: true,
                      ),
                      ListTile(
                          title: const Text('Use Amoled Dark Mode Settings'),
                          dense: true,
                          onTap: () {
                            currentTheme.switchTheme(isDark: true);
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
                          title: const Text('Change to Default'),
                          dense: true,
                          onTap: () {
                            Hive.box('settings').put('darkMode', true);

                            settingsBox.put('backGrad', 1);
                            currentTheme.backGrad = 1;
                            settingsBox.put('cardGrad', 3);
                            currentTheme.cardGrad = 3;
                            settingsBox.put('bottomGrad', 2);
                            currentTheme.bottomGrad = 2;

                            currentTheme.switchCanvasColor('Grey');
                            canvasColor = 'Grey';

                            currentTheme.switchCardColor('Grey850');
                            cardColor = 'Grey850';

                            themeColor = 'Teal';
                            colorHue = 400;
                            currentTheme.switchTheme(isDark: true);
                          }),
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
                          'Music & Playback',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      ListTile(
                        title: const Text('Music Language'),
                        subtitle: const Text('To display songs on Home Screen'),
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
                                              child: const Text('Cancel'),
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
                                                    'No Music language selected. Select a language to see songs on Home Screen',
                                                  );
                                                }
                                              },
                                              child: const Text(
                                                'Ok',
                                                style: TextStyle(
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
                          title: const Text('Spotify Local Charts Location'),
                          subtitle: const Text(
                              'Country for Top Spotify Local Charts'),
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
                        title: const Text('Streaming Quality'),
                        subtitle: const Text('Higher quality uses more data'),
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
                      const BoxSwitchTile(
                        title: Text('Load Last Session on App Start'),
                        subtitle: Text(
                            'Automatically load last session when app starts'),
                        keyName: 'loadStart',
                        defaultValue: true,
                      ),
                      const BoxSwitchTile(
                        title: Text('Enforce Repeating'),
                        subtitle: Text(
                            'Keep the same repeat option for every session'),
                        keyName: 'enforceRepeat',
                        defaultValue: false,
                      ),
                      const BoxSwitchTile(
                        title: Text('Autoplay'),
                        subtitle: Text(
                            'Automatically added related songs to the queue'),
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
                            'Download',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title: const Text('Download Quality'),
                          subtitle:
                              const Text('Higher quality uses more disk space'),
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
                          title: const Text('Download Location'),
                          subtitle: Text(downloadPath),
                          trailing: TextButton(
                            style: TextButton.styleFrom(
                              primary: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.grey[700],
                              //       backgroundColor: Theme.of(context).accentColor,
                            ),
                            onPressed: () async {
                              downloadPath = await ExtStorage
                                      .getExternalStoragePublicDirectory(
                                          ExtStorage.DIRECTORY_MUSIC) ??
                                  '/storage/emulated/0/Music';
                              Hive.box('settings')
                                  .put('downloadPath', downloadPath);
                              setState(() {});
                            },
                            child: const Text('Reset'),
                          ),
                          onTap: () async {
                            final String temp = await Picker().selectFolder(
                                context, 'Select Download Location');
                            if (temp.trim() != '') {
                              downloadPath = temp;
                              Hive.box('settings').put('downloadPath', temp);
                              setState(() {});
                            } else {
                              ShowSnackBar().showSnackBar(
                                context,
                                'No folder selected',
                              );
                            }
                          },
                          dense: true,
                        ),
                        const BoxSwitchTile(
                          title: Text(
                              'Create folder for Album & Playlist Download'),
                          subtitle: Text(
                              'Creates common folder for Songs when Album or Playlist is downloaded'),
                          keyName: 'createDownloadFolder',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        const BoxSwitchTile(
                          title: Text(
                              'Create different folder for YouTube Downloads'),
                          subtitle: Text(
                              'Creates a different folder for Songs downloaded from YouTube'),
                          keyName: 'createYoutubeFolder',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        const BoxSwitchTile(
                          title: Text('Download Lyrics'),
                          subtitle: Text(
                              'Downloading lyrics along with song, if available'),
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
                            'Others',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                            title: const Text(
                                '\nMin Audio Length to search music'),
                            subtitle: const Text(
                                'Audios with length smaller than this will not be shown in "My Music" Section'),
                            dense: true,
                            onTap: () {
                              TextInputDialog().showTextInputDialog(
                                  context: context,
                                  title: 'Min Audio Length (in sec)',
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
                        const BoxSwitchTile(
                          title: Text('Support Equalizer'),
                          subtitle: Text(
                              'Turn this off if you are unable to play songs (in both online and offline mode)'),
                          keyName: 'supportEq',
                          isThreeLine: true,
                          defaultValue: true,
                        ),
                        BoxSwitchTile(
                            title: const Text('Show Last Session'),
                            subtitle:
                                const Text('Show Last session on Home Screen'),
                            keyName: 'showRecent',
                            defaultValue: true,
                            onChanged: (val) {
                              widget.callback!();
                            }),
                        const BoxSwitchTile(
                          title: Text('Show Search History'),
                          subtitle:
                              Text('Show Search History below Search Bar'),
                          keyName: 'showHistory',
                          defaultValue: true,
                        ),
                        const BoxSwitchTile(
                          title: Text('Stop music on App Close'),
                          subtitle: Text(
                              "If turned off, music won't stop even after app is 'closed', until you press stop button. This option is for app 'close' not when app is in 'background'. Music will always play in background you don't need to change any setting for that.\n"),
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
                        const BoxSwitchTile(
                          title: Text('Auto check for Updates'),
                          subtitle: Text(
                              "If you downloaded BlackHole from any app repository like 'F-Droid', 'IzzyOnDroid', etc which provide update options, keep this OFF. Whereas, If you downloaded it from 'GitHub' or any other source which doesn't provide auto updates then turn this ON, so as to recieve update alerts\n"),
                          keyName: 'checkUpdate',
                          isThreeLine: true,
                          defaultValue: false,
                        ),
                        BoxSwitchTile(
                          title: const Text('Use Proxy'),
                          subtitle: const Text(
                              'Turn this on if you are not from India and having issues with search, like getting only Indian Songs or not getting any results, etc. You can even use VPN with Indian Server\n'),
                          keyName: 'useProxy',
                          defaultValue: false,
                          isThreeLine: true,
                          onChanged: (bool val) {
                            useProxy = val;
                            setState(() {});
                          },
                        ),
                        ListTile(
                            title: const Text('Clear Cached Details'),
                            subtitle: const Text(
                                'Deletes Cached details including Homepage, Spotify Top Charts, YouTube and Last Session Data. Usually app automatically clears them when data become large\n'),
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
                        Visibility(
                          visible: useProxy,
                          child: ListTile(
                            title: const Text('Proxy Settings'),
                            subtitle: const Text('Change Proxy IP and Port'),
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
                                              'IP Address',
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
                                              'Port',
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
                                          // backgroundColor: Theme.of(context).accentColor,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Cancel'),
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
                                        child: const Text(
                                          'Ok',
                                          style: TextStyle(color: Colors.white),
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
                            'Backup & Restore',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ListTile(
                          title: const Text('Create Backup'),
                          subtitle: const Text('Create backup of your data'),
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
                                    'Settings',
                                    'Playlists',
                                  ];

                                  final List<String> checked = [
                                    'Settings',
                                    'Downloads',
                                    'Playlists'
                                  ];

                                  final List<String> items = [
                                    'Settings',
                                    'Playlists',
                                    'Downloads',
                                    'Cache',
                                  ];

                                  final Map<String, List> boxNames = {
                                    'Settings': ['settings'],
                                    'Cache': ['cache'],
                                    'Downloads': ['downloads'],
                                    'Playlists': playlistNames,
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
                                                child: const Text('Cancel'),
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
                                                  'Ok',
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
                          title: const Text('Restore'),
                          subtitle: const Text(
                              'Restore your data from Backup.\nYou might need to restart app\n'),
                          dense: true,
                          onTap: () {
                            BackupNRestore().restore(context);
                          },
                        ),
                        // const BoxSwitchTile(
                        //   title: Text('Auto Backup'),
                        //   subtitle:
                        //       Text('Automatically backup data'),
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
                          'About',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary),
                        ),
                      ),
                      ListTile(
                        title: const Text('Version'),
                        subtitle: const Text('Tap to check for updates'),
                        onTap: () {
                          SupaBase().getUpdate().then((Map value) {
                            if (compareVersion(
                                value['LatestVersion'].toString(),
                                appVersion!)) {
                              ShowSnackBar().showSnackBar(
                                context,
                                'Update Available!',
                                action: SnackBarAction(
                                  textColor:
                                      Theme.of(context).colorScheme.secondary,
                                  label: 'Update',
                                  onPressed: () {
                                    launch(value['LatestUrl'].toString());
                                  },
                                ),
                              );
                            } else {
                              ShowSnackBar().showSnackBar(
                                context,
                                'Congrats! You are using the latest version :)',
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
                        title: const Text('Share App'),
                        subtitle: const Text('Let you friends know about us'),
                        onTap: () {
                          Share.share(
                              'Hey! Check out this cool music player app: https://github.com/Sangwan5688/BlackHole');
                        },
                        dense: true,
                      ),
                      ListTile(
                        title: const Text('Liked my work?'),
                        subtitle: const Text('Buy me a coffee'),
                        dense: true,
                        onTap: () {
                          launch('https://www.buymeacoffee.com/ankitsangwan');
                        },
                      ),
                      ListTile(
                        title: const Text('Donate with GPay'),
                        subtitle: const Text(
                            'Even ₹1 makes me smile :)\nTap to donate or Long press to copy UPI ID'),
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
                            'UPI ID Copied!',
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
                          child: const Text(
                            'Show QR Code',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      ListTile(
                        title: const Text('Contact Us'),
                        subtitle: const Text('Feedbacks Appreciated!'),
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
                                              tooltip: 'Gmail',
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://mail.google.com/mail/?extsrc=mailto&url=mailto%3A%3Fto%3Dblackholeyoucantescape%40gmail.com%26subject%3DRegarding%2520Mobile%2520App');
                                              },
                                            ),
                                            const Text('Gmail'),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon:
                                                  const Icon(MdiIcons.telegram),
                                              iconSize: 40,
                                              tooltip: 'Telegram',
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://t.me/joinchat/fHDC1AWnOhw0ZmI9');
                                              },
                                            ),
                                            const Text('Telegram'),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                  MdiIcons.instagram),
                                              iconSize: 40,
                                              tooltip: 'Instagram',
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://instagram.com/sangwan5688');
                                              },
                                            ),
                                            const Text('Instagram'),
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
                        title: const Text('Join us on Telegram'),
                        subtitle: const Text(
                            'Want to Test beta versions? Join us now!'),
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
                                              tooltip: 'Telegram Group',
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://t.me/joinchat/fHDC1AWnOhw0ZmI9');
                                              },
                                            ),
                                            const Text('Group'),
                                          ],
                                        ),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon:
                                                  const Icon(MdiIcons.telegram),
                                              iconSize: 40,
                                              tooltip: 'Telegram Channel',
                                              onPressed: () {
                                                Navigator.pop(context);
                                                launch(
                                                    'https://t.me/blackhole_official');
                                              },
                                            ),
                                            const Text('Channel'),
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
                        title: const Text('More info'),
                        dense: true,
                        onTap: () {
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(5, 30, 5, 20),
                child: Center(
                  child: Text(
                    'Made with ♥ by Ankit Sangwan',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
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
  final Function(bool)? onChanged;

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
              value: box.get(keyName, defaultValue: defaultValue) as bool,
              onChanged: (val) {
                box.put(keyName, val);
                if (onChanged != null) {
                  onChanged!(val);
                }
              });
        });
  }
}
