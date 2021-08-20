import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:blackhole/Screens/Library/downloaded.dart';
import 'package:blackhole/Screens/Library/liked.dart';

class LibraryPage extends StatefulWidget {
  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  Box? likedBox;

  @override
  void initState() {
    super.initState();
    Hive.openBox('Favorite Songs');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        AppBar(
          title: const Text(
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
        LibraryTile(
          title: 'Now Playing',
          icon: Icons.queue_music_rounded,
          onTap: () {
            Navigator.pushNamed(context, '/nowplaying');
          },
        ),
        LibraryTile(
          title: 'Last Session',
          icon: Icons.history_rounded,
          onTap: () {
            Navigator.pushNamed(context, '/recent');
          },
        ),
        LibraryTile(
          title: 'Favorites',
          icon: Icons.favorite_rounded,
          onTap: () async {
            await Hive.openBox('Favorite Songs');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const LikedSongs(playlistName: 'Favorite Songs')));
          },
        ),
        LibraryTile(
          title: 'My Music',
          icon: MdiIcons.folderMusic,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const DownloadedSongs(type: 'all')));
          },
        ),
        LibraryTile(
          title: 'Downloads',
          icon: Icons.download_done_rounded,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const DownloadedSongs(type: 'downloaded')));
          },
        ),
        LibraryTile(
          title: 'Playlists',
          icon: Icons.playlist_play_rounded,
          onTap: () {
            Navigator.pushNamed(context, '/playlists');
          },
        ),
      ],
    );
  }
}

class LibraryTile extends StatelessWidget {
  const LibraryTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  final String title;
  final IconData icon;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).iconTheme.color,
        ),
      ),
      leading: Icon(
        icon,
        color: Theme.of(context).iconTheme.color,
      ),
      onTap: onTap,
    );
  }
}
