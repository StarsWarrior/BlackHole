import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

class YouTube extends StatefulWidget {
  const YouTube({Key key}) : super(key: key);

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube> {
  FloatingSearchBarController _controller = FloatingSearchBarController();

  @override
  Widget build(BuildContext cntxt) {
    return Scaffold(
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
        margins: EdgeInsets.all(15.0),
        scrollPadding: EdgeInsets.only(bottom: 50),
        // transitionDuration: Duration(milliseconds: 500),
        backdropColor: Colors.black12,
        transitionCurve: Curves.easeInOut,
        physics: BouncingScrollPhysics(),
        axisAlignment: 0.0,
        openAxisAlignment: 0.0,
        debounceDelay: Duration(milliseconds: 500),
        onQueryChanged: (_query) {
          print(_query);
        },
        onSubmitted: (_query) {
          print("onsubmit " + _query);
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
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Colors.white,
              elevation: 4.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: Colors.accents.map((color) {
                  return Container(height: 112, color: color);
                }).toList(),
              ),
            ),
          );
        },
        body: Center(
          child: Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
