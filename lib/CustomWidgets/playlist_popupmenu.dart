import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Helpers/playlist.dart';
import 'package:blackhole/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlaylistPopupMenu extends StatefulWidget {
  final List data;
  final String title;
  const PlaylistPopupMenu({
    Key? key,
    required this.data,
    required this.title,
  }) : super(key: key);

  @override
  _PlaylistPopupMenuState createState() => _PlaylistPopupMenuState();
}

class _PlaylistPopupMenuState extends State<PlaylistPopupMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(
        Icons.more_vert_rounded,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
      ),
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
              Text(AppLocalizations.of(context)!.addToQueue),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.favorite_border_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10.0),
              Text(AppLocalizations.of(context)!.savePlaylist),
            ],
          ),
        ),
      ],
      onSelected: (int? value) {
        if (value == 1) {
          addPlaylist(widget.title, widget.data).then(
            (value) => ShowSnackBar().showSnackBar(
              context,
              '"${widget.title}" ${AppLocalizations.of(context)!.addedToPlaylists}',
            ),
          );
        }
        if (value == 0) {
          final MediaItem? currentMediaItem = audioHandler.mediaItem.value;
          if (currentMediaItem != null &&
              currentMediaItem.extras!['url'].toString().startsWith('http')) {
            // TODO: make sure to check if song is already in queue
            final queue = audioHandler.queue.value;
            widget.data.map((e) {
              final element = MediaItemConverter.mapToMediaItem(e as Map);
              if (!queue.contains(element)) {
                audioHandler.addQueueItem(element);
              }
            });

            ShowSnackBar().showSnackBar(
              context,
              '"${widget.title}" ${AppLocalizations.of(context)!.addedToQueue}',
            );
          } else {
            ShowSnackBar().showSnackBar(
              context,
              currentMediaItem == null
                  ? AppLocalizations.of(context)!.nothingPlaying
                  : AppLocalizations.of(context)!.cantAddToQueue,
            );
          }
        }
      },
    );
  }
}
