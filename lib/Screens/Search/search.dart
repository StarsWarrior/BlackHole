import 'dart:ui';
import 'package:blackhole/CustomWidgets/add_queue.dart';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Screens/Search/albums.dart';
import 'package:blackhole/Screens/Search/artists.dart';
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
  Map<String, List> searchedData = {};
  Map<int, String> position = {};
  List<int> sortedKeys = [];
  bool fetched = false;
  bool albumFetched = false;
  List search = Hive.box('settings').get('search', defaultValue: []);
  FloatingSearchBarController _controller = FloatingSearchBarController();

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      // this fetches top 5 songs results
      SaavnAPI()
          .fetchSongSearchResults(query == '' ? widget.query : query, '5')
          .then((value) {
        setState(() {
          searchedData["Songs"] = value;
          fetched = true;
        });
      });
      // this fetches albums, playlists, artists, etc
      SaavnAPI()
          .fetchSearchResults(query == '' ? widget.query : query)
          .then((value) {
        setState(() {
          searchedData.addEntries(value[0].entries);
          position = value[1];
          sortedKeys = position.keys.toList()..sort();
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
                      searchedData = {};
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
                                        searchedData = {};

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
                      : (searchedData.isEmpty)
                          ? EmptyScreen().emptyScreen(context, 0, ":( ", 100,
                              "SORRY", 60, "Results Not Found", 20)
                          : SingleChildScrollView(
                              padding: EdgeInsets.only(top: 80),
                              physics: BouncingScrollPhysics(),
                              child: Column(
                                  children: sortedKeys.map(
                                (e) {
                                  String key = position[e];
                                  List value = searchedData[key];
                                  bool first = e == sortedKeys[0];
                                  if (value == null) return SizedBox();
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: first
                                            ? EdgeInsets.fromLTRB(25, 0, 0, 0)
                                            : EdgeInsets.fromLTRB(25, 30, 0, 0),
                                        child: Row(
                                          children: [
                                            Text(
                                              key,
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
                                        itemCount: value.length,
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        padding:
                                            EdgeInsets.fromLTRB(5, 0, 10, 0),
                                        itemBuilder: (context, index) {
                                          int count =
                                              value[index]["count"] ?? 0;
                                          String countText =
                                              value[index]["artist"];
                                          count > 1
                                              ? countText = '$count Songs'
                                              : countText = '$count Song';
                                          return ListTile(
                                            contentPadding:
                                                EdgeInsets.only(left: 15.0),
                                            title: Text(
                                              '${value[index]["title"]}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              key == 'Albums' ||
                                                      (key == 'Top Result' &&
                                                          value[0]["type"] ==
                                                              'album')
                                                  ? '$countText\n${value[index]["subtitle"]}'
                                                  : '${value[index]["subtitle"]}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            isThreeLine: key == 'Albums' ||
                                                (key == 'Top Result' &&
                                                    value[0]["type"] ==
                                                        'album'),
                                            leading: Card(
                                              elevation: 8,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(key ==
                                                                  'Artists' ||
                                                              (key == 'Top Result' &&
                                                                  value[0][
                                                                          "type"] ==
                                                                      'artist')
                                                          ? 50.0
                                                          : 7.0)),
                                              clipBehavior: Clip.antiAlias,
                                              child: CachedNetworkImage(
                                                errorWidget: (context, _, __) =>
                                                    Image(
                                                  image: AssetImage(key ==
                                                              'Artists' ||
                                                          (key == 'Top Result' &&
                                                              value[0][
                                                                      "type"] ==
                                                                  'artist')
                                                      ? 'assets/artist.png'
                                                      : key == 'Songs'
                                                          ? 'assets/cover.jpg'
                                                          : 'assets/album.png'),
                                                ),
                                                imageUrl:
                                                    '${value[index]["image"].replaceAll('http:', 'https:')}',
                                                placeholder: (context, url) =>
                                                    Image(
                                                  image: AssetImage(key ==
                                                              'Artists' ||
                                                          (key == 'Top Result' &&
                                                              value[0][
                                                                      "type"] ==
                                                                  'artist')
                                                      ? 'assets/artist.png'
                                                      : key == 'Songs'
                                                          ? 'assets/cover.jpg'
                                                          : 'assets/album.png'),
                                                ),
                                              ),
                                            ),
                                            trailing: key != 'Albums'
                                                ? key == 'Songs'
                                                    ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                            DownloadButton(
                                                              data:
                                                                  value[index],
                                                              icon: 'download',
                                                            ),
                                                            AddToQueueButton(
                                                                data: value[
                                                                    index]),
                                                          ])
                                                    : null
                                                : AlbumDownloadButton(
                                                    albumName: value[index]
                                                        ['title'],
                                                    albumId: value[index]
                                                        ['id']),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder: (_, __, ___) => key ==
                                                              'Artists' ||
                                                          (key == 'Top Result' &&
                                                              value[0][
                                                                      "type"] ==
                                                                  'artist')
                                                      ? ArtistSearchPage(
                                                          artistName:
                                                              value[index]
                                                                  ['title'],
                                                          artistToken: value[
                                                                  index]
                                                              ['artistToken'],
                                                          artistImage: value[
                                                                      index]
                                                                  ['image']
                                                              .replaceAll(
                                                                  "150x150",
                                                                  "500x500")
                                                              .replaceAll(
                                                                  '50x50',
                                                                  "500x500"),
                                                        )
                                                      : key == 'Songs'
                                                          ? PlayScreen(
                                                              data: {
                                                                  'response':
                                                                      value,
                                                                  'index':
                                                                      index,
                                                                  'offline':
                                                                      false,
                                                                },
                                                              fromMiniplayer:
                                                                  false)
                                                          : SongsListPage(
                                                              listImage:
                                                                  value[index]
                                                                      ["image"],
                                                              listItem:
                                                                  value[index]),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      if (key != 'Top Result')
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(25, 0, 25, 0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              GestureDetector(
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "View All",
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .caption
                                                            .color,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons
                                                          .chevron_right_rounded,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .caption
                                                          .color,
                                                    ),
                                                  ],
                                                ),
                                                onTap: () {
                                                  if (key == 'Albums' ||
                                                      key == 'Playlists' ||
                                                      key == 'Artists')
                                                    Navigator.push(
                                                        context,
                                                        PageRouteBuilder(
                                                          opaque: false,
                                                          pageBuilder: (_, __,
                                                                  ___) =>
                                                              AlbumSearchPage(
                                                            query: query == ''
                                                                ? widget.query
                                                                : query,
                                                            type: key,
                                                          ),
                                                        ));
                                                  if (key == 'Songs')
                                                    Navigator.push(
                                                        context,
                                                        PageRouteBuilder(
                                                          opaque: false,
                                                          pageBuilder: (_, __,
                                                                  ___) =>
                                                              SongsListPage(
                                                                  listItem: {
                                                                "id": query ==
                                                                        ''
                                                                    ? widget
                                                                        .query
                                                                    : query,
                                                                "title": key,
                                                                "type": "songs",
                                                              }),
                                                        ));
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ).toList())),
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
