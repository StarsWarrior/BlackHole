import 'dart:ui';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:hive/hive.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeSearchPage extends StatefulWidget {
  final String query;
  YouTubeSearchPage({Key key, @required this.query}) : super(key: key);
  @override
  _YouTubeSearchPageState createState() => _YouTubeSearchPageState();
}

class _YouTubeSearchPageState extends State<YouTubeSearchPage> {
  String query;
  bool status = false;
  List<Video> searchedList = [];
  bool fetched = false;
  bool done = true;
  List ytSearch = Hive.box('settings').get('ytSearch', defaultValue: []);
  FloatingSearchBarController _controller = FloatingSearchBarController();

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      YouTubeServices().fetchSearchResults(query ?? widget.query).then((value) {
        setState(() {
          searchedList = value;
          fetched = true;
        });
      });
    }
    return GradientContainer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: FloatingSearchBar(
                  borderRadius: BorderRadius.circular(10.0),
                  controller: _controller,
                  automaticallyImplyBackButton: false,
                  automaticallyImplyDrawerHamburger: false,
                  elevation: 8.0,
                  insets: EdgeInsets.zero,
                  leadingActions: [
                    FloatingSearchBarAction.icon(
                      showIfClosed: true,
                      showIfOpened: true,
                      size: 20.0,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? null
                            : Colors.grey[700],
                      ),
                      onTap: () {
                        _controller.isOpen
                            ? _controller.close()
                            : Navigator.of(context).pop();
                      },
                    ),
                  ],
                  hint: 'Search on YouTube',
                  height: 52.0,
                  margins: EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 15.0),
                  scrollPadding: EdgeInsets.only(bottom: 50),
                  backdropColor: Colors.black12,
                  transitionCurve: Curves.easeInOut,
                  physics: BouncingScrollPhysics(),
                  axisAlignment: 0.0,
                  openAxisAlignment: 0.0,
                  debounceDelay: Duration(milliseconds: 500),
                  // onQueryChanged: (_query) {
                  // print(_query);
                  // },
                  onSubmitted: (_query) async {
                    _controller.close();
                    setState(() {
                      fetched = false;
                      query = _query;
                      status = false;
                      searchedList = [];
                      if (ytSearch.contains(_query)) ytSearch.remove(_query);
                      ytSearch.insert(0, _query);
                      if (ytSearch.length > 10)
                        ytSearch = ytSearch.sublist(0, 10);
                      Hive.box('settings').put('ytSearch', ytSearch);
                    });
                  },
                  transition: CircularFloatingSearchBarTransition(),
                  actions: [
                    FloatingSearchBarAction(
                      showIfOpened: false,
                      child: CircularButton(
                        icon: Icon(CupertinoIcons.search),
                        onPressed: () {},
                      ),
                    ),
                    FloatingSearchBarAction(
                      showIfOpened: true,
                      showIfClosed: false,
                      child: CircularButton(
                        icon: Icon(
                          CupertinoIcons.clear,
                          size: 20.0,
                        ),
                        onPressed: () {
                          _controller.clear();
                        },
                      ),
                    ),
                  ],
                  builder: (context, transition) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: GradientCard(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: ytSearch
                                .map((e) => ListTile(
                                    // dense: true,
                                    horizontalTitleGap: 0.0,
                                    title: Text(e),
                                    leading: Icon(CupertinoIcons.search),
                                    trailing: IconButton(
                                        icon: Icon(
                                          CupertinoIcons.clear,
                                          size: 15.0,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            ytSearch.remove(e);
                                            Hive.box('settings')
                                                .put('ytSearch', ytSearch);
                                          });
                                        }),
                                    onTap: () {
                                      _controller.close();
                                      setState(() {
                                        fetched = false;
                                        query = e;
                                        status = false;
                                        searchedList = [];
                                        ytSearch.remove(e);
                                        ytSearch.insert(0, e);
                                        Hive.box('settings')
                                            .put('ytSearch', ytSearch);
                                      });
                                    }))
                                .toList()),
                      ),
                    );
                  },
                  body: (!fetched)
                      ? Container(
                          child: Center(
                            child: Container(
                                height: MediaQuery.of(context).size.width / 6,
                                width: MediaQuery.of(context).size.width / 6,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).accentColor),
                                  strokeWidth: 5,
                                )),
                          ),
                        )
                      : searchedList.length == 0
                          ? EmptyScreen().emptyScreen(context, 0, ":( ", 100,
                              "SORRY", 60, "Results Not Found", 20)
                          : Stack(
                              children: [
                                ListView.builder(
                                  itemCount: searchedList.length,
                                  physics: BouncingScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: EdgeInsets.fromLTRB(15, 80, 15, 0),
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10.0),
                                      child: Card(
                                        elevation: 8,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0)),
                                        clipBehavior: Clip.antiAlias,
                                        child: GradientContainer(
                                          child: GestureDetector(
                                            child: Column(
                                              children: [
                                                CachedNetworkImage(
                                                  errorWidget:
                                                      (context, _, __) => Image(
                                                    image: NetworkImage(
                                                        searchedList[index]
                                                            .thumbnails
                                                            .standardResUrl),
                                                  ),
                                                  imageUrl: searchedList[index]
                                                      .thumbnails
                                                      .maxResUrl,
                                                  placeholder: (context, url) =>
                                                      Image(
                                                    image: AssetImage(
                                                        'assets/ytCover.png'),
                                                  ),
                                                ),
                                                ListTile(
                                                  dense: true,
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0),
                                                  title: Text(
                                                    searchedList[index].title,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  // isThreeLine: true,
                                                  subtitle: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            searchedList[index]
                                                                .author,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            // '${searchedList[index]["channelName"]}'
                                                          ),
                                                          // Text(searchedList[index]
                                                          //         .engagement
                                                          //         .viewCount
                                                          //         .toString()

                                                          //     // '${searchedList[index]["views"]}'
                                                          //     ),
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 15.0),
                                                        child: Text(
                                                          searchedList[index]
                                                                      .duration
                                                                      .toString() ==
                                                                  'null'
                                                              ? 'LIVE NOW'
                                                              : searchedList[
                                                                      index]
                                                                  .duration
                                                                  .toString()
                                                                  .split(
                                                                      ".")[0],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  // leading: CircleAvatar(
                                                  //   maxRadius: 20,
                                                  //   backgroundImage: AssetImage(
                                                  //       'assets/artist.png'),
                                                  //   foregroundImage:
                                                  //       CachedNetworkImageProvider(
                                                  //           'https://yt3.ggpht.com/ytc/AKedOLS47SGZoq9qhTlM6ANNiXN5I3sUcV4_owFydPkU=s68-c-k-c0x00ffffff-no-rj'
                                                  //           // 'https://yt3.ggpht.com/ytc/${searchedList[index].channelId.value}'

                                                  //           // ["channelImage"],
                                                  //           ),
                                                  // ),
                                                ),
                                              ],
                                            ),
                                            onTap: () async {
                                              print('pressed');
                                              setState(() {
                                                done = false;
                                              });

                                              Map response =
                                                  await YouTubeServices()
                                                      .formatVideo(
                                                          searchedList[index]);
                                              setState(() {
                                                done = true;
                                              });
                                              response == null
                                                  ? ScaffoldMessenger.of(
                                                          context)
                                                      .showSnackBar(
                                                      SnackBar(
                                                        elevation: 6,
                                                        backgroundColor:
                                                            Colors.grey[900],
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        content: Text(
                                                          'Video is live. Please wait until the live stream finishes and try again.',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        action: SnackBarAction(
                                                          textColor:
                                                              Theme.of(context)
                                                                  .accentColor,
                                                          label: 'Ok',
                                                          onPressed: () {},
                                                        ),
                                                      ),
                                                    )
                                                  : Navigator.push(
                                                      context,
                                                      PageRouteBuilder(
                                                        opaque: false,
                                                        pageBuilder:
                                                            (_, __, ___) =>
                                                                PlayScreen(
                                                          fromMiniplayer: false,
                                                          data: {
                                                            'response': [
                                                              response
                                                            ],
                                                            'index': 0,
                                                            'offline': false,
                                                            'fromYT': true,
                                                          },
                                                        ),
                                                      ),
                                                    );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (!done)
                                  Center(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width / 2,
                                      width:
                                          MediaQuery.of(context).size.width / 2,
                                      child: Card(
                                        elevation: 10,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15)),
                                        clipBehavior: Clip.antiAlias,
                                        child: GradientContainer(
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                SizedBox(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            6,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            6,
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Theme.of(context)
                                                                  .accentColor),
                                                      strokeWidth: 5,
                                                    )),
                                                Text('Fetching Audio Stream'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                ),
              ),
            ),
            MiniPlayer(),
          ],
        ),
      ),
    );
  }
}
