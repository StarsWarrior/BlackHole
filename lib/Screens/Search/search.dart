import 'dart:ui';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/add_queue.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Screens/Search/albums.dart';
import 'package:blackhole/Screens/Search/artists.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

class SearchPage extends StatefulWidget {
  final String query;
  final bool fromHome;
  const SearchPage({Key? key, required this.query, this.fromHome = false})
      : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';
  bool status = false;
  Map searchedData = {};
  Map position = {};
  List sortedKeys = [];
  final ValueNotifier<List<String>> topSearch = ValueNotifier<List<String>>([]);
  bool fetched = false;
  bool albumFetched = false;
  bool? fromHome;
  List search = Hive.box('settings').get('search', defaultValue: []) as List;
  bool showHistory =
      Hive.box('settings').get('showHistory', defaultValue: true) as bool;
  final FloatingSearchBarController _controller = FloatingSearchBarController();

  @override
  void initState() {
    _controller.query = widget.query;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchResults() async {
    // this fetches top 5 songs results
    searchedData['Songs'] = await SaavnAPI()
        .fetchSongSearchResults(query == '' ? widget.query : query, '5');
    fetched = true;
    // this fetches albums, playlists, artists, etc
    final List<Map> value =
        await SaavnAPI().fetchSearchResults(query == '' ? widget.query : query);

    searchedData.addEntries(value[0].entries);
    position = value[1];
    sortedKeys = position.keys.toList()..sort();
    albumFetched = true;
    setState(() {});
  }

  Future<void> getTrendingSearch() async {
    topSearch.value = await SaavnAPI().getTopSearches();
  }

  @override
  Widget build(BuildContext context) {
    fromHome ??= widget.fromHome;
    if (!status) {
      status = true;
      fromHome! ? getTrendingSearch() : fetchResults();
    }
    return GradientContainer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scaffold(
                resizeToAvoidBottomInset: false,
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
                      showIfOpened: true,
                      size: 20.0,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
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
                  margins: const EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 15.0),
                  scrollPadding: const EdgeInsets.only(bottom: 50),
                  backdropColor: Colors.black45,
                  transitionCurve: Curves.easeInOut,
                  physics: const BouncingScrollPhysics(),
                  openAxisAlignment: 0.0,
                  clearQueryOnClose: false,
                  debounceDelay: const Duration(milliseconds: 500),
                  // onQueryChanged: (_query) {
                  // print(_query);
                  // },
                  onSubmitted: (_query) {
                    _controller.close();

                    setState(() {
                      fetched = false;
                      query = _query;
                      status = false;
                      fromHome = false;
                      searchedData = {};
                      if (search.contains(_query)) search.remove(_query);
                      search.insert(0, _query);
                      if (search.length > 5) search = search.sublist(0, 5);
                      Hive.box('settings').put('search', search);
                    });
                  },
                  transition:
                      // CircularFloatingSearchBarTransition(),
                      SlideFadeFloatingSearchBarTransition(),
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
                    if (!showHistory) return const SizedBox();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GradientCard(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: search
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
                                        tooltip: 'Remove',
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
                                        query = e.toString();
                                        _controller.query = query;
                                        status = false;
                                        fromHome = false;
                                        searchedData = {};

                                        search.remove(e);
                                        search.insert(0, e);
                                        if (search.length > 5) {
                                          search = search.sublist(0, 5);
                                        }
                                        Hive.box('settings')
                                            .put('search', search);
                                      });
                                    }))
                                .toList()),
                      ),
                    );
                  },
                  body: fromHome!
                      ? ValueListenableBuilder(
                          valueListenable: topSearch,
                          builder: (BuildContext context, List<String> value,
                              Widget? child) {
                            if (value.isEmpty) return const SizedBox();
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        25, 90, 10, 0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Trending Search',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            fontSize: 25,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ListView.builder(
                                      itemCount: value.length,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 10, 10, 0),
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                            horizontalTitleGap: 0.0,
                                            title: Text(value[index]),
                                            leading: const Icon(
                                                Icons.trending_up_rounded),
                                            onTap: () {
                                              _controller.close();
                                              setState(() {
                                                fetched = false;
                                                query = value[index];
                                                _controller.query = query;
                                                status = false;
                                                fromHome = false;
                                                searchedData = {};
                                                search.insert(0, value[index]);
                                                if (search.length > 5) {
                                                  search = search.sublist(0, 5);
                                                }
                                                Hive.box('settings')
                                                    .put('search', search);
                                              });
                                            });
                                      })
                                ],
                              ),
                            );
                          })
                      : !fetched
                          ? SizedBox(
                              child: Center(
                                child: SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 7,
                                    width:
                                        MediaQuery.of(context).size.width / 7,
                                    child: const CircularProgressIndicator()),
                              ),
                            )
                          : (searchedData.isEmpty)
                              ? EmptyScreen().emptyScreen(context, 0, ':( ',
                                  100, 'SORRY', 60, 'Results Not Found', 20)
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.only(top: 80),
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                      children: sortedKeys.map(
                                    (e) {
                                      final String key = position[e].toString();
                                      final List? value =
                                          searchedData[key] as List?;
                                      final bool first = e == sortedKeys[0];
                                      if (value == null) {
                                        return const SizedBox();
                                      }
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: first
                                                ? const EdgeInsets.fromLTRB(
                                                    25, 0, 0, 0)
                                                : const EdgeInsets.fromLTRB(
                                                    25, 30, 0, 0),
                                            child: Row(
                                              children: [
                                                Text(
                                                  key,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ListView.builder(
                                            itemCount: value.length,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            padding: const EdgeInsets.fromLTRB(
                                                5, 0, 10, 0),
                                            itemBuilder: (context, index) {
                                              final int count = value[index]
                                                      ['count'] as int? ??
                                                  0;
                                              String countText = value[index]
                                                      ['artist']
                                                  .toString();
                                              count > 1
                                                  ? countText = '$count Songs'
                                                  : countText = '$count Song';
                                              return ListTile(
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                        left: 15.0),
                                                title: Text(
                                                  '${value[index]["title"]}',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                subtitle: Text(
                                                  key == 'Albums' ||
                                                          (key == 'Top Result' &&
                                                              value[0][
                                                                      'type'] ==
                                                                  'album')
                                                      ? '$countText\n${value[index]["subtitle"]}'
                                                      : '${value[index]["subtitle"]}',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                isThreeLine: key == 'Albums' ||
                                                    (key == 'Top Result' &&
                                                        value[0]['type'] ==
                                                            'album'),
                                                leading: Card(
                                                  elevation: 8,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius
                                                          .circular(key ==
                                                                      'Artists' ||
                                                                  (key == 'Top Result' &&
                                                                      value[0][
                                                                              'type'] ==
                                                                          'artist')
                                                              ? 50.0
                                                              : 7.0)),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: CachedNetworkImage(
                                                    errorWidget:
                                                        (context, _, __) =>
                                                            Image(
                                                      image: AssetImage(key ==
                                                                  'Artists' ||
                                                              (key == 'Top Result' &&
                                                                  value[0][
                                                                          'type'] ==
                                                                      'artist')
                                                          ? 'assets/artist.png'
                                                          : key == 'Songs'
                                                              ? 'assets/cover.jpg'
                                                              : 'assets/album.png'),
                                                    ),
                                                    imageUrl:
                                                        '${value[index]["image"].replaceAll('http:', 'https:')}',
                                                    placeholder:
                                                        (context, url) => Image(
                                                      image: AssetImage(key ==
                                                                  'Artists' ||
                                                              (key == 'Top Result' &&
                                                                  value[0][
                                                                          'type'] ==
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
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                                DownloadButton(
                                                                  data: value[
                                                                          index]
                                                                      as Map,
                                                                  icon:
                                                                      'download',
                                                                ),
                                                                AddToQueueButton(
                                                                    data: value[
                                                                            index]
                                                                        as Map),
                                                              ])
                                                        : null
                                                    : AlbumDownloadButton(
                                                        albumName: value[index]
                                                                ['title']
                                                            .toString(),
                                                        albumId: value[index]
                                                                ['id']
                                                            .toString(),
                                                      ),
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    PageRouteBuilder(
                                                      opaque: false,
                                                      pageBuilder: (_, __, ___) => key ==
                                                                  'Artists' ||
                                                              (key == 'Top Result' &&
                                                                  value[0][
                                                                          'type'] ==
                                                                      'artist')
                                                          ? ArtistSearchPage(
                                                              artistName: value[
                                                                          index]
                                                                      ['title']
                                                                  .toString(),
                                                              artistToken: value[
                                                                          index]
                                                                      [
                                                                      'artistToken']
                                                                  .toString(),
                                                              artistImage: value[
                                                                          index]
                                                                      ['image']
                                                                  .toString()
                                                                  .replaceAll(
                                                                      '150x150',
                                                                      '500x500')
                                                                  .replaceAll(
                                                                      '50x50',
                                                                      '500x500'),
                                                            )
                                                          : key == 'Songs'
                                                              ? PlayScreen(
                                                                  data: {
                                                                      'response':
                                                                          [
                                                                        value[
                                                                            index]
                                                                      ],
                                                                      'index':
                                                                          0,
                                                                      'offline':
                                                                          false,
                                                                    },
                                                                  fromMiniplayer:
                                                                      false)
                                                              : SongsListPage(
                                                                  listItem: value[
                                                                          index]
                                                                      as Map),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                          if (key != 'Top Result')
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      25, 0, 25, 0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () {
                                                      if (key == 'Albums' ||
                                                          key == 'Playlists' ||
                                                          key == 'Artists') {
                                                        Navigator.push(
                                                            context,
                                                            PageRouteBuilder(
                                                              opaque: false,
                                                              pageBuilder: (_,
                                                                      __,
                                                                      ___) =>
                                                                  AlbumSearchPage(
                                                                query: query ==
                                                                        ''
                                                                    ? widget
                                                                        .query
                                                                    : query,
                                                                type: key,
                                                              ),
                                                            ));
                                                      }
                                                      if (key == 'Songs') {
                                                        Navigator.push(
                                                            context,
                                                            PageRouteBuilder(
                                                              opaque: false,
                                                              pageBuilder: (_,
                                                                      __,
                                                                      ___) =>
                                                                  SongsListPage(
                                                                      listItem: {
                                                                    'id': query ==
                                                                            ''
                                                                        ? widget
                                                                            .query
                                                                        : query,
                                                                    'title':
                                                                        key,
                                                                    'type':
                                                                        'songs',
                                                                  }),
                                                            ));
                                                      }
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          'View All',
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .caption!
                                                                .color,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons
                                                              .chevron_right_rounded,
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .caption!
                                                                  .color,
                                                        ),
                                                      ],
                                                    ),
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
