import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/add_playlist.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
                      Text(AppLocalizations.of(context)!.playNext),
                    ],
                  )),
              PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(
                        Icons.playlist_add_rounded,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      const SizedBox(width: 10.0),
                      Text(AppLocalizations.of(context)!.addToQueue),
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
                      Text(AppLocalizations.of(context)!.addToPlaylist),
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
                      Text(AppLocalizations.of(context)!.share),
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
            final MediaItem? currentMediaItem = audioHandler.mediaItem.value;
            if (currentMediaItem != null &&
                currentMediaItem.extras!['url'].toString().startsWith('http')) {
              if (audioHandler.queue.value.contains(mediaItem)) {
                ShowSnackBar().showSnackBar(
                  context,
                  AppLocalizations.of(context)!.alreadyInQueue,
                );
              } else {
                audioHandler.addQueueItem(mediaItem);

                ShowSnackBar().showSnackBar(
                  context,
                  AppLocalizations.of(context)!.addedToQueue,
                );
              }
            } else {
              ShowSnackBar().showSnackBar(
                context,
                currentMediaItem == null
                    ? AppLocalizations.of(context)!.nothingPlaying
                    : AppLocalizations.of(context)!.cantAddToQueue,
              );
            }
          }

          if (value == 2) {
            final MediaItem? currentMediaItem = audioHandler.mediaItem.value;
            if (currentMediaItem != null &&
                currentMediaItem.extras!['url'].toString().startsWith('http')) {
              final queue = audioHandler.queue.value;
              if (queue.contains(mediaItem)) {
                audioHandler.moveQueueItem(queue.indexOf(mediaItem),
                    queue.indexOf(currentMediaItem) + 1);
              } else {
                audioHandler.addQueueItem(mediaItem).then((value) =>
                    audioHandler.moveQueueItem(
                        queue.length, queue.indexOf(currentMediaItem) + 1));
              }

              ShowSnackBar().showSnackBar(
                context,
                '"${mediaItem.title}" ${AppLocalizations.of(context)!.willPlayNext}',
              );
            } else {
              ShowSnackBar().showSnackBar(
                  context,
                  currentMediaItem == null
                      ? AppLocalizations.of(context)!.nothingPlaying
                      : AppLocalizations.of(context)!.cantAddToQueue);
            }
          }
        });
  }
}
