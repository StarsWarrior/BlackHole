import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/playlist.dart';

class AddListToQueueButton extends StatefulWidget {
  final List data;
  final String title;
  const AddListToQueueButton(
      {Key? key, required this.data, required this.title})
      : super(key: key);

  @override
  _AddListToQueueButtonState createState() => _AddListToQueueButtonState();
}

class _AddListToQueueButtonState extends State<AddListToQueueButton> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
        icon: const Icon(
          Icons.more_vert_rounded,
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0))),
        itemBuilder: (context) => [
              PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(
                        Icons.playlist_add_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 10.0),
                      const Text('Add to Queue'),
                    ],
                  )),
              PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 10.0),
                      const Text('Save Playlist'),
                    ],
                  )),
            ],
        onSelected: (int? value) {
          if (value == 1) {
            addPlaylist(widget.title, widget.data).then(
              (value) => ShowSnackBar().showSnackBar(
                context,
                'Added"${widget.title}" to Playlists',
              ),
            );
          }
          if (value == 0) {
            final MediaItem? event = AudioService.currentMediaItem;
            if (event != null &&
                event.extras!['url'].toString().startsWith('http')) {
              // TODO: make sure to check if song is already in queue
              AudioService.customAction('addListToQueue', widget.data);

              ShowSnackBar().showSnackBar(
                context,
                'Added "${widget.title}" to Queue',
              );
            } else {
              ShowSnackBar().showSnackBar(
                context,
                event == null
                    ? 'Nothing is Playing'
                    : "Can't add Online Song to Offline Queue",
              );
            }
          }
        });
  }
}
