import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

class ArtistLikeButton extends StatefulWidget {
  final double? size;
  final Map data;
  final bool showSnack;
  const ArtistLikeButton({
    Key? key,
    this.size,
    required this.data,
    this.showSnack = false,
  }) : super(key: key);

  @override
  _ArtistLikeButtonState createState() => _ArtistLikeButtonState();
}

class _ArtistLikeButtonState extends State<ArtistLikeButton>
    with SingleTickerProviderStateMixin {
  bool liked = false;
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _curve;
  Map likedArtists =
      Hive.box('settings').get('likedArtists', defaultValue: {}) as Map;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _curve = CurvedAnimation(parent: _controller, curve: Curves.slowMiddle);

    _scale = TweenSequence(<TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(_curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    liked = likedArtists.containsKey(widget.data['id'].toString());
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        icon: Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: liked ? Colors.redAccent : Theme.of(context).iconTheme.color,
        ),
        iconSize: widget.size ?? 24.0,
        tooltip: liked
            ? AppLocalizations.of(context)!.unlike
            : AppLocalizations.of(context)!.like,
        onPressed: () async {
          if (!liked) {
            _controller.forward();
            likedArtists.addEntries(
              [MapEntry(widget.data['id'].toString(), widget.data)],
            );
          } else {
            _controller.reverse();
            likedArtists.remove(widget.data['id'].toString());
          }
          Hive.box('settings').put('likedArtists', likedArtists);
          setState(() {
            liked = !liked;
          });
          if (widget.showSnack) {
            ShowSnackBar().showSnackBar(
              context,
              liked
                  ? AppLocalizations.of(context)!.addedToFav
                  : AppLocalizations.of(context)!.removedFromFav,
            );
          }
        },
      ),
    );
  }
}
