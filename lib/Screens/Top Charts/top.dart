import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:web_scraper/web_scraper.dart';

List items = [];
List globalItems = [];
List cachedItems = [];
List cachedGlobalItems = [];
bool fetched = false;

class TopCharts extends StatefulWidget {
  final String region;
  final status;
  const TopCharts({Key key, @required this.region, @required this.status})
      : super(key: key);

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
                  child: Text('Local'),
                ),
                Tab(
                  child: Text('Global'),
                ),
              ],
            ),
            title: Text(
              'Spotify Top Charts',
              style: TextStyle(fontSize: 18),
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
                status: widget.status,
              ),
              TopPage(
                region: 'global',
                status: widget.status,
              ),
            ],
          ),
        ));
  }
}

Future<List> scrapData(String region) async {
  final webScraper = WebScraper("https://www.spotifycharts.com");
  print('starting expensive operation');
  List temp = [];
  await webScraper.loadWebPage('/regional/' + region + '/daily/latest/');
  for (int i = 1; i <= 200; i++) {
    final title = webScraper.getElement(
        "#content > div > div > div > span > table > tbody > tr:nth-child($i) > td.chart-table-track > strong",
        []);
    final artist = webScraper.getElement(
        "#content > div > div > div > span > table > tbody > tr:nth-child($i) > td.chart-table-track > span",
        []);
    try {
      temp.add({
        'title': title[0]['title'],
        'artist': artist[0]['title'].replaceFirst('by ', ''),
        'image': ''
      });
    } catch (e) {}
  }
  print('finished expensive operation');
  return temp;
}

class TopPage extends StatefulWidget {
  final region;
  final status;
  TopPage({Key key, @required this.region, @required this.status})
      : super(key: key);
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
        cachedGlobalItems = globalItems;
        Hive.box('cache').put(region, globalItems);
      } else {
        items = temp;
        cachedItems = items;
        Hive.box('cache').put(region, items);
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
    if (!fetched) {
      getCachedData(widget.region);
      getData(widget.region);
    }
    List showList =
        (widget.region == 'global' ? cachedGlobalItems : cachedItems);
    return Column(
      children: [
        showList.length <= 50
            ? Expanded(
                child: Column(
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
                child: !widget.status
                    ? EmptyScreen().emptyScreen(context, 0, ":( ", 100, "ERROR",
                        60, "Service Unavailable", 20)
                    : ListView.builder(
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
                                  Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Text(
                                      (index + 1).toString(),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: Text(
                                '${showList[index]['title'].split("(")[0]}'),
                            subtitle: Text(
                                '${showList[index]['artist'].split("(")[0]}'),
                            onTap: () {
                              Navigator.pushNamed(context, '/search',
                                  arguments: showList[index]['title']);
                            },
                          );
                        },
                      )),
      ],
    );
  }
}
