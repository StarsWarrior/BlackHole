import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/Helpers/format.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';

bool fetched = false;
List preferredLanguage = Hive.box('settings')
    .get('preferredLanguage', defaultValue: ['Hindi']) as List;
Map data = Hive.box('cache').get('homepage', defaultValue: {}) as Map;
List lists = ['recent', ...?data['collections']];

class SaavnHomePage extends StatefulWidget {
  @override
  _SaavnHomePageState createState() => _SaavnHomePageState();
}

class _SaavnHomePageState extends State<SaavnHomePage> {
  List recentList =
      Hive.box('recentlyPlayed').get('recentSongs', defaultValue: []) as List;

  Future<void> getHomePageData() async {
    Map recievedData = await SaavnAPI().fetchHomePageData();
    if (recievedData.isNotEmpty) {
      Hive.box('cache').put('homepage', recievedData);
      data = recievedData;
      lists = ['recent', ...?data['collections']];
    }
    setState(() {});
    recievedData = await FormatResponse().formatPromoLists(data);
    if (recievedData.isNotEmpty) {
      Hive.box('cache').put('homepage', recievedData);
      data = recievedData;
      lists = ['recent', ...?data['collections']];
    }
    setState(() {});
  }

  String getSubTitle(Map item) {
    final type = item['type'];
    if (type == 'charts') {
      return '';
    } else if (type == 'playlist') {
      return formatString(item['subtitle']?.toString());
    } else if (type == 'radio_station') {
      return formatString(item['subtitle']?.toString());
    } else if (type == 'song') {
      return formatString(item['artist']?.toString());
    } else {
      final artists = item['more_info']['artistMap']?['artists']
          .map((artist) => artist['name'])
          .toList();
      return formatString(artists?.join(', ')?.toString());
    }
  }

  String formatString(String? text) {
    return text == null
        ? ''
        : text
            .toString()
            .replaceAll('&amp;', '&')
            .replaceAll('&#039;', "'")
            .replaceAll('&quot;', '"')
            .trim();
  }

  @override
  Widget build(BuildContext context) {
    if (!fetched) {
      getHomePageData();
      fetched = true;
    }
    return ListView.builder(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        itemCount: data.isEmpty ? 1 : lists.length,
        itemBuilder: (context, idx) {
          if (idx == 0) {
            return (recentList.isEmpty ||
                    !(Hive.box('settings').get('showRecent', defaultValue: true)
                        as bool))
                ? const SizedBox()
                : Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                            child: Text(
                              'Last Session',
                              style: TextStyle(
                                color: Theme.of(context).accentColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 4 + 10,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          itemCount: recentList.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    opaque: false,
                                    pageBuilder: (_, __, ___) => PlayScreen(
                                      data: {
                                        'response': recentList,
                                        'index': index,
                                        'offline': false,
                                      },
                                      fromMiniplayer: false,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width:
                                    MediaQuery.of(context).size.height / 4 - 30,
                                child: Column(
                                  children: [
                                    Card(
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: CachedNetworkImage(
                                        errorWidget: (context, _, __) =>
                                            const Image(
                                          image: AssetImage('assets/cover.jpg'),
                                        ),
                                        imageUrl: recentList[index]['image']
                                            .toString()
                                            .replaceAll('http:', 'https:')
                                            .replaceAll('50x50', '500x500')
                                            .replaceAll('150x150', '500x500'),
                                        placeholder: (context, url) =>
                                            const Image(
                                          image: AssetImage('assets/cover.jpg'),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${recentList[index]["title"]}',
                                      textAlign: TextAlign.center,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${recentList[index]["artist"]}',
                                      textAlign: TextAlign.center,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .textTheme
                                              .caption!
                                              .color),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
          }
          return Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 10, 0, 5),
                    child: Text(
                      formatString(
                          data['modules'][lists[idx]]?['title']?.toString()),
                      style: TextStyle(
                        color: Theme.of(context).accentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (data[lists[idx]] == null)
                const SizedBox()
              else
                SizedBox(
                  height: MediaQuery.of(context).size.height / 4 + 5,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    itemCount: (data[lists[idx]] as List).length,
                    itemBuilder: (context, index) {
                      final Map item = data[lists[idx]][index] as Map;
                      final currentSongList = data[lists[idx]]
                          .where((e) => e['type'] == 'song')
                          .toList();
                      final subTitle = getSubTitle(item);
                      return GestureDetector(
                        onTap: () {
                          if (item['type'] == 'radio_station') {
                            ShowSnackBar().showSnackBar(
                              context,
                              'Connecting to Radio...',
                              duration: const Duration(seconds: 2),
                            );
                            SaavnAPI()
                                .createRadio(
                              item['more_info']['featured_station_type']
                                          .toString() ==
                                      'artist'
                                  ? item['more_info']['query'].toString()
                                  : item['id'].toString(),
                              item['more_info']['language']?.toString() ??
                                  'hindi',
                              item['more_info']['featured_station_type']
                                  .toString(),
                            )
                                .then((value) {
                              if (value != null) {
                                SaavnAPI()
                                    .getRadioSongs(value)
                                    .then((value) => Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                              opaque: false,
                                              pageBuilder: (_, __, ___) =>
                                                  PlayScreen(
                                                    data: {
                                                      'response': value,
                                                      'index': 0,
                                                      'offline': false,
                                                    },
                                                    fromMiniplayer: false,
                                                  )),
                                        ));
                              }
                            });
                          } else {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => item['type'] ==
                                        'song'
                                    ? PlayScreen(
                                        data: {
                                          'response': currentSongList,
                                          'index': currentSongList.indexWhere(
                                              (e) => e['id'] == item['id']),
                                          'offline': false,
                                        },
                                        fromMiniplayer: false,
                                      )
                                    : SongsListPage(
                                        listItem: item,
                                      ),
                              ),
                            );
                          }
                        },
                        child: SizedBox(
                          width: MediaQuery.of(context).size.height / 4 - 30,
                          child: Column(
                            children: [
                              Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      item['type'] == 'radio_station'
                                          ? 100.0
                                          : 10.0),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: CachedNetworkImage(
                                  errorWidget: (context, _, __) => const Image(
                                    image: AssetImage('assets/cover.jpg'),
                                  ),
                                  imageUrl: item['image']
                                      .toString()
                                      .replaceAll('http:', 'https:')
                                      .replaceAll('50x50', '500x500')
                                      .replaceAll('150x150', '500x500'),
                                  placeholder: (context, url) => Image(
                                    image: (item['type'] == 'playlist' ||
                                            item['type'] == 'album')
                                        ? const AssetImage('assets/album.png')
                                        : item['type'] == 'artist'
                                            ? const AssetImage(
                                                'assets/artist.png')
                                            : const AssetImage(
                                                'assets/cover.jpg'),
                                  ),
                                ),
                              ),
                              Text(
                                formatString(item['title']?.toString()),
                                textAlign: TextAlign.center,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subTitle != '')
                                Text(
                                  subTitle,
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .textTheme
                                          .caption!
                                          .color),
                                )
                              else
                                const SizedBox(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        });
  }
}
