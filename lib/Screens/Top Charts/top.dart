import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/Screens/Search/search.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

List items = [];
List globalItems = [];
List cachedItems = [];
List cachedGlobalItems = [];
bool fetched = false;
bool emptyRegional, emptyGlobal = false;

class TopCharts extends StatefulWidget {
  final String region;
  const TopCharts({Key key, @required this.region}) : super(key: key);

  @override
  _TopChartsState createState() => _TopChartsState();
}

class _TopChartsState extends State<TopCharts> {
  @override
  Widget build(BuildContext cntxt) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(
                  child: Text(
                    'Local',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1.color),
                  ),
                ),
                Tab(
                  child: Text(
                    'Global',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1.color),
                  ),
                ),
              ],
            ),
            title: Text(
              'Spotify Top Charts',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyText1.color,
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
                    icon: const Icon(Icons
                        .horizontal_split_rounded), // line_weight_rounded),
                    onPressed: () {
                      Scaffold.of(cntxt).openDrawer();
                    },
                    tooltip:
                        MaterialLocalizations.of(cntxt).openAppDrawerTooltip,
                  ),
                );
              },
            ),
          ),
          body: TabBarView(
            children: [
              TopPage(
                region: widget.region,
              ),
              TopPage(
                region: 'global',
              ),
            ],
          ),
        ));
  }
}

Future<List> scrapData(String region) async {
  // print('starting expensive operation');
  HtmlUnescape unescape = HtmlUnescape();
  String authority = "www.spotifycharts.com";
  String unencodedPath = '/regional/' + region + '/daily/latest/';
  Response res = await get(Uri.https(authority, unencodedPath));

  if (res.statusCode != 200) return List.empty();
  List result = RegExp(
          r'\<td class=\"chart-table-image\"\>\n[ ]*?\<a href=\"https:\/\/open\.spotify\.com\/track\/(.*?)\" target=\"_blank\"\>\n[ ]*?\<img src=\"(https:\/\/i\.scdn\.co\/image\/.*?)\"\>\n[ ]*?\<\/a\>\n[ ]*?<\/td\>\n[ ]*?<td class=\"chart-table-position\">([0-9]*?)<\/td>\n[ ]*?<td class=\"chart-table-trend\">[.|\n| ]*<.*\n[ ]*<.*\n[ ]*<.*\n[ ]*<.*\n[ ]*<td class=\"chart-table-track\">\n[ ]*?<strong>(.*?)<\/strong>\n[ ]*?<span>by (.*?)<\/span>\n[ ]*?<\/td>\n[ ]*?<td class="chart-table-streams">(.*?)<\/td>')
      .allMatches(res.body)
      .map((m) {
    return {
      'id': m[1],
      'image': m[2],
      'position': m[3],
      'title': unescape.convert(m[4]),
      'album': '',
      'artist': unescape.convert(m[5]),
      'streams': m[6],
      "region": region,
    };
  }).toList();
  // print('finished expensive operation');
  return result;
}

class TopPage extends StatefulWidget {
  final region;
  TopPage({Key key, @required this.region}) : super(key: key);
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  void getData(String region) async {
    if (region != 'global') fetched = true;
    List temp = await compute(scrapData, region);
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

  getCachedData(String region) async {
    if (region != 'global') fetched = true;
    if (region != 'global')
      cachedItems = await Hive.box('cache').get(region) ?? [];
    if (region == 'global')
      cachedGlobalItems = await Hive.box('cache').get(region) ?? [];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.region == 'global' && globalItems.length == 0) {
      getCachedData(widget.region);
      getData(widget.region);
    } else {
      if (items.length == 0) {
        getCachedData(widget.region);
        getData(widget.region);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isGlobal = widget.region == 'global';
    if (!fetched) {
      getCachedData(widget.region);
      getData(widget.region);
    }
    List showList = (isGlobal ? cachedGlobalItems : cachedItems);
    bool isListEmpty = isGlobal ? emptyGlobal : emptyRegional;
    return Column(
      children: [
        showList.length <= 50
            ? Expanded(
                child: isListEmpty != null && isListEmpty
                    ? EmptyScreen().emptyScreen(context, 0, ":( ", 100, "ERROR",
                        60, "Service Unavailable", 20)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.width / 6,
                              width: MediaQuery.of(context).size.width / 6,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).accentColor),
                                strokeWidth: 5,
                              )),
                        ],
                      ),
              )
            : Expanded(
                child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: showList.length,
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
                          Image(
                            image: AssetImage('assets/cover.jpg'),
                          ),
                          if (showList[index]['image'] != '')
                            CachedNetworkImage(
                              imageUrl: showList[index]['image'],
                              errorWidget: (context, _, __) => Image(
                                image: AssetImage('assets/cover.jpg'),
                              ),
                              placeholder: (context, url) => Image(
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
                              builder: (context) =>
                                  SearchPage(query: showList[index]['title'])));
                    },
                  );
                },
              )),
      ],
    );
  }
}
