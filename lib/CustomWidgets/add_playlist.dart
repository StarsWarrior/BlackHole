import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/Helpers/playlist.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:blackhole/CustomWidgets/gradientContainers.dart';

class AddToPlaylist {
  void addToPlaylist(BuildContext context, MediaItem mediaItem) {
    showModalBottomSheet(
        isDismissible: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          final settingsBox = Hive.box('settings');
          List playlistNames = settingsBox.get('playlistNames')?.toList() ?? [];
          Map playlistDetails =
              settingsBox.get('playlistDetails', defaultValue: {});

          return BottomGradientContainer(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Create Playlist'),
                    leading: Card(
                      elevation: 0,
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Center(
                          child: Icon(
                            Icons.add_rounded,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? null
                                    : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Create new playlist',
                                      style: TextStyle(
                                          color: Theme.of(context).accentColor),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                TextField(
                                    cursorColor: Theme.of(context).accentColor,
                                    controller: controller,
                                    autofocus: true,
                                    onSubmitted: (String value) {
                                      if (value.trim() == '') {
                                        value =
                                            'Playlist ${playlistNames.length}';
                                      }
                                      if (playlistNames.contains(value))
                                        value = value + ' (1)';
                                      playlistNames.add(value);
                                      settingsBox.put(
                                          'playlistNames', playlistNames);
                                      Navigator.pop(context);
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
                                  if (controller.text.trim() == '') {
                                    controller.text =
                                        'Playlist ${playlistNames.length}';
                                  }
                                  if (playlistNames.contains(controller.text))
                                    controller.text = controller.text + ' (1)';
                                  playlistNames.add(controller.text);

                                  settingsBox.put(
                                      'playlistNames', playlistNames);
                                  Navigator.pop(context);
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
                  playlistNames.isEmpty
                      ? SizedBox()
                      : ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: playlistNames.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                                leading: playlistDetails[
                                                playlistNames[index]] ==
                                            null ||
                                        playlistDetails[playlistNames[index]]
                                                ['imagesList'] ==
                                            null
                                    ? Card(
                                        elevation: 5,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(7.0),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: SizedBox(
                                          height: 50,
                                          width: 50,
                                          child: Image(
                                              image: AssetImage(
                                                  'assets/album.png')),
                                        ),
                                      )
                                    : Collage(
                                        imageList: playlistDetails[
                                            playlistNames[index]]['imagesList'],
                                        placeholderImage: 'assets/cover.jpg'),
                                title: Text(
                                  '${playlistDetails.containsKey(playlistNames[index]) ? playlistDetails[playlistNames[index]]["name"] ?? playlistNames[index] : playlistNames[index]}',
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  addItemToPlaylist(
                                      playlistNames[index], mediaItem);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      duration: Duration(seconds: 2),
                                      elevation: 6,
                                      backgroundColor: Colors.grey[900],
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(
                                        'Added to ${playlistDetails.containsKey(playlistNames[index]) ? playlistDetails[playlistNames[index]]["name"] ?? playlistNames[index] : playlistNames[index]}',
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
                                });
                          }),
                ],
              ),
            ),
          );
        });
  }
}
