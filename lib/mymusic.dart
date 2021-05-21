import 'package:blackhole/album.dart';
import 'package:blackhole/downloaded.dart';
import 'package:blackhole/miniplayer.dart';
import 'package:flutter/material.dart';

class MyMusicScreen extends StatefulWidget {
  final String type;
  MyMusicScreen({Key key, @required this.type}) : super(key: key);
  @override
  _MyMusicScreenState createState() => _MyMusicScreenState();
}

class _MyMusicScreenState extends State<MyMusicScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Colors.grey[850],
                  Colors.grey[900],
                  Colors.black,
                ]
              : [
                  Colors.white,
                  Theme.of(context).canvasColor,
                ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  widget.type == 'all' ? 'My Music' : 'Downloaded',
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).accentColor,
                elevation: 0,
              ),
              body: ListView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.all(5),
                children: [
                  SizedBox(height: 5),
                  ListTile(
                    title: Text(
                      'Songs',
                    ),
                    leading: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image(
                        image: AssetImage('assets/song.png'),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DownloadedSongs(type: widget.type)));
                    },
                  ),
                  SizedBox(height: 5),
                  ListTile(
                    title: Text('Albums'),
                    leading: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image(
                        image: AssetImage('assets/album.png'),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false, // set to false
                          pageBuilder: (_, __, ___) =>
                              AlbumSongs(data: 'album', type: widget.type),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 5),
                  ListTile(
                    title: Text('Artists'),
                    leading: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image(
                        image: AssetImage('assets/artist.png'),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          opaque: false, // set to false
                          pageBuilder: (_, __, ___) =>
                              AlbumSongs(data: 'artist', type: widget.type),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
