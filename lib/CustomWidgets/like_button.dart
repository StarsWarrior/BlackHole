import 'package:audio_service/audio_service.dart';
import 'package:blackhole/Helpers/playlist.dart';
import 'package:flutter/material.dart';

class LikeButton extends StatefulWidget {
  final MediaItem mediaItem;
  final double size;
  const LikeButton({Key key, @required this.mediaItem, this.size})
      : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  bool liked = false;

  @override
  Widget build(BuildContext context) {
    if (widget.mediaItem != null) {
      try {
        liked = checkPlaylist('Favorite Songs', widget.mediaItem.id);
      } catch (e) {}
    }
    return IconButton(
        icon: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? Colors.redAccent : null,
        ),
        iconSize: widget.size ?? 24.0,
        onPressed: () {
          liked
              ? removeLiked(widget.mediaItem.id)
              : addPlaylist('Favorite Songs', widget.mediaItem);
          liked = !liked;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 2),
              action: SnackBarAction(
                  textColor: Theme.of(context).accentColor,
                  label: 'Undo',
                  onPressed: () {
                    liked
                        ? removeLiked(widget.mediaItem.id)
                        : addPlaylist('Favorite Songs', widget.mediaItem);
                    liked = !liked;
                    setState(() {});
                  }),
              elevation: 6,
              backgroundColor: Colors.grey[900],
              behavior: SnackBarBehavior.floating,
              content: Text(
                liked ? 'Added to Favorites' : 'Removed from Favorites',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        });
  }
}
