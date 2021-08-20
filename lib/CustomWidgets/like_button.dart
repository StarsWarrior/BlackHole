import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/playlist.dart';

class LikeButton extends StatefulWidget {
  final MediaItem mediaItem;
  final double? size;
  const LikeButton({Key? key, required this.mediaItem, this.size})
      : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool liked = false;

  @override
  Widget build(BuildContext context) {
    try {
      liked = checkPlaylist('Favorite Songs', widget.mediaItem.id);
    } catch (e) {
      // print('Error: $e');
    }
    return IconButton(
        icon: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? Colors.redAccent : Theme.of(context).iconTheme.color,
        ),
        iconSize: widget.size ?? 24.0,
        tooltip: liked ? 'Unlike' : 'Like',
        onPressed: () {
          liked
              ? removeLiked(widget.mediaItem.id)
              : addItemToPlaylist('Favorite Songs', widget.mediaItem);

          setState(() {
            liked = !liked;
          });
          ShowSnackBar().showSnackBar(
            context,
            liked ? 'Added to Favorites' : 'Removed from Favorites',
            action: SnackBarAction(
                textColor: Theme.of(context).accentColor,
                label: 'Undo',
                onPressed: () {
                  liked
                      ? removeLiked(widget.mediaItem.id)
                      : addItemToPlaylist('Favorite Songs', widget.mediaItem);
                  liked = !liked;
                  setState(() {});
                }),
          );
        });
  }
}
