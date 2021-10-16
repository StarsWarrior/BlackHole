import 'package:blackhole/Screens/LocalMusic/downed_songs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyMusicPage extends StatefulWidget {
  @override
  _MyMusicPageState createState() => _MyMusicPageState();
}

class _MyMusicPageState extends State<MyMusicPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myMusic,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          LibraryTile(
            title: AppLocalizations.of(context)!.songs,
            icon: Icons.music_note_rounded,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DownloadedSongs()));
            },
          ),
          LibraryTile(
            title:
                '${AppLocalizations.of(context)!.playlists} (${AppLocalizations.of(context)!.local})',
            icon: Icons.playlist_play_rounded,
            onTap: () {
              Navigator.pushNamed(context, '/localplaylists');
            },
          ),
        ],
      ),
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
      leading: Card(
        elevation: 0,
        color: Colors.transparent,
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(
            child: Icon(
              icon,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
