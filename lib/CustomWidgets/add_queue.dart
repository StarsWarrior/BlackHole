import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:share_plus/share_plus.dart';

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
            borderRadius: BorderRadius.all(Radius.circular(15.0))),
        itemBuilder: (context) => [
              PopupMenuItem(
                  value: 2,
                  child: Row(
                    children: [
                      Icon(
                        Icons.queue_music_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 10.0),
                      const Text('Play Next'),
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
                      const SizedBox(width: 10.0),
                      const Text('Add to Queue'),
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
                      const SizedBox(width: 10.0),
                      const Text('Add to playlist'),
                    ],
                  )),
              PopupMenuItem(
                  value: 3,
                  child: Row(
                    children: [
                      Icon(
                        Icons.share_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 10.0),
                      const Text('Share'),
                    ],
                  )),
            ],
        onSelected: (int? value) {
          final MediaItem mediaItem =
              MediaItemConverter().mapToMediaItem(widget.data);
          if (value == 3) {
            Share.share(widget.data['perma_url'].toString());
          }
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
