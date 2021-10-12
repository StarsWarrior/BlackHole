import 'dart:async';

import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/Screens/YouTube/youtube_playlist.dart';
import 'package:blackhole/Screens/YouTube/youtube_search.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

bool status = false;
List searchedList = Hive.box('cache').get('ytHome', defaultValue: []) as List;
List headList = Hive.box('cache').get('ytHomeHead', defaultValue: []) as List;

class YouTube extends StatefulWidget {
  const YouTube({Key? key}) : super(key: key);

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube>
    with AutomaticKeepAliveClientMixin<YouTube> {
  List ytSearch =
      Hive.box('settings').get('ytSearch', defaultValue: []) as List;
  bool showHistory =
      Hive.box('settings').get('showHistory', defaultValue: true) as bool;
  final FloatingSearchBarController _controller = FloatingSearchBarController();
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    if (!status) {
      YouTubeServices().getMusicHome().then((value) {
        status = true;
        if (value.isNotEmpty) {
          setState(() {
            searchedList = value['body'] ?? [];
            headList = value['head'] ?? [];

            Hive.box('cache').put('ytHome', value['body']);
            Hive.box('cache').put('ytHomeHead', value['head']);
          });
        } else {
          status = false;
        }
      });
    }
    if (headList.isNotEmpty) {
      Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (_currentPage < headList.length) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }

        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
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
    super.build(context);
    final double boxSize =
        MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.height;
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
            icon: const Icon(Icons.arrow_back_rounded),
            showIfOpened: true,
            showIfClosed: false,
          ),
          FloatingSearchBarAction.icon(
            size: 20.0,
            icon: Transform.rotate(
              angle: 22 / 7 * 2,
              child: const Icon(
                Icons.horizontal_split_rounded,
              ),
            ),
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ],
        hint: AppLocalizations.of(context)!.searchYt,
        height: 52.0,
        margins: const EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 15.0),
        scrollPadding: const EdgeInsets.only(bottom: 50),
        backdropColor: Colors.black12,
        transitionCurve: Curves.easeInOut,
        physics: const BouncingScrollPhysics(),
        openAxisAlignment: 0.0,
        debounceDelay: const Duration(milliseconds: 500),
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
            child: CircularButton(
              icon: const Icon(CupertinoIcons.search),
              onPressed: () {},
            ),
          ),
          FloatingSearchBarAction(
            showIfOpened: true,
            showIfClosed: false,
            child: CircularButton(
              icon: const Icon(
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
          if (!showHistory) {
            return const SizedBox();
          } else {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GradientCard(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ytSearch
                        .map((e) => ListTile(
                            // dense: true,
                            horizontalTitleGap: 0.0,
                            title: Text(e.toString()),
                            leading: const Icon(CupertinoIcons.search),
                            trailing: IconButton(
                                icon: const Icon(
                                  CupertinoIcons.clear,
                                  size: 15.0,
                                ),
                                tooltip: AppLocalizations.of(context)!.remove,
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
                                  pageBuilder: (_, __, ___) =>
                                      YouTubeSearchPage(
                                    query: e.toString(),
                                  ),
                                ),
                              );
                            }))
                        .toList()),
              ),
            );
          }
        },
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 80, 10, 0),
          child: Column(
            children: [
              if (headList.isNotEmpty)
                SizedBox(
                  height: boxSize / 2 + 20,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: headList.length,
                    onPageChanged: (int value) {
                      _currentPage = value;
                    },
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => YouTubeSearchPage(
                              query: headList[index]['title'].toString(),
                            ),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: boxSize,
                        child: Column(
                          children: [
                            Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                errorWidget: (context, _, __) => const Image(
                                    image: AssetImage('assets/ytCover.png')),
                                imageUrl: headList[index]['image'].toString(),
                                placeholder: (context, url) => const Image(
                                  image: AssetImage('assets/ytCover.png'),
                                ),
                              ),
                            ),
                            // Text(
                            //   '${headList[index]["title"]}',
                            //   textAlign: TextAlign.center,
                            //   softWrap: false,
                            //   overflow: TextOverflow.ellipsis,
                            // ),
                            // Text(
                            //   '${headList[index]["description"]}',
                            //   textAlign: TextAlign.center,
                            //   softWrap: false,
                            //   overflow: TextOverflow.ellipsis,
                            //   style: TextStyle(
                            //       fontSize: 11,
                            //       color: Theme.of(context)
                            //           .textTheme
                            //           .caption!
                            //           .color),
                            // )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (searchedList.isEmpty)
                SizedBox(
                  child: Center(
                    child: SizedBox(
                        height: boxSize / 7,
                        width: boxSize / 7,
                        child: const CircularProgressIndicator()),
                  ),
                )
              else
                ListView.builder(
                    itemCount: searchedList.length,
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 10),
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
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: boxSize / 2 + 10,
                            width: double.infinity,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              itemCount:
                                  (searchedList[index]['playlists'] as List)
                                      .length,
                              itemBuilder: (context, idx) {
                                final item =
                                    searchedList[index]['playlists'][idx];
                                return GestureDetector(
                                  onTap: () {
                                    item['type'] == 'video'
                                        ? Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              opaque: false,
                                              pageBuilder: (_, __, ___) =>
                                                  YouTubeSearchPage(
                                                query: item['title'].toString(),
                                              ),
                                            ),
                                          )
                                        : Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              opaque: false,
                                              pageBuilder: (_, __, ___) =>
                                                  YouTubePlaylist(
                                                playlistId: item['playlistId']
                                                    .toString(),
                                                playlistImage:
                                                    item['imageStandard']
                                                        .toString(),
                                                playlistName:
                                                    item['title'].toString(),
                                              ),
                                            ),
                                          );
                                  },
                                  child: SizedBox(
                                    width: item['type'] != 'playlist'
                                        ? boxSize - 110
                                        : boxSize / 2 - 30,
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
                                            fit: BoxFit.cover,
                                            errorWidget: (context, _, __) =>
                                                Image(
                                              image: item['type'] != 'playlist'
                                                  ? const AssetImage(
                                                      'assets/ytCover.png')
                                                  : const AssetImage(
                                                      'assets/cover.jpg'),
                                            ),
                                            imageUrl: item['image'].toString(),
                                            placeholder: (context, url) =>
                                                Image(
                                              image: item['type'] != 'playlist'
                                                  ? const AssetImage(
                                                      'assets/ytCover.png')
                                                  : const AssetImage(
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
                                          item['type'] != 'video'
                                              ? '${item["count"]} Tracks | ${item["description"]}'
                                              : '${item["count"]} | ${item["description"]}',
                                          textAlign: TextAlign.center,
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .caption!
                                                  .color),
                                        )
                                      ],
                                    ),
                                  ),
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
      ),
    );
  }
}
