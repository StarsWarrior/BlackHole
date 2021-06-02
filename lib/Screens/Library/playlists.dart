import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/GradientContainers.dart';
import 'package:blackhole/Helpers/webView.dart';
import 'package:blackhole/Screens/Library/liked.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/APIs/spotifyApi.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PlaylistScreen extends StatefulWidget {
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  Box settingsBox = Hive.box('settings');
  List playlistNames;
  @override
  Widget build(BuildContext context) {
    try {
      playlistNames = settingsBox.get('playlistNames').toList();
    } catch (e) {
      playlistNames = null;
    }

    return GradientContainer(
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
                physics: BouncingScrollPhysics(),
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
                                        if (value == null ||
                                            value.trim() == '') {
                                          playlistNames == null
                                              ? value = 'Playlist 0'
                                              : value =
                                                  'Playlist ${playlistNames.length}';
                                        }
                                        playlistNames == null
                                            ? playlistNames = [value]
                                            : playlistNames.add(value);
                                        settingsBox.put(
                                            'playlistNames', playlistNames);
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
                                    if (_controller.text == null ||
                                        _controller.text.trim() == '') {
                                      playlistNames == null
                                          ? _controller.text = 'Playlist 0'
                                          : _controller.text =
                                              'Playlist ${playlistNames.length}';
                                    }
                                    playlistNames == null
                                        ? playlistNames = [_controller.text]
                                        : playlistNames.add(_controller.text);
                                    settingsBox.put(
                                        'playlistNames', playlistNames);
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
                    ListTile(
                        title: Text('Import from Spotify'),
                        leading: Icon(
                          MdiIcons.spotify,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? null
                              : Colors.grey[700],
                        ),
                        onTap: () async {
                          // String code = await SpotifyApi().authenticate();
                          String code = await Navigator.of(context).push(
                            PageRouteBuilder(
                                opaque: false, // set to false
                                pageBuilder: (_, __, ___) => SpotifyWebView()),
                          );
                          // print(code);
                          if (code != 'ERROR') {
                            await fetchPlaylists(
                                code, context, playlistNames, settingsBox);
                            setState(() {
                              playlistNames = playlistNames;
                            });
                          }
                        }),
                    playlistNames == null
                        ? SizedBox()
                        : ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: playlistNames.length,
                            itemBuilder: (context, index) {
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
                                        'playlistNames', playlistNames);
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

void addPlaylist(String name, Map info) async {
  if (name != 'Favorite Songs') await Hive.openBox(name);
  Box playlistBox = Hive.box(name);
  playlistBox.put(info['id'].toString(), info);
}

fetchPlaylists(code, context, playlistNames, settingsBox) async {
  List data = await SpotifyApi().getAccessToken(code);
  if (data.length != 0) {
    String accessToken = data[0];
    List spotifyPlaylists = await SpotifyApi().getUserPlaylists(accessToken);
    int index = await showModalBottomSheet(
        isDismissible: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return BottomGradientContainer(
            child: ListView.builder(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                scrollDirection: Axis.vertical,
                itemCount: spotifyPlaylists.length,
                itemBuilder: (context, index) {
                  String playName = spotifyPlaylists[index]['name'];
                  int playTotal = spotifyPlaylists[index]['tracks']['total'];
                  return ListTile(
                    title: Text(playName),
                    subtitle: Text(playTotal == 1
                        ? '$playTotal Song'
                        : '$playTotal Songs'),
                    leading: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0)),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        errorWidget: (context, _, __) => Image(
                          image: AssetImage('assets/cover.jpg'),
                        ),
                        imageUrl:
                            '${spotifyPlaylists[index]["images"][0]['url'].replaceAll('http:', 'https:')}',
                        placeholder: (context, url) => Image(
                          image: AssetImage('assets/cover.jpg'),
                        ),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context, index);
                    },
                  );
                }),
          );
        });
    String playName = spotifyPlaylists[index]['name'];
    int _total = spotifyPlaylists[index]['tracks']['total'];
    Stream<Map> songsAdder() async* {
      int _done = 0;
      List tracks = [];
      for (int i = 0; i * 100 <= _total; i++) {
        List temp = await SpotifyApi().getTracksOfPlaylist(
            accessToken, spotifyPlaylists[index]['id'], i * 100);

        tracks.addAll(temp);
      }
      playlistNames == null
          ? playlistNames = [playName]
          : playlistNames.add(playName);
      settingsBox.put('playlistNames', playlistNames);

      for (Map track in tracks) {
        String trackArtist;
        String trackName;
        try {
          trackArtist = track['track']['artists'][0]['name'].toString();
          trackName = track['track']['name'].toString();
          yield {'done': ++_done, 'name': trackName};
        } catch (e) {
          yield {'done': ++_done, 'name': ''};
        }
        try {
          List result =
              await Search().fetchTopSearchResult('$trackName by $trackArtist');
          addPlaylist(playName, result[0]);
        } catch (e) {
          print('Error in $_done: $e');
        }
      }
    }

    await showModalBottomSheet(
      isDismissible: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        // songsAdder();
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStt) {
          return BottomGradientContainer(
            child: SizedBox(
              height: 300,
              width: 300,
              child: StreamBuilder<Object>(
                  stream: songsAdder(),
                  builder: (context, snapshot) {
                    Map data = snapshot?.data;
                    int _done = (data ?? const {})['done'] ?? 0;
                    String name = (data ?? const {})['name'] ?? '';
                    if (_done == _total) Navigator.pop(context);
                    return Stack(
                      children: [
                        Center(
                          child: Text('$_done / $_total'),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Center(
                                child: Text(
                              'Converting Songs',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            )),
                            SizedBox(
                              height: 75,
                              width: 75,
                              child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).accentColor),
                                  value: _done / _total),
                            ),
                            Center(
                                child: Text(
                              name,
                              textAlign: TextAlign.center,
                            )),
                          ],
                        ),
                      ],
                    );
                  }),
            ),
          );
        });
      },
    );
  } else {
    print("Failed");
  }
  return;
}
