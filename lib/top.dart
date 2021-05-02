import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:csv/csv.dart';

List<List> items = [];
List<List> globalItems = [];
bool fetched = false;

class TopPage extends StatefulWidget {
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  void getData() async {
    Response response = await get(Uri.https(
        "www.spotifycharts.com", "/regional/in/daily/latest/download"));
    // print(response.body);
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter(eol: '\n').convert(response.body);
    rowsAsListOfValues.removeAt(0);
    rowsAsListOfValues.removeAt(0);
    items = rowsAsListOfValues;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (!fetched) {
      getData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.width / 6,
            width: MediaQuery.of(context).size.width / 6,
            child: items.length == 0
                ? CircularProgressIndicator(
                    strokeWidth: 5,
                  )
                : SizedBox(),
          ),
        ),
        Column(
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
                      icon: const Icon(Icons
                          .horizontal_split_rounded), // line_weight_rounded),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      tooltip: MaterialLocalizations.of(context)
                          .openAppDrawerTooltip,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Column(
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
            //         Expanded(
            //           child: ListView.builder(
            //             itemCount: items.length,
            //             itemBuilder: (context, index) {
            //               return ListTile(
            //                 leading: Card(
            //                   elevation: 5,
            //                   shape: RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(7.0),
            //                   ),
            //                   clipBehavior: Clip.antiAlias,
            //                   child: Stack(
            //                     children: [
            //                       Image(
            //                         image: AssetImage('assets/cover.jpg'),
            //                       ),
            //                       Padding(
            //                         padding: const EdgeInsets.all(3.0),
            //                         child: Text(
            //                           (index + 1).toString(),
            //                           style: TextStyle(color: Colors.white),
            //                         ),
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //                 title: Text('${items[index][1].split("(")[0]}'),
            //                 subtitle: Text('${items[index][2].split("(")[0]}'),
            //                 onTap: () {
            //                   Navigator.pushNamed(context, '/search',
            // //                       arguments: items[index][1]);
            //                 },
            //               );
            //             },
            //           ),
            //         ),
          ],
        ),
      ],
    );
  }
}

class GlobalPage extends StatefulWidget {
  @override
  _GlobalPageState createState() => _GlobalPageState();
}

class _GlobalPageState extends State<GlobalPage> {
  void getData() async {
    Response response = await get(Uri.https(
        "www.spotifycharts.com", "/regional/global/daily/latest/download"));
    // print(response.body);
    List<List<dynamic>> rowsAsListOfValues =
        const CsvToListConverter(eol: '\n').convert(response.body);
    rowsAsListOfValues.removeAt(0);
    rowsAsListOfValues.removeAt(0);
    globalItems = rowsAsListOfValues;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (!fetched) {
      getData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: SizedBox(
            height: MediaQuery.of(context).size.width / 6,
            width: MediaQuery.of(context).size.width / 6,
            child: globalItems.length == 0
                ? CircularProgressIndicator(
                    strokeWidth: 5,
                  )
                : SizedBox(),
          ),
        ),
        Column(
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
                      icon: const Icon(Icons
                          .horizontal_split_rounded), // line_weight_rounded),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      tooltip: MaterialLocalizations.of(context)
                          .openAppDrawerTooltip,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Column(
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
            // Expanded(
            //   child: ListView.builder(
            //     itemCount: globalItems.length,
            //     itemBuilder: (context, index) {
            //       return ListTile(
            //         leading: Card(
            //           elevation: 5,
            //           shape: RoundedRectangleBorder(
            //             borderRadius: BorderRadius.circular(7.0),
            //           ),
            //           clipBehavior: Clip.antiAlias,
            //           child: Stack(
            //             children: [
            //               Image(
            //                 image: AssetImage('assets/cover.jpg'),
            //               ),
            //               Padding(
            //                 padding: const EdgeInsets.all(3.0),
            //                 child: Text(
            //                   (index + 1).toString(),
            //                   style: TextStyle(color: Colors.white),
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //         title: Text(
            //             '${globalItems[index][1].toString().split("(")[0]}'),
            //         subtitle: Text('${globalItems[index][2].split("(")[0]}'),
            //         onTap: () {
            //           Navigator.pushNamed(context, '/search',
            //               arguments: globalItems[index][1].toString());
            //         },
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ],
    );
  }
}
