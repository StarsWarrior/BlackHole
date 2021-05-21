import 'package:flutter/material.dart';
import 'package:web_scraper/web_scraper.dart';

List<Map> items = [];
List<Map> globalItems = [];

class TopPage extends StatefulWidget {
  final region;
  final status;
  TopPage({Key key, @required this.region, @required this.status})
      : super(key: key);
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  final webScraper = WebScraper("https://www.spotifycharts.com");

  void getData(region) async {
    await webScraper.loadWebPage('/regional/' + region + '/daily/latest/');
    for (int i = 1; i <= 200; i++) {
      final title = webScraper.getElement(
          "#content > div > div > div > span > table > tbody > tr:nth-child($i) > td.chart-table-track > strong",
          []);
      final artist = webScraper.getElement(
          "#content > div > div > div > span > table > tbody > tr:nth-child($i) > td.chart-table-track > span",
          []);
      try {
        if (region == 'global') {
          globalItems.add({
            'title': title[0]['title'],
            'artist': artist[0]['title'].replaceFirst('by ', ''),
            'image': ''
          });
        } else {
          items.add({
            'title': title[0]['title'],
            'artist': artist[0]['title'].replaceFirst('by ', ''),
            'image': ''
          });
        }
      } catch (e) {
        // print(e);
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.region == 'global' && globalItems.length == 0) {
      getData(widget.region);
    } else {
      if (items.length == 0) {
        getData(widget.region);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map> showList = (widget.region == 'global' ? globalItems : items);
    return Column(
      children: [
        AppBar(
          title: Text(
            'Spotify Top Chart',
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
                  icon: const Icon(
                      Icons.horizontal_split_rounded), // line_weight_rounded),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                ),
              );
            },
          ),
        ),
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
                child: widget.status
                    ? ListView.builder(
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
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ":( ",
                                style: TextStyle(
                                  fontSize: 100,
                                  color: Theme.of(context).accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    "ERROR",
                                    style: TextStyle(
                                      fontSize: 60,
                                      color: Theme.of(context).accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "Service Unavailable",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
      ],
    );
  }
}
