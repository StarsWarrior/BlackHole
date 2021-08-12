import 'package:audio_service/audio_service.dart';
import 'package:blackhole/Helpers/playlist.dart';
import 'package:flutter/material.dart';

class AddListToQueueButton extends StatefulWidget {
  final List data;
  final String title;
  AddListToQueueButton({Key key, @required this.data, @required this.title})
      : super(key: key);

  @override
  _AddListToQueueButtonState createState() => _AddListToQueueButtonState();
}

class _AddListToQueueButtonState extends State<AddListToQueueButton> {
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
                  value: 0,
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
                  value: 1,
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      Spacer(),
                      Text('Save Playlist'),
                      Spacer(),
                    ],
                  )),
            ],
        onSelected: (value) {
          if (value == 1) {
            addPlaylist(widget.title, widget.data).then(
                (value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      duration: Duration(seconds: 2),
                      elevation: 6,
                      backgroundColor: Colors.grey[900],
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Added"${widget.title}" to Playlists',
                        style: TextStyle(color: Colors.white),
                      ),
                      action: SnackBarAction(
                        textColor: Theme.of(context).accentColor,
                        label: 'Ok',
                        onPressed: () {},
                      ),
                    )));
          }
          if (value == 0) {
            MediaItem event = AudioService.currentMediaItem;
            if (event != null &&
                event.extras['url'].toString().startsWith('http')) {
              // TODO: make sure to check if song is already in queue
              AudioService.customAction('addListToQueue', widget.data);

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: Duration(seconds: 2),
                elevation: 6,
                backgroundColor: Colors.grey[900],
                behavior: SnackBarBehavior.floating,
                content: Text(
                  'Added "${widget.title}" to Queue',
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
