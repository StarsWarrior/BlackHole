import 'package:flutter/material.dart';

class YouTube extends StatefulWidget {
  const YouTube({Key key}) : super(key: key);

  @override
  _YouTubeState createState() => _YouTubeState();
}

class _YouTubeState extends State<YouTube> {
  @override
  Widget build(BuildContext cntxt) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'YouTube',
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return Transform.rotate(
              angle: 22 / 7 * 2,
              child: IconButton(
                color: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : Colors.grey[700],
                icon: const Icon(
                    Icons.horizontal_split_rounded), // line_weight_rounded),
                onPressed: () {
                  Scaffold.of(cntxt).openDrawer();
                },
                tooltip: MaterialLocalizations.of(cntxt).openAppDrawerTooltip,
              ),
            );
          },
        ),
      ),
      body: Center(
          child: Text(
        'Coming Soon',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
      )),
    );
  }
}
