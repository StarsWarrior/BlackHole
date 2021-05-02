import 'package:blackhole/library.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:blackhole/miniplayer.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'top.dart';
import 'dart:math';
import 'trending.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'miniplayer.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Box settingsBox;
  double appVersion = 1.4;
  bool checked = false;
  bool update = false;
  // final FirebaseAnalytics _analytics = FirebaseAnalytics();
  String capitalize(msg) {
    return "${msg[0].toUpperCase()}${msg.substring(1)}";
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      pageController.animateToPage(index,
          duration: Duration(milliseconds: 500), curve: Curves.linear);
    });
  }

  updateUserDetails(key, value) {
    final userID = Hive.box('settings').get('userID');
    final dbRef = FirebaseDatabase.instance.reference().child("Users");
    dbRef.child(userID).update({"$key": "$value"});
  }

  Widget checkVersion() {
    if (!checked && Theme.of(context).platform == TargetPlatform.android) {
      print('checking......');
      checked = true;
      var now = DateTime.now();
      updateUserDetails('lastLogin',
          '${now.toUtc().add(Duration(hours: 5, minutes: 30)).toString().split('.').first} IST');
      updateUserDetails('timeZone',
          'Zone: ${now.timeZoneName}, Offset: ${now.timeZoneOffset.toString().split('.').first}');
      final dbRef =
          FirebaseDatabase.instance.reference().child("LatestVersion");
      dbRef.once().then((DataSnapshot snapshot) {
        print('Data : ${snapshot.value}');
        if (double.parse(snapshot.value) > appVersion) {
          print('UPDATE IS AVAILABLE');
          return showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Update Available',
                    // textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontWeight: FontWeight.w600)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      'A new update is available. Would you like to update now?',
                      // textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      style: TextButton.styleFrom(
                        primary: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Maybe later')),
                  TextButton(
                      style: TextButton.styleFrom(
                        primary: Colors.white,
                        backgroundColor: Theme.of(context).accentColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        launch(
                            "https://github.com/Sangwan5688/BlackHole/blob/main/BlackHole%20v${snapshot.value}.apk");
                      },
                      child: Text('Update')),
                  SizedBox(
                    width: 5,
                  ),
                ],
              );
            },
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

  _scrollListener() {
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.grey[850],
                  Colors.grey[900],
                  Colors.black,
                ]
              : [
                  Colors.white,
                  Theme.of(context).canvasColor,
                ],
        ),
      ),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          drawer: Drawer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  // stops: [0, 0.2, 0.8, 1],
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          Colors.grey[850],
                          Colors.grey[900],
                          Colors.black,
                        ]
                      : [
                          Colors.white,
                          Theme.of(context).canvasColor,
                        ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: <Widget>[
                        ValueListenableBuilder(
                            valueListenable: Hive.box('settings').listenable(),
                            builder: (context, box, widget) {
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
                                              // title: Text('Name'),
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
                                                        box.put('name', value);
                                                        box.put('email',
                                                            _controller2.text);
                                                        Navigator.pop(context);
                                                        updateUserDetails(
                                                            'name', value);
                                                        updateUserDetails(
                                                            'email',
                                                            _controller2.text);
                                                        // _analytics.logEvent(
                                                        //   name: 'Changed_Name_Email',
                                                        //   parameters: <String,
                                                        //       dynamic>{
                                                        //     'Name': value,
                                                        //     'Email': controller2.text,
                                                        //   },
                                                        // );
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
                                                        box.put('name',
                                                            _controller.text);
                                                        box.put('email', value);
                                                        Navigator.pop(context);
                                                        updateUserDetails(
                                                            'name',
                                                            _controller.text);
                                                        updateUserDetails(
                                                            'email', value);
                                                        // _analytics.logEvent(
                                                        //   name: 'Changed_Name_Email',
                                                        //   parameters: <String,
                                                        //       dynamic>{
                                                        //     'Name': controller.text,
                                                        //     'Email': value,
                                                        //   },
                                                        // );
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
                                                    box.put('name',
                                                        _controller.text);
                                                    box.put('email',
                                                        _controller2.text);
                                                    Navigator.pop(context);
                                                    updateUserDetails('name',
                                                        _controller.text);
                                                    updateUserDetails('email',
                                                        _controller2.text);
                                                    // _analytics.logEvent(
                                                    //   name: 'Changed_Name_Email',
                                                    //   parameters: <String, dynamic>{
                                                    //     'Name': controller.text,
                                                    //     'Email': controller2.text,
                                                    //   },
                                                    // );
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
                                  capitalize(box.get('name')) ?? 'Guest User',
                                ),
                                accountEmail: Text(
                                  box.get('email') ?? 'xxxxxxxxxx@gmail.com',
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
                                    // backgroundImage: AssetImage('assets/cover.jpg'),
                                    child: Text(
                                        box.get('name') == null
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
                          // selectedTileColor: Theme.of(context).accentColor,
                          // tileColor: Theme.of(context).accentColor,
                          selected: true,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          title: Text('My Music'),
                          leading: Icon(
                            Icons.my_library_music_rounded,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/downloaded');
                            print('pressed my music');
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
                            Navigator.pushNamed(context, '/setting');
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
                              physics:
                                  BouncingScrollPhysics(), //NeverScrollableScrollPhysics(),
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
                                                        builder: (context, box,
                                                            widget) {
                                                          return Text(
                                                            box.get('name') ==
                                                                    null
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
                                        // margin: EdgeInsets.zero,

                                        duration: Duration(milliseconds: 300),
                                        // margin: EdgeInsets.only(top: 5),
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
                                              offset: Offset(0.0,
                                                  3.0), // shadow direction: bottom right
                                            )
                                          ],
                                        ),
                                        child: TextField(
                                          controller: controller,
                                          decoration: InputDecoration(
                                            prefixIcon:
                                                Icon(Icons.search_rounded),
                                            border: InputBorder.none,
                                            hintText:
                                                "Songs, artists or podcasts",
                                          ),
                                          autofocus: false,
                                          onSubmitted: (query) {
                                            query == ''
                                                ? showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                          'Invalid search',
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
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
                                                  )
                                                : Navigator.pushNamed(
                                                    context, '/search',
                                                    arguments: query);
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
                      TopPage(),
                      GlobalPage(),
                      LibraryPage(),
                    ],
                  ),
                ),
                MiniPlayer()
              ],
            ),
          ),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () {},
          //   child: Icon(Icons.add),
          //   backgroundColor: Colors.red,
          // ),
          // floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
                        title: Text("Local Top 200"),
                        selectedColor: Theme.of(context).accentColor,
                      ),
                      SalomonBottomBarItem(
                        icon: Icon(Icons.bar_chart_rounded),
                        title: Text("Global Top 200"),
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
