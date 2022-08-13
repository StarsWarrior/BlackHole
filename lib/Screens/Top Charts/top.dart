/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2022, Ankit Sangwan
 */

import 'dart:convert';

import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
// import 'package:blackhole/Helpers/countrycodes.dart';
import 'package:blackhole/Screens/Search/search.dart';
// import 'package:blackhole/Screens/Settings/setting.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:html_unescape/html_unescape_small.dart';
import 'package:http/http.dart';

List topSongs = [];
List viralSongs = [];
List cachedTopSongs = [];
List cachedViralSongs = [];
bool fetched = false;
bool emptyTop = false;
bool emptyViral = false;

class TopCharts extends StatefulWidget {
  final PageController pageController;
  const TopCharts({super.key, required this.pageController});

  @override
  _TopChartsState createState() => _TopChartsState();
}

class _TopChartsState extends State<TopCharts>
    with AutomaticKeepAliveClientMixin<TopCharts> {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext cntxt) {
    super.build(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool rotated = MediaQuery.of(context).size.height < screenWidth;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          // actions: [
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 8.0),
          //     child: IconButton(
          //       icon: const Icon(Icons.my_location_rounded),
          //       onPressed: () async {
          //         await SpotifyCountry().changeCountry(context: context);
          //       },
          //     ),
          //   ),
          // ],
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(
                child: Text(
                  AppLocalizations.of(context)!.top,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1!.color,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  AppLocalizations.of(context)!.viral,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1!.color,
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            AppLocalizations.of(context)!.spotifyCharts,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyText1!.color,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: (rotated && screenWidth < 1050)
              ? null
              : Builder(
                  builder: (BuildContext context) {
                    return Transform.rotate(
                      angle: 22 / 7 * 2,
                      child: IconButton(
                        color: Theme.of(context).iconTheme.color,
                        icon: const Icon(
                          Icons.horizontal_split_rounded,
                        ),
                        onPressed: () {
                          Scaffold.of(cntxt).openDrawer();
                        },
                        tooltip: MaterialLocalizations.of(cntxt)
                            .openAppDrawerTooltip,
                      ),
                    );
                  },
                ),
        ),
        body: NotificationListener(
          onNotification: (overscroll) {
            if (overscroll is OverscrollNotification &&
                overscroll.overscroll != 0 &&
                overscroll.dragDetails != null) {
              widget.pageController.animateToPage(
                overscroll.overscroll < 0 ? 0 : 2,
                curve: Curves.ease,
                duration: const Duration(milliseconds: 150),
              );
            }
            return true;
          },
          child: const TabBarView(
            physics: CustomPhysics(),
            children: [
              // ValueListenableBuilder(
              //   valueListenable: Hive.box('settings').listenable(),
              //   builder: (BuildContext context, Box box, Widget? widget) {
              //     return TopPage(
              //       region: CountryCodes
              //           .countryCodes[box.get('region', defaultValue: 'India')]
              //           .toString(),
              //     );
              //   },
              // ),
              TopPage(type: 'top'),
              TopPage(type: 'viral'),
            ],
          ),
        ),
      ),
    );
  }
}

Future<List> scrapData(String type) async {
  const String authority = 'www.volt.fm';
  const String topPath = '/charts/spotify-top';
  const String viralPath = '/charts/spotify-viral';
  // const String weeklyPath = '/weekly';

  final String unencodedPath = type == 'top' ? topPath : viralPath;
  // if (isWeekly) unencodedPath += weeklyPath;

  final Response res = await get(Uri.https(authority, unencodedPath));

  if (res.statusCode != 200) return List.empty();
  final result = RegExp(r'<script.*>({\"context\".*})<\/script>', dotAll: true)
      .firstMatch(res.body)![1]!;
  final Map data = json.decode(result) as Map;
  return data['chart_ranking']['tracks'] as List;
}

class TopPage extends StatefulWidget {
  final String type;
  const TopPage({super.key, required this.type});
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage>
    with AutomaticKeepAliveClientMixin<TopPage> {
  Future<void> getData(String type) async {
    fetched = true;
    final List temp = await compute(scrapData, type);
    setState(() {
      if (type == 'top') {
        topSongs = temp;
        if (topSongs.isNotEmpty) {
          cachedTopSongs = topSongs;
          Hive.box('cache').put(type, topSongs);
        }
        emptyTop = topSongs.isEmpty && cachedTopSongs.isEmpty;
      } else {
        viralSongs = temp;
        if (viralSongs.isNotEmpty) {
          cachedViralSongs = viralSongs;
          Hive.box('cache').put(type, viralSongs);
        }
        emptyViral = viralSongs.isEmpty && cachedViralSongs.isEmpty;
      }
    });
  }

  Future<void> getCachedData(String type) async {
    fetched = true;
    if (type == 'top') {
      cachedTopSongs =
          await Hive.box('cache').get(type, defaultValue: []) as List;
    } else {
      cachedViralSongs =
          await Hive.box('cache').get(type, defaultValue: []) as List;
    }
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'top' && topSongs.isEmpty) {
      getCachedData(widget.type);
      getData(widget.type);
    } else {
      if (viralSongs.isEmpty) {
        getCachedData(widget.type);
        getData(widget.type);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isTop = widget.type == 'top';
    if (!fetched) {
      getCachedData(widget.type);
      getData(widget.type);
    }
    final List showList = isTop ? cachedTopSongs : cachedViralSongs;
    final bool isListEmpty = isTop ? emptyTop : emptyViral;
    return Column(
      children: [
        if (showList.length <= 10)
          Expanded(
            child: isListEmpty
                ? emptyScreen(
                    context,
                    0,
                    ':( ',
                    100,
                    'ERROR',
                    60,
                    'Service Unavailable',
                    20,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                    ],
                  ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: showList.length,
              itemExtent: 70.0,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        const Image(
                          image: AssetImage('assets/cover.jpg'),
                        ),
                        if (showList[index]['image_url_small'] != '')
                          CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl:
                                showList[index]['image_url_small'].toString(),
                            errorWidget: (context, _, __) => const Image(
                              fit: BoxFit.cover,
                              image: AssetImage('assets/cover.jpg'),
                            ),
                            placeholder: (context, url) => const Image(
                              fit: BoxFit.cover,
                              image: AssetImage('assets/cover.jpg'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  title: Text(
                    '${index + 1}. ${showList[index]["name"]}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    (showList[index]['artists'] as List)
                        .map((e) => e['name'])
                        .toList()
                        .join(', '),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchPage(
                          query: showList[index]['name'].toString(),
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
  }
}
