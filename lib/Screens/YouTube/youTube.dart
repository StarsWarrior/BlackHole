import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Screens/YouTube/youtube_search.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTube extends StatefulWidget {
  const YouTube({Key key}) : super(key: key);

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube> {
  bool status = false;
  List<Video> searchedList = [];
  bool fetched = false;
  String playlist = 'PLnc6mq_nY21P4Ap1SIYC3v6uBQkvKrY3M';
  String globalTopVideos = 'PL4fGSI1pDJn5kI81J1fYWK5eZRl1zJ5kM';
  String globalTopSongs = 'PL4fGSI1pDJn6puJdseH2Rt9sMvt9E2M4i';
  String hitList = 'RDCLAK5uy_kmPRjHDECIcuVwnKsx2Ng7fyNgFKWNJFs';
  bool done = true;
  List ytSearch = Hive.box('settings').get('ytSearch', defaultValue: []);
  FloatingSearchBarController _controller = FloatingSearchBarController();

  @override
  void initState() {
    if (!status) {
      status = true;
      YouTubeServices().getPlaylistSongs(hitList).then((value) {
        if (value.isNotEmpty)
          setState(() {
            searchedList = value;
            fetched = true;
          });
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext cntxt) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FloatingSearchBar(
        borderRadius: BorderRadius.circular(8.0),
        controller: _controller,
        automaticallyImplyBackButton: false,
        automaticallyImplyDrawerHamburger: false,
        elevation: 8.0,
        insets: EdgeInsets.zero,
        leadingActions: [
          FloatingSearchBarAction.icon(
            onTap: () => _controller.close(),
            icon: Icon(Icons.arrow_back_rounded),
            showIfOpened: true,
            showIfClosed: false,
          ),
          FloatingSearchBarAction.icon(
            showIfClosed: true,
            size: 20.0,
            icon: Transform.rotate(
              angle: 22 / 7 * 2,
              child: Icon(
                Icons.horizontal_split_rounded,
                color: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : Colors.grey[700],
              ),
            ),
            onTap: () {
              Scaffold.of(context).openDrawer();
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
        onSubmitted: (_query) {
          _controller.close();
          Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => YouTubeSearchPage(
                query: _query,
              ),
            ),
          );
          setState(() {
            if (ytSearch.contains(_query)) ytSearch.remove(_query);
            ytSearch.insert(0, _query);
            if (ytSearch.length > 10) ytSearch = ytSearch.sublist(0, 10);
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
            borderRadius: BorderRadius.circular(8),
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
                              ytSearch.remove(e);
                              ytSearch.insert(0, e);
                              Hive.box('settings').put('ytSearch', ytSearch);
                            });
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => YouTubeSearchPage(
                                  query: e,
                                ),
                              ),
                            );
                          }))
                      .toList()),
            ),
          );
        },
        body: Stack(
          children: [
            (!fetched)
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
                : ListView.builder(
                    itemCount: searchedList.length,
                    physics: BouncingScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(15, 80, 15, 0),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          clipBehavior: Clip.antiAlias,
                          child: GradientContainer(
                            child: GestureDetector(
                              child: Column(
                                children: [
                                  CachedNetworkImage(
                                    errorWidget: (context, _, __) =>
                                        CachedNetworkImage(
                                      imageUrl: (searchedList[index]
                                          .thumbnails
                                          .standardResUrl),
                                      errorWidget: (context, _, __) => Image(
                                        image: AssetImage('assets/ytCover.png'),
                                      ),
                                    ),
                                    imageUrl: searchedList[index]
                                        .thumbnails
                                        .maxResUrl,
                                    placeholder: (context, url) => Image(
                                      image: AssetImage('assets/ytCover.png'),
                                    ),
                                  ),
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.only(left: 15.0),
                                    title: Text(
                                      searchedList[index].title,
                                      // '${searchedList[index]["title"].trim()}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    // isThreeLine: true,
                                    subtitle: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(searchedList[index].author),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 15.0),
                                          child: Text(
                                            searchedList[index]
                                                .duration
                                                .toString()
                                                .split(".")[0],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                print('pressed');
                                setState(() {
                                  done = false;
                                });

                                Map response = await YouTubeServices()
                                    .formatVideo(searchedList[index]);
                                setState(() {
                                  done = true;
                                });
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder: (_, __, ___) => PlayScreen(
                                      fromMiniplayer: false,
                                      data: {
                                        'response': [response],
                                        'index': 0,
                                        'offline': false,
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
                  height: MediaQuery.of(context).size.width / 2,
                  width: MediaQuery.of(context).size.width / 2,
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    clipBehavior: Clip.antiAlias,
                    child: GradientContainer(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SizedBox(
                                height: MediaQuery.of(context).size.width / 6,
                                width: MediaQuery.of(context).size.width / 6,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).accentColor),
                                  strokeWidth: 5,
                                )),
                            Text('Coverting Video to Audio'),
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
    );
  }
}
