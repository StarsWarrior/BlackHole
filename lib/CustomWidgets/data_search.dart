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

import 'dart:io';

import 'package:blackhole/Helpers/audio_query.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:on_audio_query/on_audio_query.dart';

class DataSearch extends SearchDelegate {
  final List<SongModel> data;
  final String tempPath;

  DataSearch({required this.data, required this.tempPath}) : super();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isEmpty)
        IconButton(
          icon: const Icon(CupertinoIcons.search),
          tooltip: AppLocalizations.of(context)!.search,
          onPressed: () {},
        )
      else
        IconButton(
          onPressed: () {
            query = '';
          },
          tooltip: AppLocalizations.of(context)!.clear,
          icon: const Icon(
            Icons.clear_rounded,
          ),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: AppLocalizations.of(context)!.back,
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? data
        : [
            ...{
              ...data
                  .where(
                    (element) => element.title
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .toList(),
              ...data
                  .where(
                    (element) => element.artist!
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .toList(),
            }
          ];
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      shrinkWrap: true,
      itemExtent: 70.0,
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => ListTile(
        leading: OfflineAudioQuery.offlineArtworkWidget(
          id: suggestionList[index].id,
          type: ArtworkType.AUDIO,
          tempPath: tempPath,
          fileName: suggestionList[index].displayNameWOExt,
        ),
        title: Text(
          suggestionList[index].title.trim() != ''
              ? suggestionList[index].title
              : suggestionList[index].displayNameWOExt,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          suggestionList[index].artist! == '<unknown>'
              ? AppLocalizations.of(context)!.unknown
              : suggestionList[index].artist!,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () async {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => PlayScreen(
                songsList: suggestionList,
                index: index,
                offline: true,
                fromMiniplayer: false,
                fromDownloads: false,
                recommend: false,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final suggestionList = query.isEmpty
        ? data
        : [
            ...{
              ...data
                  .where(
                    (element) => element.title
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .toList(),
              ...data
                  .where(
                    (element) => element.artist!
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .toList(),
            }
          ];
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      shrinkWrap: true,
      itemExtent: 70.0,
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => ListTile(
        leading: OfflineAudioQuery.offlineArtworkWidget(
          id: suggestionList[index].id,
          type: ArtworkType.AUDIO,
          tempPath: tempPath,
          fileName: suggestionList[index].displayNameWOExt,
        ),
        title: Text(
          suggestionList[index].title.trim() != ''
              ? suggestionList[index].title
              : suggestionList[index].displayNameWOExt,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          suggestionList[index].artist! == '<unknown>'
              ? AppLocalizations.of(context)!.unknown
              : suggestionList[index].artist!,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () async {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => PlayScreen(
                songsList: suggestionList,
                index: index,
                offline: true,
                fromMiniplayer: false,
                fromDownloads: false,
                recommend: false,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      primaryColor: Theme.of(context).colorScheme.secondary,
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: Colors.white),
      hintColor: Colors.white70,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.white),
      textTheme: theme.textTheme.copyWith(
        headline6:
            const TextStyle(fontWeight: FontWeight.normal, color: Colors.white),
      ),
      inputDecorationTheme:
          const InputDecorationTheme(focusedBorder: InputBorder.none),
    );
  }
}

class DownloadsSearch extends SearchDelegate {
  final bool isDowns;
  final List data;

  DownloadsSearch({required this.data, this.isDowns = false});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isEmpty)
        IconButton(
          icon: const Icon(CupertinoIcons.search),
          tooltip: AppLocalizations.of(context)!.search,
          onPressed: () {},
        )
      else
        IconButton(
          onPressed: () {
            query = '';
          },
          tooltip: AppLocalizations.of(context)!.clear,
          icon: const Icon(
            Icons.clear_rounded,
          ),
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: AppLocalizations.of(context)!.back,
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? data
        : [
            ...{
              ...data
                  .where(
                    (element) => element['title']
                        .toString()
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .toList(),
              ...data
                  .where(
                    (element) => element['artist']
                        .toString()
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .toList(),
            }
          ];
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      shrinkWrap: true,
      itemExtent: 70.0,
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => ListTile(
        leading: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox.square(
            dimension: 50,
            child: isDowns
                ? Image(
                    fit: BoxFit.cover,
                    image: FileImage(
                      File(suggestionList[index]['image'].toString()),
                    ),
                    errorBuilder: (_, __, ___) =>
                        Image.asset('assets/cover.jpg'),
                  )
                : CachedNetworkImage(
                    fit: BoxFit.cover,
                    errorWidget: (context, _, __) => const Image(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/cover.jpg'),
                    ),
                    imageUrl: suggestionList[index]['image']
                        .toString()
                        .replaceAll('http:', 'https:'),
                    placeholder: (context, url) => const Image(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/cover.jpg'),
                    ),
                  ),
          ),
        ),
        title: Text(
          suggestionList[index]['title'].toString(),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          suggestionList[index]['artist'].toString(),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => PlayScreen(
                songsList: suggestionList,
                index: index,
                offline: isDowns,
                fromMiniplayer: false,
                fromDownloads: isDowns,
                recommend: false,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final suggestionList = query.isEmpty
        ? data
        : [
            ...{
              ...data
                  .where(
                    (element) => element['title']
                        .toString()
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .toList(),
              ...data
                  .where(
                    (element) => element['artist']
                        .toString()
                        .toLowerCase()
                        .contains(query.toLowerCase()),
                  )
                  .toList(),
            }
          ];
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      shrinkWrap: true,
      itemExtent: 70.0,
      itemCount: suggestionList.length,
      itemBuilder: (context, index) => ListTile(
        leading: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox.square(
            dimension: 50,
            child: isDowns
                ? Image(
                    fit: BoxFit.cover,
                    image: FileImage(
                      File(suggestionList[index]['image'].toString()),
                    ),
                    errorBuilder: (_, __, ___) =>
                        Image.asset('assets/cover.jpg'),
                  )
                : CachedNetworkImage(
                    fit: BoxFit.cover,
                    errorWidget: (context, _, __) => const Image(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/cover.jpg'),
                    ),
                    imageUrl: suggestionList[index]['image']
                        .toString()
                        .replaceAll('http:', 'https:'),
                    placeholder: (context, url) => const Image(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/cover.jpg'),
                    ),
                  ),
          ),
        ),
        title: Text(
          suggestionList[index]['title'].toString(),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          suggestionList[index]['artist'].toString(),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => PlayScreen(
                songsList: suggestionList,
                index: index,
                offline: isDowns,
                fromMiniplayer: false,
                fromDownloads: isDowns,
                recommend: false,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.copyWith(
      primaryColor: Theme.of(context).colorScheme.secondary,
      textSelectionTheme:
          const TextSelectionThemeData(cursorColor: Colors.white),
      hintColor: Colors.white70,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.white),
      textTheme: theme.textTheme.copyWith(
        headline6:
            const TextStyle(fontWeight: FontWeight.normal, color: Colors.white),
      ),
      inputDecorationTheme:
          const InputDecorationTheme(focusedBorder: InputBorder.none),
    );
  }
}
