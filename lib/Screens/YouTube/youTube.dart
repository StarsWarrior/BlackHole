import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/Screens/YouTube/youtube_playlist.dart';
import 'package:blackhole/Screens/YouTube/youtube_search.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

bool status = false;
List searchedList = Hive.box('cache').get('ytHome', defaultValue: []);

class YouTube extends StatefulWidget {
  const YouTube({Key key}) : super(key: key);

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube> {
  String channelId = "UC-9-kyTW8ZkZNDHQJ6FgpwQ";
  List ytSearch = Hive.box('settings').get('ytSearch', defaultValue: []);
  bool showHistory =
      Hive.box('settings').get('showHistory', defaultValue: true);
  FloatingSearchBarController _controller = FloatingSearchBarController();

  @override
  void initState() {
    if (!status) {
      YouTubeServices().getChannelSongs(channelId).then((value) {
        status = true;
        if (value.isNotEmpty) {
          setState(() {
            searchedList = value;
            Hive.box('cache').put('ytHome', value);
          });
        } else {
          status = false;
        }
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext cntxt) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          return !showHistory
              ? SizedBox()
              : ClipRRect(
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
                                    Hive.box('settings')
                                        .put('ytSearch', ytSearch);
                                  });
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (_, __, ___) =>
                                          YouTubeSearchPage(
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
            (searchedList.isEmpty)
                ? Container(
                    child: Center(
                      child: Container(
                          height: MediaQuery.of(context).size.width / 7,
                          width: MediaQuery.of(context).size.width / 7,
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
                    padding: EdgeInsets.fromLTRB(10, 70, 10, 0),
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 10, 0, 5),
                                child: Text(
                                  '${searchedList[index]["title"]}',
                                  style: TextStyle(
                                    color: Theme.of(context).accentColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 4 + 5,
                            child: ListView.builder(
                              physics: BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              itemCount:
                                  searchedList[index]["playlists"].length,
                              itemBuilder: (context, idx) {
                                final item =
                                    searchedList[index]["playlists"][idx];
                                return GestureDetector(
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.height / 4 -
                                            30,
                                    child: Column(
                                      children: [
                                        Card(
                                          elevation: 5,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: CachedNetworkImage(
                                            errorWidget: (context, _, __) =>
                                                Image(
                                              image: AssetImage(
                                                  'assets/cover.jpg'),
                                            ),
                                            imageUrl: item["image"],
                                            placeholder: (context, url) =>
                                                Image(
                                              image: AssetImage(
                                                  'assets/cover.jpg'),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${item["title"]}',
                                          textAlign: TextAlign.center,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "${item["count"]} Tracks | ${item["description"]}",
                                          textAlign: TextAlign.center,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .caption
                                                  .color),
                                        )
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        opaque: false,
                                        pageBuilder: (_, __, ___) =>
                                            YouTubePlaylist(
                                          playlistId: item['playlistId'],
                                          playlistImage: item['imageStandard'],
                                          playlistName: item['title'],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),
          ],
        ),
      ),
    );
  }
}
