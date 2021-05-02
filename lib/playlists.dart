import 'package:blackhole/liked.dart';
import 'package:blackhole/miniplayer.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class PlaylistScreen extends StatefulWidget {
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  Box settingsBox = Hive.box('settings');
  @override
  Widget build(BuildContext context) {
    var playlistNames;
    try {
      playlistNames = settingsBox.get('playlists').toList();
    } catch (e) {
      playlistNames = null;
    }

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
                  'Playlists',
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Theme.of(context).accentColor,
                elevation: 0,
              ),
              body: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 5),
                    ListTile(
                      title: Text('Create Playlist'),
                      leading: Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? null
                            : Colors.grey[700],
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            final _controller = TextEditingController();
                            return AlertDialog(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Create new playlist',
                                        style: TextStyle(
                                            color:
                                                Theme.of(context).accentColor),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  TextField(
                                      controller: _controller,
                                      autofocus: true,
                                      onSubmitted: (value) {
                                        print(
                                            'PLAYLIST NAMES IS $playlistNames');
                                        playlistNames == null
                                            ? playlistNames = [value]
                                            : playlistNames.add(value);
                                        // print(
                                        //     'PLAYLIST NAMES NOW IS $playlistNames');
                                        settingsBox.put(
                                            'playlists', playlistNames);
                                        Navigator.pop(context);
                                        setState(() {});
                                      }),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    primary: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.grey[700],
                                    //       backgroundColor: Theme.of(context).accentColor,
                                  ),
                                  child: Text("Cancel"),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    primary: Colors.white,
                                    backgroundColor:
                                        Theme.of(context).accentColor,
                                  ),
                                  child: Text(
                                    "Ok",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () {
                                    playlistNames == null
                                        ? playlistNames = [_controller.text]
                                        : playlistNames.add(_controller.text);
                                    print('Putting as $playlistNames');
                                    settingsBox.put('playlists', playlistNames);
                                    Navigator.pop(context);
                                    setState(() {});
                                  },
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    playlistNames == null
                        ? SizedBox()
                        : ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: playlistNames.length,
                            itemBuilder: (context, index) {
                              print('PLAYLIST IS $playlistNames');
                              return ListTile(
                                leading: Icon(
                                  Icons.music_note_rounded,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? null
                                      : Colors.grey[700],
                                ),
                                title: Text('${playlistNames[index]}'),
                                trailing: PopupMenuButton(
                                  icon: Icon(Icons.more_vert_rounded),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(7.0))),
                                  onSelected: (value) async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        elevation: 6,
                                        backgroundColor: Colors.grey[900],
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Deleted ${playlistNames[index]}',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        action: SnackBarAction(
                                          textColor:
                                              Theme.of(context).accentColor,
                                          label: 'Ok',
                                          onPressed: () {},
                                        ),
                                      ),
                                    );
                                    await Hive.openBox(playlistNames[index]);
                                    await Hive.box(playlistNames[index])
                                        .deleteFromDisk();
                                    await playlistNames.removeAt(index);
                                    await settingsBox.put(
                                        'playlists', playlistNames);
                                    setState(() {});
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 0,
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete),
                                          Spacer(),
                                          Text('Delete playlist'),
                                          Spacer(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Hive.openBox(playlistNames[index]);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => LikedSongs(
                                              playlistName:
                                                  playlistNames[index])));
                                  // Navigator.pushNamed(context, '/liked');
                                },
                              );
                            })
                  ],
                ),
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
