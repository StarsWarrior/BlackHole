import 'package:blackhole/Helpers/countrycodes.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Screens/Library/downloaded.dart';
import 'package:blackhole/Screens/Library/library.dart';
import 'package:blackhole/Screens/Search/search.dart';
import 'package:blackhole/Screens/Settings/setting.dart';
import 'package:blackhole/Screens/YouTube/youTube.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:blackhole/Screens/Top Charts/top.dart';
import 'dart:math';
import 'trending.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info/package_info.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Box settingsBox;
<<<<<<< HEAD
  double appVersion = 1.4;
=======
  double appVersion;
>>>>>>> b843d55 (final wrap-ups for v1.6)
  bool checked = false;
  bool update = false;
  bool status = false;

  String capitalize(String msg) {
    return "${msg[0].toUpperCase()}${msg.substring(1)}";
  }

  void callback() {
    setState(() {});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      pageController.animateToPage(index,
          duration: Duration(milliseconds: 400), curve: Curves.ease);
    });
  }

  updateUserDetails(String key, dynamic value) {
    final userID = Hive.box('settings').get('userID');
    final dbRef = FirebaseDatabase.instance.reference().child("Users");
    dbRef.child(userID).update({"$key": "$value"});
  }

  Widget checkVersion() {
    if (!checked && Theme.of(context).platform == TargetPlatform.android) {
      print('checking for update..');
      checked = true;
      DateTime now = DateTime.now();
      updateUserDetails('lastLogin',
          '${now.toUtc().add(Duration(hours: 5, minutes: 30)).toString().split('.').first} IST');
      updateUserDetails('timeZone',
          'Zone: ${now.timeZoneName}, Offset: ${now.timeZoneOffset.toString().split('.').first}');
      final tpStatus = FirebaseDatabase.instance.reference().child("TopStatus");
      tpStatus.once().then((DataSnapshot snapshot) {
        status = snapshot.value;
        status ??= true;
      });
      final dbRef =
          FirebaseDatabase.instance.reference().child("LatestVersion");

      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        List temp = packageInfo.version.split('.');
        temp.removeLast();
        appVersion = double.parse(temp.join('.'));
        updateUserDetails('version', appVersion);
      });
      DeviceInfoPlugin info = DeviceInfoPlugin();
      info.androidInfo.then((AndroidDeviceInfo androidInfo) {
        Map deviceInfo = {
          'Brand': androidInfo.brand,
          'Manufacturer': androidInfo.manufacturer,
          'Device': androidInfo.device,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'Fingerprint': androidInfo.fingerprint,
          'Model': androidInfo.model,
          'Build': androidInfo.display,
          'Product': androidInfo.product,
          'androidVersion': androidInfo.version.release,
          'supportedAbis': androidInfo.supportedAbis,
        };
        Hive.box('settings').put('deviceInfo', deviceInfo);
        updateUserDetails('deviceInfo', deviceInfo);
      });

      dbRef.once().then((DataSnapshot snapshot) {
        if (double.parse(snapshot.value) > appVersion) {
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
                  final dLink =
                      FirebaseDatabase.instance.reference().child("LatestLink");
                  dLink.once().then((DataSnapshot linkSnapshot) {
                    launch(linkSnapshot.value);
                  });
                },
              ),
            ),
          );
        }
      });
      return SizedBox();
    } else {
      // print('platform not android or already checked');
      return SizedBox();
    }
  }

  ScrollController _scrollController;
  double _size = 0.0;

  void _scrollListener() {
    setState(() {
      _size = _scrollController.offset;
    });
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  PageController pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
          backgroundColor: Colors.transparent,
          drawer: Drawer(
            child: GradientContainer(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: <Widget>[
                        ValueListenableBuilder(
                            valueListenable: Hive.box('settings').listenable(),
                            builder: (BuildContext context, Box box, widget) {
                              return UserAccountsDrawerHeader(
                                otherAccountsPictures: [
                                  IconButton(
                                      icon: Icon(Icons.edit_rounded),
                                      iconSize: 20,
                                      color: Colors.white,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            final _controller =
                                                TextEditingController(
                                                    text: box.get('name'));
                                            final _controller2 =
                                                TextEditingController(
                                                    text: box.get('email'));
                                            return AlertDialog(
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Name',
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .accentColor),
                                                      ),
                                                    ],
                                                  ),
                                                  // SizedBox(
                                                  //   height: 5,
                                                  // ),
                                                  TextField(
                                                      autofocus: true,
                                                      controller: _controller,
                                                      onSubmitted: (value) {
                                                        box.put('name',
                                                            value.trim());
                                                        box.put(
                                                            'email',
                                                            _controller2.text
                                                                .trim());
                                                        Navigator.pop(context);
                                                        updateUserDetails(
                                                            'name',
                                                            value.trim());
                                                        updateUserDetails(
                                                            'email',
                                                            _controller2.text
                                                                .trim());
                                                      }),
                                                  SizedBox(
                                                    height: 30,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Email',
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .accentColor),
                                                      ),
                                                    ],
                                                  ),
                                                  TextField(
                                                      autofocus: true,
                                                      controller: _controller2,
                                                      onSubmitted: (value) {
                                                        box.put(
                                                            'name',
                                                            _controller.text
                                                                .trim());
                                                        box.put('email',
                                                            value.trim());
                                                        Navigator.pop(context);
                                                        updateUserDetails(
                                                            'name',
                                                            _controller.text
                                                                .trim());
                                                        updateUserDetails(
                                                            'email',
                                                            value.trim());
                                                      }),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    primary: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.grey[700],
                                                    // backgroundColor: Theme.of(context).accentColor,
                                                  ),
                                                  child: Text("Cancel"),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    primary: Colors.white,
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .accentColor,
                                                  ),
                                                  child: Text(
                                                    "Ok",
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  onPressed: () {
                                                    box.put(
                                                        'name',
                                                        _controller.text
                                                            .trim());
                                                    box.put(
                                                        'email',
                                                        _controller2.text
                                                            .trim());
                                                    Navigator.pop(context);
                                                    updateUserDetails(
                                                        'name',
                                                        _controller.text
                                                            .trim());
                                                    updateUserDetails(
                                                        'email',
                                                        _controller2.text
                                                            .trim());
                                                  },
                                                ),
                                                SizedBox(
                                                  width: 5,
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      })
                                ],
                                accountName: Text(
                                  capitalize((box.get('name') == null ||
                                          box.get('name') == '')
                                      ? 'Guest User'
                                      : box.get('name')),
                                ),
                                accountEmail: Text(
                                  (box.get('email') == null ||
                                          box.get('email') == '')
                                      ? 'xxxxxxxxxx@gmail.com'
                                      : box.get('email'),
                                ),
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        fit: BoxFit.fill,
                                        image: AssetImage(
                                            Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? 'assets/header.jpg'
                                                : 'assets/header-dark.jpg'))),
                                currentAccountPicture: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                        colors: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? [
                                                Colors.white60,
                                                Colors.orangeAccent,
                                                Colors.deepOrangeAccent,
                                                Colors.redAccent,
                                                Colors.redAccent[700],
                                              ]
                                            : [
                                                Colors.grey[700],
                                                // Colors.grey[800],
                                                Colors.grey[800],
                                                Colors.grey[900],
                                                Colors.black,
                                              ],
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    child: Text(
                                        (box.get('name') == null ||
                                                box.get('name') == '')
                                            ? 'G'
                                            : capitalize(box.get('name'))[0],
                                        style: TextStyle(
                                          fontSize: 32,
                                          color: Colors
                                              .white, // (context).accentColor,
                                        )),
                                  ),
                                ),
                              );
                            }),
                        ListTile(
                          title: Text(
                            'Home',
                            style: TextStyle(
                              color: Theme.of(context).accentColor,
                            ),
                          ),
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
                          leading: Icon(
                            Icons.info_outline_rounded,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/about');
                          },
                        ),
                      ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 30, 5, 20),
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
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    onPageChanged: (indx) {
                      setState(() {
                        _selectedIndex = indx;
                        if (indx == 0) {
                          try {
                            _size = _scrollController.offset;
                          } catch (e) {}
                        }
                      });
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
                                          background: Column(
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
                                      child: AnimatedContainer(
                                        width: max(
                                            MediaQuery.of(context).size.width -
                                                _size,
                                            MediaQuery.of(context).size.width -
                                                75),

                                        duration: Duration(milliseconds: 300),
                                        padding:
                                            EdgeInsets.only(top: 3, bottom: 1),
                                        // margin: EdgeInsets.zero,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          color: Theme.of(context).cardColor,
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
                                          decoration: InputDecoration(
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  width: 1.5,
                                                  color: Colors.transparent),
                                            ),
                                            fillColor:
                                                Theme.of(context).accentColor,
                                            prefixIcon: Icon(
                                              CupertinoIcons.search,
                                              color:
                                                  Theme.of(context).accentColor,
                                            ),
                                            border: InputBorder.none,
                                            hintText:
                                                "Songs, albums or artists",
                                          ),
                                          autofocus: false,
                                          onSubmitted: (query) {
                                            if (query.trim() == '') {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                      'Invalid search',
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .accentColor),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        Text(
                                                            'Please enter a valid search query'),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                          style: TextButton
                                                              .styleFrom(
                                                            primary: Theme.of(
                                                                    context)
                                                                .accentColor,
                                                          ),
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text('Ok'))
                                                    ],
                                                  );
                                                },
                                              );
                                            } else {
                                              List search = Hive.box('settings')
                                                  .get('search',
                                                      defaultValue: []);
                                              if (search.contains(query))
                                                search.remove(query);
                                              search.insert(0, query);
                                              if (search.length > 10)
                                                search = search.sublist(0, 10);
                                              Hive.box('settings')
                                                  .put('search', search);
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          SearchPage(
                                                              query: query)));
                                            }
                                            controller.text = '';
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ];
                              },
                              body: TrendingPage(),
                            ),
                          ),
                          Builder(
                            builder: (context) => Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, left: 4.0),
                              child: Transform.rotate(
                                angle: 22 / 7 * 2,
                                child: IconButton(
                                  icon: const Icon(Icons
                                      .horizontal_split_rounded), // line_weight_rounded),
                                  // color: Theme.of(context).accentColor,
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
                        status: status,
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
                return AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  height: 60 *
                      (MediaQuery.of(context).size.height - value) /
                      (MediaQuery.of(context).size.height - 76),
                  child: SalomonBottomBar(
                    currentIndex: _selectedIndex,
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
                        title: Text("Spotify Top Charts"),
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
              })),
    );
  }
}
