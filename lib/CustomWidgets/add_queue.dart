import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class AddToQueueButton extends StatefulWidget {
  final MediaItem mediaItem;
  AddToQueueButton({Key key, @required this.mediaItem}) : super(key: key);

  @override
  _AddToQueueButtonState createState() => _AddToQueueButtonState();
}

class _AddToQueueButtonState extends State<AddToQueueButton> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.add_to_queue_rounded),
        iconSize: 25.0,
        onPressed: () {
          AudioService.addQueueItem(widget.mediaItem);
        });
  }
}
