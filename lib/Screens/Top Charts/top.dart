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

import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/Helpers/countrycodes.dart';
import 'package:blackhole/Screens/Search/search.dart';
import 'package:blackhole/Screens/Settings/setting.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:http/http.dart';

List items = [];
List globalItems = [];
List cachedItems = [];
List cachedGlobalItems = [];
bool fetched = false;
bool emptyRegional = false;
bool emptyGlobal = false;

class TopCharts extends StatefulWidget {
  final PageController pageController;
  const TopCharts({Key? key, required this.pageController}) : super(key: key);

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: const Icon(Icons.my_location_rounded),
                onPressed: () async {
                  await SpotifyCountry().changeCountry(context: context);
                },
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Text(
                  AppLocalizations.of(context)!.local,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1!.color,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  AppLocalizations.of(context)!.global,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyText1!.color,
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            AppLocalizations.of(context)!.spotifyTopCharts,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).textTheme.bodyText1!.color,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
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
                  tooltip: MaterialLocalizations.of(cntxt).openAppDrawerTooltip,
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
          child: TabBarView(
            physics: const CustomPhysics(),
            children: [
              ValueListenableBuilder(
                valueListenable: Hive.box('settings').listenable(),
                builder: (BuildContext context, Box box, Widget? widget) {
                  return TopPage(
                    region: CountryCodes
                        .countryCodes[box.get('region', defaultValue: 'India')]
                        .toString(),
                  );
                },
              ),
              const TopPage(
                region: 'global',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<List> scrapData(String region) async {
  // print('starting expensive operation');
  final HtmlUnescape unescape = HtmlUnescape();
  const String authority = 'www.spotifycharts.com';
  final String unencodedPath = '/regional/$region/daily/latest/';
  final Response res = await get(Uri.https(authority, unencodedPath));

  if (res.statusCode != 200) return List.empty();
  final List result = RegExp(
    r'\<td class=\"chart-table-image\"\>\n[ ]*?\<a href=\"https:\/\/open\.spotify\.com\/track\/(.*?)\" target=\"_blank\"\>\n[ ]*?\<img src=\"(https:\/\/i\.scdn\.co\/image\/.*?)\"\>\n[ ]*?\<\/a\>\n[ ]*?<\/td\>\n[ ]*?<td class=\"chart-table-position\">([0-9]*?)<\/td>\n[ ]*?<td class=\"chart-table-trend\">[.|\n| ]*<.*\n[ ]*<.*\n[ ]*<.*\n[ ]*<.*\n[ ]*<td class=\"chart-table-track\">\n[ ]*?<strong>(.*?)<\/strong>\n[ ]*?<span>by (.*?)<\/span>\n[ ]*?<\/td>\n[ ]*?<td class="chart-table-streams">(.*?)<\/td>',
  ).allMatches(res.body).map((m) {
    return {
      'id': m[1],
      'image': m[2],
      'position': m[3],
      'title': unescape.convert(m[4]!),
      'album': '',
      'artist': unescape.convert(m[5]!),
      'streams': m[6],
      'region': region,
    };
  }).toList();
  // print('finished expensive operation');
  return result;
}

class TopPage extends StatefulWidget {
  final String region;
  const TopPage({Key? key, required this.region}) : super(key: key);
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage>
    with AutomaticKeepAliveClientMixin<TopPage> {
  Future<void> getData(String region) async {
    fetched = true;
    final List temp = await compute(scrapData, region);
    setState(() {
      if (region == 'global') {
        globalItems = temp;
        if (globalItems.isNotEmpty) {
          cachedGlobalItems = globalItems;
          Hive.box('cache').put(region, globalItems);
        }
        emptyGlobal = globalItems.isEmpty && cachedGlobalItems.isEmpty;
      } else {
        items = temp;
        if (items.isNotEmpty) {
          cachedItems = items;
          Hive.box('cache').put(region, items);
        }
        emptyRegional = items.isEmpty && cachedItems.isEmpty;
      }
    });
  }

  Future<void> getCachedData(String region) async {
    fetched = true;
    if (region != 'global') {
      cachedItems =
          await Hive.box('cache').get(region, defaultValue: []) as List;
    }
    if (region == 'global') {
      cachedGlobalItems =
          await Hive.box('cache').get(region, defaultValue: []) as List;
    }
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.region == 'global' && globalItems.isEmpty) {
      getCachedData(widget.region);
      getData(widget.region);
    } else {
      if (items.isEmpty) {
        getCachedData(widget.region);
        getData(widget.region);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool isGlobal = widget.region == 'global';
    if (!fetched) {
      getCachedData(widget.region);
      getData(widget.region);
    }
    final List showList = isGlobal ? cachedGlobalItems : cachedItems;
    final bool isListEmpty = isGlobal ? emptyGlobal : emptyRegional;
    return Column(
      children: [
        if (showList.length <= 50)
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
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.width / 8,
                        width: MediaQuery.of(context).size.width / 8,
                        child: const CircularProgressIndicator(),
                      ),
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
                        if (showList[index]['image'] != '')
                          CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl: showList[index]['image'].toString(),
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
                    showList[index]['position'] == null
                        ? '${showList[index]["title"]}'
                        : '${showList[index]['position']}. ${showList[index]["title"]}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${showList[index]['artist']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchPage(
                          query: showList[index]['title'].toString(),
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
