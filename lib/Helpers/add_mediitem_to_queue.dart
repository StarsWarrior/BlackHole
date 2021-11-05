import 'package:audio_service/audio_service.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddToQueue {
  void addToNowPlaying(MediaItem mediaItem, BuildContext context) {
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

  void playNext(MediaItem mediaItem, BuildContext context) {
    final MediaItem? currentMediaItem = audioHandler.mediaItem.value;
    if (currentMediaItem != null &&
        currentMediaItem.extras!['url'].toString().startsWith('http')) {
      final queue = audioHandler.queue.value;
      if (queue.contains(mediaItem)) {
        audioHandler.moveQueueItem(
          queue.indexOf(mediaItem),
          queue.indexOf(currentMediaItem) + 1,
        );
      } else {
        audioHandler.addQueueItem(mediaItem).then(
              (value) => audioHandler.moveQueueItem(
                queue.length,
                queue.indexOf(currentMediaItem) + 1,
              ),
            );
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
            : AppLocalizations.of(context)!.cantAddToQueue,
      );
    }
  }
}
