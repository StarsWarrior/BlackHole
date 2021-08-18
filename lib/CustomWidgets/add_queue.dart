import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';

class AddToQueueButton extends StatefulWidget {
  final Map data;
  const AddToQueueButton({Key? key, required this.data}) : super(key: key);

  @override
  _AddToQueueButtonState createState() => _AddToQueueButtonState();
}

class _AddToQueueButtonState extends State<AddToQueueButton> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
        icon: Icon(
          Icons.more_vert_rounded,
          color: Theme.of(context).iconTheme.color,
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(7.0))),
        itemBuilder: (context) => [
              PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(
                        Icons.queue_music_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const Spacer(),
                      const Text('Play Next'),
                      const Spacer(),
                    ],
                  )),
              PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(
                        Icons.queue_music_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const Spacer(),
                      const Text('Add to Queue'),
                      const Spacer(),
                    ],
                  )),
              PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(
                        Icons.playlist_add_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const Spacer(),
                      const Text('Add to playlist'),
                      const Spacer(),
                    ],
                  )),
            ],
        onSelected: (int? value) {
          final MediaItem mediaItem =
              MediaItemConverter().mapToMediaItem(widget.data);

          if (value == 0) {
            AddToPlaylist().addToPlaylist(context, mediaItem);
          }
          if (value == 1) {
            final MediaItem? event = AudioService.currentMediaItem;
            if (event != null &&
                event.extras!['url'].toString().startsWith('http')) {
              // TODO: make sure to check if song is already in queue
              AudioService.addQueueItem(mediaItem);

              ShowSnackBar().showSnackBar(
                context,
                'Added "${mediaItem.title}" to Queue',
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

          if (value == 2) {
            final MediaItem? event = AudioService.currentMediaItem;
            if (event != null &&
                event.extras!['url'].toString().startsWith('http')) {
              // TODO: make sure to check if song is already in queue
              AudioService.addQueueItemAt(mediaItem, -1);

              ShowSnackBar().showSnackBar(
                context,
                'Added "${mediaItem.title}" to Queue',
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
