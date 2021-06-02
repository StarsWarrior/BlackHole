import 'package:blackhole/Screens/Library/downloaded.dart';
import 'package:blackhole/Screens/Library/liked.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  Box likedBox;

  @override
  void initState() {
    super.initState();
    Hive.openBox('Favorite Songs');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AppBar(
          title: Text(
            'Library',
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
                    Scaffold.of(context).openDrawer();
                  },
                  tooltip:
                      MaterialLocalizations.of(context).openAppDrawerTooltip,
                ),
              );
            },
          ),
        ),
        ListTile(
          title: Text('Now Playing'),
          leading: Icon(
            Icons.queue_music_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? null
                : Colors.grey[700],
          ),
          onTap: () async {
            Navigator.pushNamed(context, '/nowplaying');
          },
        ),
        ListTile(
          title: Text('Last Session'),
          leading: Icon(
            Icons.history_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? null
                : Colors.grey[700],
          ),
          onTap: () async {
            Navigator.pushNamed(context, '/recent');
          },
        ),
        ListTile(
          title: Text('Favorites'),
          leading: Icon(
            Icons.favorite_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? null
                : Colors.grey[700],
          ),
          onTap: () async {
            await Hive.openBox('Favorite Songs');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        LikedSongs(playlistName: 'Favorite Songs')));
          },
        ),
        ListTile(
          title: Text('My Music'),
          leading: Icon(
            MdiIcons.folderMusic,
            color: Theme.of(context).brightness == Brightness.dark
                ? null
                : Colors.grey[700],
          ),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DownloadedSongs(type: 'all')));
          },
        ),
        ListTile(
          title: Text('Downloads'),
          leading: Icon(
            Icons.download_done_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? null
                : Colors.grey[700],
          ),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DownloadedSongs(type: 'downloaded')));
          },
        ),
        ListTile(
          title: Text('Playlists'),
          leading: Icon(
            Icons.playlist_play_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? null
                : Colors.grey[700],
          ),
          onTap: () {
            Navigator.pushNamed(context, '/playlists');
          },
        ),
      ],
    );
  }
}
