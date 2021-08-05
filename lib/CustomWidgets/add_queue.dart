import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:flutter/material.dart';

class AddToQueueButton extends StatefulWidget {
  final Map data;
  AddToQueueButton({Key key, @required this.data}) : super(key: key);

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
        shape: RoundedRectangleBorder(
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
                      Spacer(),
                      Text('Play Next'),
                      Spacer(),
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
                      Spacer(),
                      Text('Add to Queue'),
                      Spacer(),
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
                      Spacer(),
                      Text('Add to playlist'),
                      Spacer(),
                    ],
                  )),
            ],
        onSelected: (value) {
          MediaItem mediaItem =
              MediaItemConverter().mapToMediaItem(widget.data);

          if (value == 0) {
            AddToPlaylist().addToPlaylist(context, mediaItem);
          }
          if (value == 1) {
            MediaItem event = AudioService.currentMediaItem;
            if (event != null &&
                event.extras['url'].toString().startsWith('http')) {
              // TODO: make sure to check if song is already in queue
              AudioService.addQueueItem(mediaItem);

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: Duration(seconds: 2),
                elevation: 6,
                backgroundColor: Colors.grey[900],
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'Added "${mediaItem.title}" to Queue',
                  style: TextStyle(color: Colors.white),
                ),
                action: SnackBarAction(
                  textColor: Theme.of(context).accentColor,
                  label: 'Ok',
                  onPressed: () {},
                ),
              ));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: Duration(seconds: 2),
                elevation: 6,
                backgroundColor: Colors.grey[900],
                behavior: SnackBarBehavior.floating,
                content: Text(
                  (event == null)
                      ? 'Nothing is Playing'
                      : "Can't add Online Song to Offline Queue",
                  style: TextStyle(color: Colors.white),
                ),
                action: SnackBarAction(
                  textColor: Theme.of(context).accentColor,
                  label: 'Ok',
                  onPressed: () {},
                ),
              ));
            }
          }

          if (value == 2) {
            MediaItem event = AudioService.currentMediaItem;
            if (event != null &&
                event.extras['url'].toString().startsWith('http')) {
              // TODO: make sure to check if song is already in queue
              AudioService.addQueueItemAt(mediaItem, -1);

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: Duration(seconds: 2),
                elevation: 6,
                backgroundColor: Colors.grey[900],
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'Added "${mediaItem.title}" to Queue',
                  style: TextStyle(color: Colors.white),
                ),
                action: SnackBarAction(
                  textColor: Theme.of(context).accentColor,
                  label: 'Ok',
                  onPressed: () {},
                ),
              ));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: Duration(seconds: 2),
                elevation: 6,
                backgroundColor: Colors.grey[900],
                behavior: SnackBarBehavior.floating,
                content: Text(
                  (event == null)
                      ? 'Nothing is Playing'
                      : "Can't add Online Song to Offline Queue",
                  style: TextStyle(color: Colors.white),
                ),
                action: SnackBarAction(
                  textColor: Theme.of(context).accentColor,
                  label: 'Ok',
                  onPressed: () {},
                ),
              ));
            }
          }
        });
  }
}
