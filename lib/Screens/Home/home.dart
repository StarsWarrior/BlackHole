import 'dart:math';

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info/package_info.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/countrycodes.dart';
import 'package:blackhole/Helpers/supabase.dart';
import 'package:blackhole/Screens/Home/saavn.dart';
import 'package:blackhole/Screens/Library/downloaded.dart';
import 'package:blackhole/Screens/Library/library.dart';
import 'package:blackhole/Screens/Search/search.dart';
import 'package:blackhole/Screens/Settings/setting.dart';
import 'package:blackhole/Screens/Top Charts/top.dart';
import 'package:blackhole/Screens/YouTube/youtube_home.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  bool checked = false;
  String? appVersion;
  String name =
      Hive.box('settings').get('name', defaultValue: 'Guest') as String;

  String capitalize(String msg) {
    return '${msg[0].toUpperCase()}${msg.substring(1)}';
  }

  void callback() {
    setState(() {});
  }

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
    pageController.animateToPage(index,
        duration: const Duration(milliseconds: 400), curve: Curves.ease);
  }

  bool compareVersion(String latestVersion, String currentVersion) {
    bool update = false;
    final List latestList = latestVersion.split('.');
    final List currentList = currentVersion.split('.');

    for (int i = 0; i < latestList.length; i++) {
      try {
        if (int.parse(latestList[i] as String) >
            int.parse(currentList[i] as String)) {
          update = true;
          break;
        }
      } catch (e) {
        break;
      }
    }
    return update;
  }

  void updateUserDetails(String key, dynamic value) {
    final userId = Hive.box('settings').get('userId') as String?;
    SupaBase().updateUserDetails(userId, key, value);
  }

  Widget checkVersion() {
    if (!checked && Theme.of(context).platform == TargetPlatform.android) {
      checked = true;
      final SupaBase db = SupaBase();
      final DateTime now = DateTime.now();
      final List lastLogin = now
          .toUtc()
          .add(const Duration(hours: 5, minutes: 30))
          .toString()
          .split('.')
            ..removeLast()
            ..join('.');
      updateUserDetails('lastLogin', '${lastLogin[0]} IST');
      final String offset =
          now.timeZoneOffset.toString().replaceAll('.000000', '');

      updateUserDetails(
          'timeZone', 'Zone: ${now.timeZoneName}, Offset: $offset');

      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        appVersion = packageInfo.version;
        updateUserDetails('version', packageInfo.version);

        db.getUpdate().then((Map value) {
          if (compareVersion(value['LatestVersion'] as String, appVersion!)) {
            ShowSnackBar().showSnackBar(
              context,
              'Update Available!',
              duration: const Duration(seconds: 15),
              action: SnackBarAction(
                textColor: Theme.of(context).accentColor,
                label: 'Update',
                onPressed: () {
                  Navigator.pop(context);
                  launch(value['LatestUrl'] as String);
                },
              ),
            );
          }
        });
      });
      if (Hive.box('settings').get('proxyIp') == null) {
        Hive.box('settings').put('proxyIp', '103.47.67.134');
      }
      if (Hive.box('settings').get('proxyPort') == null) {
        Hive.box('settings').put('proxyPort', 8080);
      }
      return const SizedBox();
    } else {
      return const SizedBox();
    }
  }

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          drawer: Drawer(
            child: GradientContainer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomScrollView(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        elevation: 0,
                        stretch: true,
                        expandedHeight:
                            MediaQuery.of(context).size.height * 0.2,
                        flexibleSpace: FlexibleSpaceBar(
                          title: RichText(
                            text: TextSpan(
                              text: 'BlackHole',
                              style: const TextStyle(
                                fontSize: 30.0,
                                fontWeight: FontWeight.w500,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: appVersion == null
                                      ? ''
                                      : '\nv$appVersion',
                                  style: const TextStyle(
                                    fontSize: 7.0,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.end,
                          ),
                          titlePadding: const EdgeInsets.only(bottom: 40.0),
                          centerTitle: true,
                          background: ShaderMask(
                            shaderCallback: (rect) {
                              return LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.black.withOpacity(0.1),
                                ],
                              ).createShader(
                                  Rect.fromLTRB(0, 0, rect.width, rect.height));
                            },
                            blendMode: BlendMode.dstIn,
                            child: Image(
                                alignment: Alignment.topCenter,
                                image: AssetImage(
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 'assets/header-dark.jpg'
                                        : 'assets/header.jpg')),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            ListTile(
                              title: Text(
                                'Home',
                                style: TextStyle(
                                  color: Theme.of(context).accentColor,
                                ),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              leading: Icon(
                                Icons.home_rounded,
                                color: Theme.of(context).accentColor,
                              ),
                              selected: true,
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                            ListTile(
                              title: const Text('My Music'),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              leading: Icon(
                                MdiIcons.folderMusic,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const DownloadedSongs(
                                                type: 'all')));
                              },
                            ),
                            ListTile(
                              title: const Text('Settings'),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              leading: Icon(
                                Icons
                                    .settings_rounded, // miscellaneous_services_rounded,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            SettingPage(callback: callback)));
                              },
                            ),
                            ListTile(
                              title: const Text('About'),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              leading: Icon(
                                Icons.info_outline_rounded,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(context, '/about');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(5, 30, 5, 20),
                    child: Center(
                      child: Text(
                        'Made with ♥ by Ankit Sangwan',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    physics: const CustomPhysics(),
                    onPageChanged: (indx) {
                      _selectedIndex.value = indx;
                    },
                    controller: pageController,
                    children: [
                      Stack(
                        children: [
                          checkVersion(),
                          NestedScrollView(
                            physics: const BouncingScrollPhysics(),
                            controller: _scrollController,
                            headerSliverBuilder:
                                (BuildContext context, bool innerBoxScrolled) {
                              final controller = TextEditingController();
                              return <Widget>[
                                SliverAppBar(
                                  expandedHeight: 135,
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  // pinned: true,
                                  toolbarHeight: 65,
                                  // floating: true,
                                  automaticallyImplyLeading: false,
                                  flexibleSpace: LayoutBuilder(
                                    builder: (BuildContext context,
                                        BoxConstraints constraints) {
                                      return FlexibleSpaceBar(
                                        // collapseMode: CollapseMode.parallax,
                                        background: GestureDetector(
                                          onTap: () async {
                                            await TextInputDialog()
                                                .showTextInputDialog(
                                                    context,
                                                    'Name',
                                                    name,
                                                    TextInputType.name,
                                                    (value) {
                                              Hive.box('settings')
                                                  .put('name', value.trim());
                                              name = value.trim();
                                              Navigator.pop(context);
                                              updateUserDetails(
                                                  'name', value.trim());
                                            });
                                            setState(() {});
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              const SizedBox(
                                                height: 60,
                                              ),
                                              Row(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 15.0),
                                                    child: Text(
                                                      'Hi There,',
                                                      style: TextStyle(
                                                          letterSpacing: 2,
                                                          color:
                                                              Theme.of(context)
                                                                  .accentColor,
                                                          fontSize: 30,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 15.0),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    ValueListenableBuilder(
                                                        valueListenable:
                                                            Hive.box('settings')
                                                                .listenable(),
                                                        builder: (BuildContext
                                                                context,
                                                            Box box,
                                                            widget) {
                                                          return Text(
                                                            (box.get('name') ==
                                                                        null ||
                                                                    box.get('name') ==
                                                                        '')
                                                                ? 'Guest'
                                                                : capitalize(box
                                                                    .get('name')
                                                                    .split(
                                                                        ' ')[0]
                                                                    .toString()),
                                                            style: const TextStyle(
                                                                letterSpacing:
                                                                    2,
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                          );
                                                        }),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SliverAppBar(
                                  automaticallyImplyLeading: false,
                                  pinned: true,
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  stretch: true,
                                  toolbarHeight: 65,
                                  title: Align(
                                    alignment: Alignment.centerRight,
                                    child: AnimatedBuilder(
                                        animation: _scrollController,
                                        builder: (context, child) {
                                          return AnimatedContainer(
                                            width: (!_scrollController
                                                        .hasClients ||
                                                    _scrollController
                                                            // ignore: invalid_use_of_protected_member
                                                            .positions
                                                            .length >
                                                        1)
                                                ? MediaQuery.of(context)
                                                    .size
                                                    .width
                                                : max(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width -
                                                        _scrollController.offset
                                                            .roundToDouble(),
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width -
                                                        75),
                                            duration: const Duration(
                                                milliseconds: 150),
                                            padding: const EdgeInsets.all(2.0),
                                            // margin: EdgeInsets.zero,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              color:
                                                  Theme.of(context).cardColor,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 5.0,
                                                  offset: Offset(1.5, 1.5),
                                                  // shadow direction: bottom right
                                                )
                                              ],
                                            ),
                                            child: TextField(
                                              controller: controller,
                                              textAlignVertical:
                                                  TextAlignVertical.center,
                                              decoration: InputDecoration(
                                                focusedBorder:
                                                    const UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      width: 1.5,
                                                      color:
                                                          Colors.transparent),
                                                ),
                                                fillColor: Theme.of(context)
                                                    .accentColor,
                                                prefixIcon: Icon(
                                                  CupertinoIcons.search,
                                                  color: Theme.of(context)
                                                      .accentColor,
                                                ),
                                                border: InputBorder.none,
                                                hintText:
                                                    'Songs, albums or artists',
                                              ),
                                              onSubmitted: (query) {
                                                if (query.trim() != '') {
                                                  List search =
                                                      Hive.box('settings').get(
                                                              'search',
                                                              defaultValue: [])
                                                          as List;
                                                  if (search.contains(query)) {
                                                    search.remove(query);
                                                  }
                                                  search.insert(0, query);
                                                  if (search.length > 3) {
                                                    search =
                                                        search.sublist(0, 3);
                                                  }
                                                  Hive.box('settings')
                                                      .put('search', search);
                                                  Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              SearchPage(
                                                                  query:
                                                                      query)));
                                                }
                                                controller.text = '';
                                              },
                                            ),
                                          );
                                        }),
                                  ),
                                ),
                              ];
                            },
                            body: SaavnHomePage(),
                          ),
                          Builder(
                            builder: (context) => Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, left: 4.0),
                              child: Transform.rotate(
                                angle: 22 / 7 * 2,
                                child: IconButton(
                                  icon: const Icon(
                                      Icons.horizontal_split_rounded),
                                  color: Theme.of(context).iconTheme.color,
                                  onPressed: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                  tooltip: MaterialLocalizations.of(context)
                                      .openAppDrawerTooltip,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      TopCharts(
                        region: CountryCodes()
                            .countryCodes[Hive.box('settings')
                                .get('region', defaultValue: 'India')]
                            .toString(),
                      ),
                      const YouTube(),
                      LibraryPage(),
                    ],
                  ),
                ),
                MiniPlayer()
              ],
            ),
          ),
          bottomNavigationBar: ValueListenableBuilder(
              valueListenable: playerExpandProgress,
              builder: (BuildContext context, double value, Widget? child) {
                return SafeArea(
                  child: ValueListenableBuilder(
                      valueListenable: _selectedIndex,
                      builder: (BuildContext context, int indexValue,
                          Widget? child) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          height: 60 *
                              (MediaQuery.of(context).size.height - value) /
                              (MediaQuery.of(context).size.height - 76),
                          child: SalomonBottomBar(
                            currentIndex: indexValue,
                            onTap: (index) {
                              _onItemTapped(index);
                            },
                            items: [
                              /// Home
                              SalomonBottomBarItem(
                                icon: const Icon(Icons.home_rounded),
                                title: const Text('Home'),
                                selectedColor: Theme.of(context).accentColor,
                              ),

                              SalomonBottomBarItem(
                                icon: const Icon(Icons.trending_up_rounded),
                                title: const Text('Spotify Charts'),
                                selectedColor: Theme.of(context).accentColor,
                              ),
                              SalomonBottomBarItem(
                                icon: const Icon(MdiIcons.youtube),
                                title: const Text('YouTube'),
                                selectedColor: Theme.of(context).accentColor,
                              ),
                              SalomonBottomBarItem(
                                icon:
                                    const Icon(Icons.my_library_music_rounded),
                                title: const Text('Library'),
                                selectedColor: Theme.of(context).accentColor,
                              ),
                            ],
                          ),
                        );
                      }),
                );
              })),
    );
  }
}
