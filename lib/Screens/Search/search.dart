import 'dart:ui';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Screens/Search/albums.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/APIs/api.dart';
import 'package:hive/hive.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

class SearchPage extends StatefulWidget {
  final String query;
  SearchPage({Key key, @required this.query}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
  bool status = false;
  List searchedList = [];
  List searchedAlbumList = [];
  bool fetched = false;
  bool albumFetched = false;
  List search = Hive.box('settings').get('search', defaultValue: []);
  FloatingSearchBarController _controller = FloatingSearchBarController();

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      Search()
          .fetchSearchResults(query == '' ? widget.query : query)
          .then((value) {
        setState(() {
          searchedList = value;
          fetched = true;
        });
      });
      Search()
          .fetchAlbumSearchResults(query == '' ? widget.query : query)
          .then((value) {
        setState(() {
          searchedAlbumList = value;
          albumFetched = true;
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
                  hint: 'Songs, albums or artists',
                  progress: !fetched,
                  height: 52.0,
                  margins: EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 15.0),
                  scrollPadding: EdgeInsets.only(bottom: 50),
                  backdropColor: Colors.black12,
                  transitionCurve: Curves.easeInOut,
                  physics: BouncingScrollPhysics(),
                  axisAlignment: 0.0,
                  openAxisAlignment: 0.0,
                  clearQueryOnClose: false,
                  debounceDelay: Duration(milliseconds: 500),
                  // onQueryChanged: (_query) {
                  // print(_query);
                  // },
                  onSubmitted: (_query) {
                    _controller.close();

                    setState(() {
                      fetched = false;
                      query = _query;
                      status = false;
                      searchedList = [];
                      if (search.contains(_query)) search.remove(_query);
                      search.insert(0, _query);
                      if (search.length > 10) search = search.sublist(0, 10);
                      Hive.box('settings').put('search', search);
                    });
                  },
                  transition:
                      // CircularFloatingSearchBarTransition(),
                      SlideFadeFloatingSearchBarTransition(),

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
                            children: search
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
                                            search.remove(e);
                                            Hive.box('settings')
                                                .put('search', search);
                                          });
                                        }),
                                    onTap: () {
                                      _controller.close();

                                      setState(() {
                                        fetched = false;
                                        query = e;
                                        status = false;
                                        searchedList = [];

                                        search.remove(e);
                                        search.insert(0, e);
                                        Hive.box('settings')
                                            .put('search', search);
                                      });
                                    }))
                                .toList()),
                      ),
                    );
                  },
                  body: !fetched
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
                      : (searchedList.isEmpty && searchedAlbumList.isEmpty)
                          ? EmptyScreen().emptyScreen(context, 0, ":( ", 100,
                              "SORRY", 60, "Results Not Found", 20)
                          : (searchedList.isEmpty)
                              ? SizedBox()
                              : SingleChildScrollView(
                                  padding: EdgeInsets.only(top: 80),
                                  physics: BouncingScrollPhysics(),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            25, 10, 0, 0),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Songs',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .accentColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ListView.builder(
                                        itemCount: searchedList.length,
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        padding:
                                            EdgeInsets.fromLTRB(5, 0, 5, 0),
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 7, 7, 5),
                                            child: ListTile(
                                              contentPadding:
                                                  EdgeInsets.only(left: 15.0),
                                              title: Text(
                                                '${searchedList[index]["title"]}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              subtitle: Text(
                                                  '${searchedList[index]["subtitle"]}'),
                                              leading: Card(
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0)),
                                                clipBehavior: Clip.antiAlias,
                                                child: CachedNetworkImage(
                                                  errorWidget:
                                                      (context, _, __) => Image(
                                                    image: AssetImage(
                                                        'assets/cover.jpg'),
                                                  ),
                                                  imageUrl:
                                                      '${searchedList[index]["image"].replaceAll('http:', 'https:')}',
                                                  placeholder: (context, url) =>
                                                      Image(
                                                    image: AssetImage(
                                                        'assets/cover.jpg'),
                                                  ),
                                                ),
                                              ),
                                              trailing: DownloadButton(
                                                data: searchedList[index],
                                                icon: 'download',
                                              ),
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    pageBuilder: (_, __, ___) =>
                                                        PlayScreen(
                                                      data: {
                                                        'response':
                                                            searchedList,
                                                        'index': index,
                                                        'offline': false,
                                                      },
                                                      fromMiniplayer: false,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                      searchedAlbumList.isEmpty
                                          ? SizedBox()
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      25, 30, 0, 0),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    'Albums',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .accentColor,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      ListView.builder(
                                        itemCount: searchedAlbumList.length,
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        padding:
                                            EdgeInsets.fromLTRB(5, 0, 5, 0),
                                        itemBuilder: (context, index) {
                                          int count =
                                              searchedAlbumList[index]["count"];
                                          String countText;
                                          (count > 1)
                                              ? countText = '$count Songs'
                                              : countText = '$count Song';
                                          return ListTile(
                                            contentPadding:
                                                EdgeInsets.only(left: 15.0),
                                            title: Text(
                                              '${searchedAlbumList[index]["title"]}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            subtitle: Text(
                                                '$countText\n${searchedAlbumList[index]["subtitle"]}'),
                                            isThreeLine: true,
                                            leading: Card(
                                              elevation: 8,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          7.0)),
                                              clipBehavior: Clip.antiAlias,
                                              child: CachedNetworkImage(
                                                errorWidget: (context, _, __) =>
                                                    Image(
                                                  image: AssetImage(
                                                      'assets/album.png'),
                                                ),
                                                imageUrl:
                                                    '${searchedAlbumList[index]["image"].replaceAll('http:', 'https:')}',
                                                placeholder: (context, url) =>
                                                    Image(
                                                  image: AssetImage(
                                                      'assets/album.png'),
                                                ),
                                              ),
                                            ),
                                            trailing: AlbumDownloadButton(
                                                albumName:
                                                    searchedAlbumList[index]
                                                        ['title'],
                                                albumId:
                                                    searchedAlbumList[index]
                                                        ['id']),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder: (_, __, ___) =>
                                                      AlbumSearchPage(
                                                    albumName:
                                                        searchedAlbumList[index]
                                                            ['title'],
                                                    albumId:
                                                        searchedAlbumList[index]
                                                            ['id'],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
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
