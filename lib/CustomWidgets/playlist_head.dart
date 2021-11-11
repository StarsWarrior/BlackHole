import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlaylistHead extends StatelessWidget {
  final List songsList;
  final bool offline;
  final bool fromDownloads;
  final bool recommend;
  const PlaylistHead({
    Key? key,
    required this.songsList,
    required this.fromDownloads,
    required this.recommend,
    required this.offline,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(left: 20.0, right: 10.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${songsList.length} Songs',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              final tempList = songsList.toList();
              tempList.shuffle();
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => PlayScreen(
                    songsList: tempList,
                    index: 0,
                    offline: offline,
                    fromMiniplayer: false,
                    fromDownloads: fromDownloads,
                    recommend: recommend,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.shuffle_rounded),
            label: Text(
              AppLocalizations.of(context)!.shuffle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => PlayScreen(
                    songsList: songsList,
                    index: 0,
                    offline: offline,
                    fromMiniplayer: false,
                    fromDownloads: fromDownloads,
                    recommend: recommend,
                  ),
                ),
              );
            },
            tooltip: AppLocalizations.of(context)!.shuffle,
            icon: const Icon(Icons.play_arrow_rounded),
            iconSize: 30.0,
          ),
        ],
      ),
    );
  }
}
