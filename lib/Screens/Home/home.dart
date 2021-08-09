import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/textinput_dialog.dart';
import 'package:blackhole/Helpers/countrycodes.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Helpers/supabase.dart';
import 'package:blackhole/Screens/Home/saavn.dart';
import 'package:blackhole/Screens/Library/downloaded.dart';
import 'package:blackhole/Screens/Library/library.dart';
import 'package:blackhole/Screens/Search/search.dart';
import 'package:blackhole/Screens/Settings/setting.dart';
import 'package:blackhole/Screens/YouTube/youTube.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:blackhole/Screens/Top Charts/top.dart';
import 'dart:math';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info/package_info.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);
  Box settingsBox;
  bool checked = false;
  bool update = false;
  String appVersion;
  String name = Hive.box("settings").get('name', defaultValue: 'Guest');

  String capitalize(String msg) {
    return "${msg[0].toUpperCase()}${msg.substring(1)}";
  }

  void callback() {
    setState(() {});
  }

  void _onItemTapped(int index) {
    _selectedIndex.value = index;
    pageController.animateToPage(index,
        duration: Duration(milliseconds: 400), curve: Curves.ease);
  }

  bool compareVersion(String latestVersion, String currentVersion) {
    bool update = false;
    List latestList = latestVersion.split('.');
    List currentList = currentVersion.split('.');

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

  updateUserDetails(String key, dynamic value) {
    final userId = Hive.box('settings').get('userId');
    SupaBase().updateUserDetails(userId, key, value);
  }

  Widget checkVersion() {
    if (!checked && Theme.of(context).platform == TargetPlatform.android) {
      print('Checking for Update');
      checked = true;
      SupaBase db = SupaBase();
      DateTime now = DateTime.now();
      List lastLogin =
          now.toUtc().add(Duration(hours: 5, minutes: 30)).toString().split('.')
            ..removeLast()
            ..join('.');
      updateUserDetails('lastLogin', '${lastLogin[0]} IST');
      String offset = now.timeZoneOffset.toString().replaceAll(".000000", "");

      updateUserDetails(
          'timeZone', 'Zone: ${now.timeZoneName}, Offset: $offset');

      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        appVersion = packageInfo.version;
        updateUserDetails('version', packageInfo.version);

        db.getUpdate().then((Map value) {
          if (compareVersion(value['LatestVersion'], appVersion)) {
            print('UPDATE IS AVAILABLE');
            return ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: Duration(seconds: 15),
                margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 5.0),
                elevation: 6,
                backgroundColor: Colors.grey[900],
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'Update Available!',
                  style: TextStyle(color: Colors.white),
                ),
                action: SnackBarAction(
                  textColor: Theme.of(context).accentColor,
                  label: 'Update',
                  onPressed: () {
                    Navigator.pop(context);
                    launch(value['LatestUrl']);
                  },
                ),
              ),
            );
          }
        });
      });
      if (Hive.box('settings').get('proxyIp') == null)
        Hive.box('settings').put('proxyIp', "103.47.67.134");
      if (Hive.box('settings').get('proxyPort') == null)
        Hive.box('settings').put('proxyPort', 8080);
      return SizedBox();
    } else {
      // print('platform not android or already checked');
      return SizedBox();
    }
  }

  ScrollController _scrollController;
  ValueNotifier<double> _size = ValueNotifier<double>(0.0);

  void _scrollListener() {
    _size.value = _scrollController.offset.roundToDouble();
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  PageController pageController = PageController(initialPage: 0);

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
                    physics: BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        backgroundColor: Colors.transparent,
                        automaticallyImplyLeading: false,
                        elevation: 0,
                        stretch: true,
                        pinned: false,
                        expandedHeight:
                            MediaQuery.of(context).size.height * 0.2,
                        flexibleSpace: FlexibleSpaceBar(
                          title: RichText(
                            text: TextSpan(
                              text: "BlackHole",
                              style: TextStyle(
                                fontSize: 30.0,
                                fontWeight: FontWeight.w500,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: appVersion==null?"":"\nv$appVersion",
                                  style: TextStyle(
                                    fontSize: 7.0,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.end,
                          ),
                          titlePadding: EdgeInsets.only(bottom: 40.0),
                          centerTitle: true,
                          stretchModes: [StretchMode.zoomBackground],
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
                                  EdgeInsets.symmetric(horizontal: 20.0),
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
                              title: Text('My Music'),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 20.0),
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
                                            DownloadedSongs(type: 'all')));
                              },
                            ),
                            ListTile(
                              title: Text('Settings'),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 20.0),
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
                              title: Text('About'),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 20.0),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 30, 5, 20),
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
                    physics: CustomPhysics(),
                    onPageChanged: (indx) {
                      _selectedIndex.value = indx;
                      if (indx == 0) {
                        _size = ValueNotifier<double>(0.0);
                      }
                    },
                    controller: pageController,
                    children: [
                      Stack(
                        children: [
                          checkVersion(),
                          NotificationListener<OverscrollIndicatorNotification>(
                            onNotification: (overScroll) {
                              overScroll.disallowGlow();
                              return;
                            },
                            child: NestedScrollView(
                              physics: BouncingScrollPhysics(),
                              controller: _scrollController,
                              headerSliverBuilder: (BuildContext context,
                                  bool innerBoxScrolled) {
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
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                SizedBox(
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
                                                            color: Theme.of(
                                                                    context)
                                                                .accentColor,
                                                            fontSize: 30,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 15.0),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      ValueListenableBuilder(
                                                          valueListenable:
                                                              Hive.box(
                                                                      'settings')
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
                                                                      .get(
                                                                          'name')
                                                                      .split(
                                                                          ' ')[0]),
                                                              style: TextStyle(
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
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  SliverAppBar(
                                    automaticallyImplyLeading: false,
                                    pinned: true,
                                    floating: false,
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    stretch: true,
                                    toolbarHeight: 65,
                                    title: Align(
                                      alignment: Alignment.centerRight,
                                      child: ValueListenableBuilder(
                                          valueListenable: _size,
                                          builder:
                                              (context, double value, child) {
                                            return AnimatedContainer(
                                              width: max(
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      value,
                                                  MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      75),
                                              duration:
                                                  Duration(milliseconds: 300),
                                              padding: EdgeInsets.all(2.0),
                                              // margin: EdgeInsets.zero,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                color:
                                                    Theme.of(context).cardColor,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 5.0,
                                                    spreadRadius: 0.0,
                                                    offset: Offset(0.0, 3.0),
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
                                                      UnderlineInputBorder(
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
                                                      "Songs, albums or artists",
                                                ),
                                                autofocus: false,
                                                onSubmitted: (query) {
                                                  if (query.trim() != '') {
                                                    List search = Hive.box(
                                                            'settings')
                                                        .get('search',
                                                            defaultValue: []);
                                                    if (search.contains(query))
                                                      search.remove(query);
                                                    search.insert(0, query);
                                                    if (search.length > 3)
                                                      search =
                                                          search.sublist(0, 3);
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
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? null
                                      : Colors.grey[700],
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
                        region: CountryCodes().countryCodes[
                            Hive.box('settings').get('region') ?? 'India'],
                      ),
                      YouTube(),
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
              builder: (BuildContext context, double value, Widget child) {
                return SafeArea(
                  child: ValueListenableBuilder(
                      valueListenable: _selectedIndex,
                      builder: (context, indexValue, child) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 100),
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
                                icon: Icon(Icons.home_rounded),
                                title: Text("Home"),
                                selectedColor: Theme.of(context).accentColor,
                              ),

                              SalomonBottomBarItem(
                                icon: Icon(Icons.trending_up_rounded),
                                title: Text("Spotify Charts"),
                                selectedColor: Theme.of(context).accentColor,
                              ),
                              SalomonBottomBarItem(
                                icon: Icon(MdiIcons.youtube),
                                title: Text("YouTube"),
                                selectedColor: Theme.of(context).accentColor,
                              ),
                              SalomonBottomBarItem(
                                icon: Icon(Icons.my_library_music_rounded),
                                title: Text("Library"),
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
