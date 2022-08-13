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

import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/search_bar.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/CustomWidgets/song_tile_trailing_menu.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeSearchPage extends StatefulWidget {
  final String query;
  const YouTubeSearchPage({super.key, required this.query});
  @override
  _YouTubeSearchPageState createState() => _YouTubeSearchPageState();
}

class _YouTubeSearchPageState extends State<YouTubeSearchPage> {
  String query = '';
  bool status = false;
  List<Video> searchedList = [];
  bool fetched = false;
  bool done = true;
  bool liveSearch =
      Hive.box('settings').get('liveSearch', defaultValue: true) as bool;
  // List ytSearch =
  // Hive.box('settings').get('ytSearch', defaultValue: []) as List;
  // bool showHistory =
  // Hive.box('settings').get('showHistory', defaultValue: true) as bool;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.query;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool rotated =
        MediaQuery.of(context).size.height < MediaQuery.of(context).size.width;
    double boxSize = !rotated
        ? MediaQuery.of(context).size.width / 2
        : MediaQuery.of(context).size.height / 2.5;
    if (boxSize > 250) boxSize = 250;
    if (!status) {
      status = true;
      YouTubeServices()
          .fetchSearchResults(query == '' ? widget.query : query)
          .then((value) {
        setState(() {
          searchedList = value;
          fetched = true;
        });
      });
    }
    return GradientContainer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: Colors.transparent,
                body: SearchBar(
                  isYt: true,
                  controller: _controller,
                  liveSearch: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  hintText: AppLocalizations.of(context)!.searchYt,
                  onQueryChanged: (changedQuery) {
                    return YouTubeServices()
                        .getSearchSuggestions(query: changedQuery);
                  },
                  onSubmitted: (submittedQuery) async {
                    setState(() {
                      fetched = false;
                      query = submittedQuery;
                      _controller.text = submittedQuery;
                      status = false;
                      searchedList = [];
                    });
                  },
                  body: (!fetched)
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : searchedList.isEmpty
                          ? emptyScreen(
                              context,
                              0,
                              ':( ',
                              100,
                              AppLocalizations.of(
                                context,
                              )!
                                  .sorry,
                              60,
                              AppLocalizations.of(
                                context,
                              )!
                                  .resultsNotFound,
                              20,
                            )
                          : Stack(
                              children: [
                                ListView.builder(
                                  itemCount: searchedList.length,
                                  physics: const BouncingScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.fromLTRB(
                                    15,
                                    80,
                                    15,
                                    0,
                                  ),
                                  itemBuilder: (context, index) {
                                    final Widget thumbnailWidget = Card(
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.0,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        children: [
                                          CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            height: !rotated
                                                ? null
                                                : boxSize / 1.25,
                                            width: !rotated
                                                ? null
                                                : (boxSize / 1.25) * 16 / 9,
                                            errorWidget: (context, _, __) =>
                                                Image(
                                              fit: BoxFit.cover,
                                              image: NetworkImage(
                                                searchedList[index]
                                                    .thumbnails
                                                    .standardResUrl,
                                              ),
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) =>
                                                  const Image(
                                                fit: BoxFit.cover,
                                                image: AssetImage(
                                                  'assets/ytCover.png',
                                                ),
                                              ),
                                            ),
                                            imageUrl: searchedList[index]
                                                .thumbnails
                                                .maxResUrl,
                                            placeholder: (context, url) =>
                                                const Image(
                                              fit: BoxFit.cover,
                                              image: AssetImage(
                                                'assets/ytCover.png',
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Card(
                                              elevation: 0.0,
                                              color: Colors.black54,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  6.0,
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4.5),
                                                child: Text(
                                                  searchedList[index]
                                                              .duration
                                                              .toString() ==
                                                          'null'
                                                      ? AppLocalizations.of(
                                                          context,
                                                        )!
                                                          .live
                                                      : searchedList[index]
                                                          .duration
                                                          .toString()
                                                          .split(
                                                            '.',
                                                          )[0]
                                                          .replaceFirst(
                                                            '0:0',
                                                            '',
                                                          ),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            done = false;
                                          });
                                          final Map? response =
                                              await YouTubeServices()
                                                  .formatVideo(
                                            video: searchedList[index],
                                            quality: Hive.box('settings')
                                                .get(
                                                  'ytQuality',
                                                  defaultValue: 'Low',
                                                )
                                                .toString(),
                                            // preferM4a: Hive.box(
                                            //         'settings')
                                            //     .get('preferM4a',
                                            //         defaultValue:
                                            //             true) as bool
                                          );
                                          setState(() {
                                            done = true;
                                          });
                                          response == null
                                              ? ShowSnackBar().showSnackBar(
                                                  context,
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .ytLiveAlert,
                                                )
                                              : Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    pageBuilder: (_, __, ___) =>
                                                        PlayScreen(
                                                      fromMiniplayer: false,
                                                      songsList: [response],
                                                      index: 0,
                                                      offline: false,
                                                      fromDownloads: false,
                                                      recommend: false,
                                                    ),
                                                  ),
                                                );
                                        },
                                        child: rotated
                                            ? Row(
                                                children: [
                                                  thumbnailWidget,
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            ((boxSize / 1.25) *
                                                                16 /
                                                                9) -
                                                            50,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                        15.0,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            searchedList[index]
                                                                .title,
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontSize: 22,
                                                            ),
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              SizedBox(
                                                                width: MediaQuery
                                                                            .of(
                                                                      context,
                                                                    )
                                                                        .size
                                                                        .width -
                                                                    ((boxSize /
                                                                            1.25) *
                                                                        16 /
                                                                        9) -
                                                                    150,
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    const SizedBox(
                                                                      height:
                                                                          5.0,
                                                                    ),
                                                                    Text(
                                                                      '${searchedList[index].author} • ${searchedList[index].engagement.viewCount} Views',
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style:
                                                                          TextStyle(
                                                                        color: Theme
                                                                                .of(
                                                                          context,
                                                                        )
                                                                            .textTheme
                                                                            .caption!
                                                                            .color,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          10.0,
                                                                    ),
                                                                    Text(
                                                                      searchedList[
                                                                              index]
                                                                          .description,
                                                                      maxLines:
                                                                          2,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style:
                                                                          TextStyle(
                                                                        color: Theme
                                                                                .of(
                                                                          context,
                                                                        )
                                                                            .textTheme
                                                                            .caption!
                                                                            .color,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              YtSongTileTrailingMenu(
                                                                data:
                                                                    searchedList[
                                                                        index],
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Card(
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    10.0,
                                                  ),
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: GradientContainer(
                                                  child: Column(
                                                    children: [
                                                      thumbnailWidget,
                                                      ListTile(
                                                        dense: true,
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .only(
                                                          left: 15.0,
                                                        ),
                                                        title: Text(
                                                          searchedList[index]
                                                              .title,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        // isThreeLine: true,
                                                        subtitle: Text(
                                                          searchedList[index]
                                                              .author,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          // '${searchedList[index]["channelName"]}'
                                                        ),
                                                        // leading: CircleAvatar(
                                                        //   maxRadius: 20,
                                                        //   backgroundImage: AssetImage(
                                                        //       'assets/artist.png'),
                                                        //   foregroundImage:
                                                        //       CachedNetworkImageProvider(
                                                        //           'https://yt3.ggpht.com/ytc/AKedOLS47SGZoq9qhTlM6ANNiXN5I3sUcV4_owFydPkU=s68-c-k-c0x00ffffff-no-rj'
                                                        //           // 'https://yt3.ggpht.com/ytc/${searchedList[index].channelId.value}'

                                                        //           // ["channelImage"],
                                                        //           ),
                                                        // ),
                                                        trailing:
                                                            YtSongTileTrailingMenu(
                                                          data: searchedList[
                                                              index],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                                if (!done)
                                  Center(
                                    child: SizedBox.square(
                                      dimension: boxSize,
                                      child: Card(
                                        elevation: 10,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: GradientContainer(
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                  ),
                                                  strokeWidth: 5,
                                                ),
                                                Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .fetchingStream,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                ),
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }
}
