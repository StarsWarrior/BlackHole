/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2022, Ankit Sangwan
 */

import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/playlist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LikeButton extends StatefulWidget {
  final MediaItem? mediaItem;
  final double? size;
  final Map? data;
  final bool showSnack;
  const LikeButton({
    Key? key,
    required this.mediaItem,
    this.size,
    this.data,
    this.showSnack = false,
  }) : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  bool liked = false;
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _curve;

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
    try {
      if (widget.mediaItem != null) {
        liked = checkPlaylist('Favorite Songs', widget.mediaItem!.id);
      } else {
        liked = checkPlaylist('Favorite Songs', widget.data!['id'].toString());
      }
    } catch (e) {
      // print('Error: $e');
    }
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
          liked
              ? removeLiked(
                  widget.mediaItem == null
                      ? widget.data!['id'].toString()
                      : widget.mediaItem!.id,
                )
              : widget.mediaItem == null
                  ? addMapToPlaylist('Favorite Songs', widget.data!)
                  : addItemToPlaylist('Favorite Songs', widget.mediaItem!);

          if (!liked) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
          setState(() {
            liked = !liked;
          });
          if (widget.showSnack) {
            ShowSnackBar().showSnackBar(
              context,
              liked
                  ? AppLocalizations.of(context)!.addedToFav
                  : AppLocalizations.of(context)!.removedFromFav,
              action: SnackBarAction(
                textColor: Theme.of(context).colorScheme.secondary,
                label: AppLocalizations.of(context)!.undo,
                onPressed: () {
                  liked
                      ? removeLiked(
                          widget.mediaItem == null
                              ? widget.data!['id'].toString()
                              : widget.mediaItem!.id,
                        )
                      : widget.mediaItem == null
                          ? addMapToPlaylist('Favorite Songs', widget.data!)
                          : addItemToPlaylist(
                              'Favorite Songs',
                              widget.mediaItem!,
                            );

                  liked = !liked;
                  setState(() {});
                },
              ),
            );
          }
        },
      ),
    );
  }
}
