import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class RecentlyPlayed extends StatefulWidget {
  @override
  _RecentlyPlayedState createState() => _RecentlyPlayedState();
}

class _RecentlyPlayedState extends State<RecentlyPlayed> {
  List _songs = [];
  bool added = false;

  Future<void> getSongs() async {
    _songs = Hive.box('cache').get('recentSongs', defaultValue: []) as List;
    added = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!added) {
      getSongs();
    }

    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text('Last Session'),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.secondary,
                elevation: 0,
                actions: [
                  IconButton(
                    onPressed: () {
                      Hive.box('cache').put('recentSongs', []);
                      setState(() {
                        _songs = [];
                      });
                    },
                    tooltip: 'Clear All',
                    icon: const Icon(Icons.clear_all_rounded),
                  ),
                ],
              ),
              body: _songs.isEmpty
                  ? EmptyScreen().emptyScreen(context, 3, 'Nothing to ', 15,
                      'Show Here', 50.0, 'Go and Play Something', 23.0)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      shrinkWrap: true,
                      itemCount: _songs.length,
                      itemExtent: 70.0,
                      itemBuilder: (context, index) {
                        return _songs.isEmpty
                            ? const SizedBox()
                            : Dismissible(
                                key: Key(_songs[index]['id'].toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                    color: Colors.redAccent,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: const [
                                          Icon(Icons.delete_outline_rounded),
                                        ],
                                      ),
                                    )),
                                onDismissed: (direction) {
                                  _songs.removeAt(index);
                                  setState(() {});
                                  Hive.box('cache').put('recentSongs', _songs);
                                },
                                child: ListTile(
                                  leading: Card(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7.0),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CachedNetworkImage(
                                      errorWidget: (context, _, __) =>
                                          const Image(
                                        image: AssetImage('assets/cover.jpg'),
                                      ),
                                      imageUrl: _songs[index]['image']
                                          .toString()
                                          .replaceAll('http:', 'https:'),
                                      placeholder: (context, url) =>
                                          const Image(
                                        image: AssetImage('assets/cover.jpg'),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    '${_songs[index]["title"]}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${_songs[index]["artist"]}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (_, __, ___) =>
                                                PlayScreen(
                                                  data: {
                                                    'response': _songs,
                                                    'index': index,
                                                    'offline': false,
                                                  },
                                                  fromMiniplayer: false,
                                                )));
                                  },
                                ),
                              );
                      }),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
