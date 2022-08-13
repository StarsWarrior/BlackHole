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

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/collage.dart';
import 'package:blackhole/CustomWidgets/horizontal_albumlist.dart';
import 'package:blackhole/CustomWidgets/like_button.dart';
import 'package:blackhole/CustomWidgets/on_hover.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Helpers/extensions.dart';
import 'package:blackhole/Helpers/format.dart';
import 'package:blackhole/Helpers/mediaitem_converter.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Library/liked.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Screens/Search/artists.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';

bool fetched = false;
List preferredLanguage = Hive.box('settings')
    .get('preferredLanguage', defaultValue: ['Hindi']) as List;
List likedRadio =
    Hive.box('settings').get('likedRadio', defaultValue: []) as List;
Map data = Hive.box('cache').get('homepage', defaultValue: {}) as Map;
List lists = ['recent', 'playlist', ...?data['collections']];

class SaavnHomePage extends StatefulWidget {
  @override
  _SaavnHomePageState createState() => _SaavnHomePageState();
}

class _SaavnHomePageState extends State<SaavnHomePage>
    with AutomaticKeepAliveClientMixin<SaavnHomePage> {
  List recentList =
      Hive.box('cache').get('recentSongs', defaultValue: []) as List;
  Map likedArtists =
      Hive.box('settings').get('likedArtists', defaultValue: {}) as Map;
  List blacklistedHomeSections = Hive.box('settings')
      .get('blacklistedHomeSections', defaultValue: []) as List;
  List playlistNames =
      Hive.box('settings').get('playlistNames')?.toList() as List? ??
          ['Favorite Songs'];
  Map playlistDetails =
      Hive.box('settings').get('playlistDetails', defaultValue: {}) as Map;
  int recentIndex = 0;
  int playlistIndex = 1;

  Future<void> getHomePageData() async {
    Map recievedData = await SaavnAPI().fetchHomePageData();
    if (recievedData.isNotEmpty) {
      Hive.box('cache').put('homepage', recievedData);
      data = recievedData;
      lists = ['recent', 'playlist', ...?data['collections']];
      lists.insert((lists.length / 2).round(), 'likedArtists');
    }
    setState(() {});
    recievedData = await FormatResponse.formatPromoLists(data);
    if (recievedData.isNotEmpty) {
      Hive.box('cache').put('homepage', recievedData);
      data = recievedData;
      lists = ['recent', 'playlist', ...?data['collections']];
      lists.insert((lists.length / 2).round(), 'likedArtists');
    }
    setState(() {});
  }

  String getSubTitle(Map item) {
    final type = item['type'];
    switch (type) {
      case 'charts':
        return '';
      case 'radio_station':
        return 'Radio • ${item['subtitle']?.toString().unescape()}';
      case 'playlist':
        return 'Playlist • ${item['subtitle']?.toString().unescape() ?? 'JioSaavn'}';
      case 'song':
        return 'Single • ${item['artist']?.toString().unescape()}';
      case 'album':
        final artists = item['more_info']?['artistMap']?['artists']
            .map((artist) => artist['name'])
            .toList();
        if (artists != null) {
          return 'Album • ${artists?.join(', ')?.toString().unescape()}';
        } else if (item['subtitle'] != null && item['subtitle'] != '') {
          return 'Album • ${item['subtitle']?.toString().unescape()}';
        }
        return 'Album';
      default:
        final artists = item['more_info']?['artistMap']?['artists']
            .map((artist) => artist['name'])
            .toList();
        return artists?.join(', ')?.toString().unescape() ?? '';
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!fetched) {
      getHomePageData();
      fetched = true;
    }
    double boxSize =
        MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
            ? MediaQuery.of(context).size.width / 2
            : MediaQuery.of(context).size.height / 2.5;
    if (boxSize > 250) boxSize = 250;
    if (recentList.length < playlistNames.length) {
      recentIndex = 0;
      playlistIndex = 1;
    } else {
      recentIndex = 1;
      playlistIndex = 0;
    }
    return (data.isEmpty && recentList.isEmpty)
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            itemCount: data.isEmpty ? 2 : lists.length,
            itemBuilder: (context, idx) {
              if (idx == recentIndex) {
                return (recentList.isEmpty ||
                        !(Hive.box('settings')
                            .get('showRecent', defaultValue: true) as bool))
                    ? const SizedBox()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 10, 0, 5),
                                child: Text(
                                  AppLocalizations.of(context)!.lastSession,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          HorizontalAlbumsList(
                            songsList: recentList,
                            onTap: (int idx) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) => PlayScreen(
                                    songsList: recentList,
                                    index: idx,
                                    offline: false,
                                    fromDownloads: false,
                                    fromMiniplayer: false,
                                    recommend: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
              }
              if (idx == playlistIndex) {
                return (playlistNames.isEmpty ||
                        !(Hive.box('settings')
                            .get('showPlaylist', defaultValue: true) as bool))
                    ? const SizedBox()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 10, 0, 5),
                                child: Text(
                                  AppLocalizations.of(context)!.yourPlaylists,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: boxSize + 15,
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              itemCount: playlistNames.length,
                              itemBuilder: (context, index) {
                                final String name =
                                    playlistNames[index].toString();
                                final String showName =
                                    playlistDetails.containsKey(name)
                                        ? playlistDetails[name]['name']
                                                ?.toString() ??
                                            name
                                        : name;
                                final String? subtitle = playlistDetails[
                                                name] ==
                                            null ||
                                        playlistDetails[name]['count'] ==
                                            null ||
                                        playlistDetails[name]['count'] == 0
                                    ? null
                                    : '${playlistDetails[name]['count']} ${AppLocalizations.of(context)!.songs}';
                                return GestureDetector(
                                  child: SizedBox(
                                    width: boxSize - 30,
                                    child: HoverBox(
                                      child: (playlistDetails[name] == null ||
                                              playlistDetails[name]
                                                      ['imagesList'] ==
                                                  null ||
                                              (playlistDetails[name]
                                                      ['imagesList'] as List)
                                                  .isEmpty)
                                          ? Card(
                                              elevation: 5,
                                              color: Colors.black,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  10.0,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: name == 'Favorite Songs'
                                                  ? const Image(
                                                      image: AssetImage(
                                                        'assets/cover.jpg',
                                                      ),
                                                    )
                                                  : const Image(
                                                      image: AssetImage(
                                                        'assets/album.png',
                                                      ),
                                                    ),
                                            )
                                          : Collage(
                                              borderRadius: 10.0,
                                              imageList: playlistDetails[name]
                                                  ['imagesList'] as List,
                                              showGrid: true,
                                              placeholderImage:
                                                  'assets/cover.jpg',
                                            ),
                                      builder: (
                                        BuildContext context,
                                        bool isHover,
                                        Widget? child,
                                      ) {
                                        return Card(
                                          color: isHover
                                              ? null
                                              : Colors.transparent,
                                          elevation: 0,
                                          margin: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10.0,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Column(
                                            children: [
                                              SizedBox.square(
                                                dimension: isHover
                                                    ? boxSize - 25
                                                    : boxSize - 30,
                                                child: child,
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10.0,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      showName,
                                                      textAlign:
                                                          TextAlign.center,
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    if (subtitle != null)
                                                      Text(
                                                        subtitle,
                                                        textAlign:
                                                            TextAlign.center,
                                                        softWrap: false,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .caption!
                                                                  .color,
                                                        ),
                                                      )
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  onTap: () async {
                                    await Hive.openBox(name);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LikedSongs(
                                          playlistName: name,
                                          showName: playlistDetails
                                                  .containsKey(name)
                                              ? playlistDetails[name]['name']
                                                      ?.toString() ??
                                                  name
                                              : name,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        ],
                      );
              }
              if (lists[idx] == 'likedArtists') {
                final List likedArtistsList = likedArtists.values.toList();
                return likedArtists.isEmpty
                    ? const SizedBox()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 10, 0, 5),
                                child: Text(
                                  'Liked Artists',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          HorizontalAlbumsList(
                            songsList: likedArtistsList,
                            onTap: (int idx) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  opaque: false,
                                  pageBuilder: (_, __, ___) => ArtistSearchPage(
                                    data: likedArtistsList[idx] as Map,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
              }
              return (data[lists[idx]] == null ||
                      blacklistedHomeSections.contains(
                        data['modules'][lists[idx]]?['title']
                            ?.toString()
                            .toLowerCase(),
                      ))
                  ? const SizedBox()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                          child: Text(
                            data['modules'][lists[idx]]?['title']
                                    ?.toString()
                                    .unescape() ??
                                '',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: boxSize + 15,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: data['modules'][lists[idx]]?['title']
                                        ?.toString() ==
                                    'Radio Stations'
                                ? (data[lists[idx]] as List).length +
                                    likedRadio.length
                                : (data[lists[idx]] as List).length,
                            itemBuilder: (context, index) {
                              Map item;
                              if (data['modules'][lists[idx]]?['title']
                                      ?.toString() ==
                                  'Radio Stations') {
                                index < likedRadio.length
                                    ? item = likedRadio[index] as Map
                                    : item = data[lists[idx]]
                                        [index - likedRadio.length] as Map;
                              } else {
                                item = data[lists[idx]][index] as Map;
                              }
                              final currentSongList = data[lists[idx]]
                                  .where((e) => e['type'] == 'song')
                                  .toList();
                              final subTitle = getSubTitle(item);
                              if (item.isEmpty) return const SizedBox();
                              return GestureDetector(
                                onLongPress: () {
                                  Feedback.forLongPress(context);
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return InteractiveViewer(
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  Navigator.pop(context),
                                            ),
                                            AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                              ),
                                              backgroundColor:
                                                  Colors.transparent,
                                              contentPadding: EdgeInsets.zero,
                                              content: Card(
                                                elevation: 5,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    item['type'] ==
                                                            'radio_station'
                                                        ? 1000.0
                                                        : 15.0,
                                                  ),
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: CachedNetworkImage(
                                                  fit: BoxFit.cover,
                                                  errorWidget:
                                                      (context, _, __) =>
                                                          const Image(
                                                    fit: BoxFit.cover,
                                                    image: AssetImage(
                                                      'assets/cover.jpg',
                                                    ),
                                                  ),
                                                  imageUrl: item['image']
                                                      .toString()
                                                      .replaceAll(
                                                        'http:',
                                                        'https:',
                                                      )
                                                      .replaceAll(
                                                        '50x50',
                                                        '500x500',
                                                      )
                                                      .replaceAll(
                                                        '150x150',
                                                        '500x500',
                                                      ),
                                                  placeholder: (context, url) =>
                                                      Image(
                                                    fit: BoxFit.cover,
                                                    image: (item['type'] ==
                                                                'playlist' ||
                                                            item['type'] ==
                                                                'album')
                                                        ? const AssetImage(
                                                            'assets/album.png',
                                                          )
                                                        : item['type'] ==
                                                                'artist'
                                                            ? const AssetImage(
                                                                'assets/artist.png',
                                                              )
                                                            : const AssetImage(
                                                                'assets/cover.jpg',
                                                              ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                onTap: () {
                                  if (item['type'] == 'radio_station') {
                                    ShowSnackBar().showSnackBar(
                                      context,
                                      AppLocalizations.of(context)!
                                          .connectingRadio,
                                      duration: const Duration(seconds: 2),
                                    );
                                    SaavnAPI()
                                        .createRadio(
                                      names: item['more_info']
                                                      ['featured_station_type']
                                                  .toString() ==
                                              'artist'
                                          ? [
                                              item['more_info']['query']
                                                  .toString()
                                            ]
                                          : [item['id'].toString()],
                                      language: item['more_info']['language']
                                              ?.toString() ??
                                          'hindi',
                                      stationType: item['more_info']
                                              ['featured_station_type']
                                          .toString(),
                                    )
                                        .then((value) {
                                      if (value != null) {
                                        SaavnAPI()
                                            .getRadioSongs(stationId: value)
                                            .then((value) {
                                          value.shuffle();
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              opaque: false,
                                              pageBuilder: (_, __, ___) =>
                                                  PlayScreen(
                                                songsList: value,
                                                index: 0,
                                                offline: false,
                                                fromDownloads: false,
                                                fromMiniplayer: false,
                                                recommend: true,
                                              ),
                                            ),
                                          );
                                        });
                                      }
                                    });
                                  } else {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        opaque: false,
                                        pageBuilder: (_, __, ___) =>
                                            item['type'] == 'song'
                                                ? PlayScreen(
                                                    songsList:
                                                        currentSongList as List,
                                                    index: currentSongList
                                                        .indexWhere(
                                                      (e) =>
                                                          e['id'] == item['id'],
                                                    ),
                                                    offline: false,
                                                    fromDownloads: false,
                                                    fromMiniplayer: false,
                                                    recommend: true,
                                                  )
                                                : SongsListPage(
                                                    listItem: item,
                                                  ),
                                      ),
                                    );
                                  }
                                },
                                child: SizedBox(
                                  width: boxSize - 30,
                                  child: HoverBox(
                                    child: Card(
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          item['type'] == 'radio_station'
                                              ? 1000.0
                                              : 10.0,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        fit: BoxFit.cover,
                                        errorWidget: (context, _, __) =>
                                            const Image(
                                          fit: BoxFit.cover,
                                          image: AssetImage(
                                            'assets/cover.jpg',
                                          ),
                                        ),
                                        imageUrl: item['image']
                                            .toString()
                                            .replaceAll(
                                              'http:',
                                              'https:',
                                            )
                                            .replaceAll(
                                              '50x50',
                                              '500x500',
                                            )
                                            .replaceAll(
                                              '150x150',
                                              '500x500',
                                            ),
                                        placeholder: (context, url) => Image(
                                          fit: BoxFit.cover,
                                          image: (item['type'] == 'playlist' ||
                                                  item['type'] == 'album')
                                              ? const AssetImage(
                                                  'assets/album.png',
                                                )
                                              : item['type'] == 'artist'
                                                  ? const AssetImage(
                                                      'assets/artist.png',
                                                    )
                                                  : const AssetImage(
                                                      'assets/cover.jpg',
                                                    ),
                                        ),
                                      ),
                                    ),
                                    builder: (
                                      BuildContext context,
                                      bool isHover,
                                      Widget? child,
                                    ) {
                                      return Card(
                                        color:
                                            isHover ? null : Colors.transparent,
                                        elevation: 0,
                                        margin: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          children: [
                                            Stack(
                                              children: [
                                                SizedBox.square(
                                                  dimension: isHover
                                                      ? boxSize - 25
                                                      : boxSize - 30,
                                                  child: child,
                                                ),
                                                if (isHover &&
                                                    (item['type'] == 'song' ||
                                                        item['type'] ==
                                                            'radio_station'))
                                                  Positioned.fill(
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                        4.0,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black54,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          item['type'] ==
                                                                  'radio_station'
                                                              ? 1000.0
                                                              : 10.0,
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: DecoratedBox(
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                Colors.black87,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              1000.0,
                                                            ),
                                                          ),
                                                          child: const Icon(
                                                            Icons
                                                                .play_arrow_rounded,
                                                            size: 50.0,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (item['type'] ==
                                                        'radio_station' &&
                                                    (Platform.isAndroid ||
                                                        Platform.isIOS ||
                                                        isHover))
                                                  Align(
                                                    alignment:
                                                        Alignment.topRight,
                                                    child: IconButton(
                                                      icon: likedRadio
                                                              .contains(item)
                                                          ? const Icon(
                                                              Icons
                                                                  .favorite_rounded,
                                                              color: Colors.red,
                                                            )
                                                          : const Icon(
                                                              Icons
                                                                  .favorite_border_rounded,
                                                            ),
                                                      tooltip: likedRadio
                                                              .contains(item)
                                                          ? AppLocalizations.of(
                                                              context,
                                                            )!
                                                              .unlike
                                                          : AppLocalizations.of(
                                                              context,
                                                            )!
                                                              .like,
                                                      onPressed: () {
                                                        likedRadio
                                                                .contains(item)
                                                            ? likedRadio
                                                                .remove(item)
                                                            : likedRadio
                                                                .add(item);
                                                        Hive.box('settings')
                                                            .put(
                                                          'likedRadio',
                                                          likedRadio,
                                                        );
                                                        setState(() {});
                                                      },
                                                    ),
                                                  ),
                                                if (item['type'] == 'song' ||
                                                    item['duration'] != null)
                                                  Align(
                                                    alignment:
                                                        Alignment.topRight,
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (isHover)
                                                          LikeButton(
                                                            mediaItem:
                                                                MediaItemConverter
                                                                    .mapToMediaItem(
                                                              item,
                                                            ),
                                                          ),
                                                        SongTileTrailingMenu(
                                                          data: item,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10.0,
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    item['title']
                                                            ?.toString()
                                                            .unescape() ??
                                                        '',
                                                    textAlign: TextAlign.center,
                                                    softWrap: false,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  if (subTitle != '')
                                                    Text(
                                                      subTitle,
                                                      textAlign:
                                                          TextAlign.center,
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .caption!
                                                            .color,
                                                      ),
                                                    )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
            },
          );
  }
}
