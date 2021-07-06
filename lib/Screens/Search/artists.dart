import 'dart:ui';
import 'package:blackhole/CustomWidgets/downloadButton.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:blackhole/CustomWidgets/emptyScreen.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/APIs/api.dart';

class ArtistSearchPage extends StatefulWidget {
  final String artistName;
  final String artistToken;
  final String artistImage;

  ArtistSearchPage({
    Key key,
    @required this.artistToken,
    this.artistName,
    this.artistImage,
  }) : super(key: key);

  @override
  _ArtistSearchPageState createState() => _ArtistSearchPageState();
}

class _ArtistSearchPageState extends State<ArtistSearchPage> {
  bool status = false;
  Map data = {};
  bool fetched = false;

  @override
  Widget build(BuildContext context) {
    if (!status) {
      status = true;
      SaavnAPI().fetchArtistSongs(widget.artistToken).then((value) {
        setState(() {
          data = value;
          fetched = true;
        });
      });
    }
    return GradientContainer(
      child: Column(children: [
        Expanded(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: !fetched
                ? Container(
                    child: Center(
                      child: Container(
                          height: MediaQuery.of(context).size.width / 6,
                          width: MediaQuery.of(context).size.width / 6,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).accentColor),
                            strokeWidth: 5,
                          )),
                    ),
                  )
                : data.isEmpty
                    ? EmptyScreen().emptyScreen(context, 0, ":( ", 100, "SORRY",
                        60, "Results Not Found", 20)
                    : CustomScrollView(
                        physics: BouncingScrollPhysics(),
                        slivers: [
                          SliverAppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            stretch: true,
                            pinned: false,
                            expandedHeight:
                                MediaQuery.of(context).size.height * 0.4,
                            flexibleSpace: FlexibleSpaceBar(
                              title: Text(
                                widget.artistName ?? 'Songs',
                                textAlign: TextAlign.center,
                              ),
                              centerTitle: true,
                              stretchModes: [StretchMode.zoomBackground],
                              background: ShaderMask(
                                shaderCallback: (rect) {
                                  return LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black, Colors.transparent],
                                  ).createShader(Rect.fromLTRB(
                                      0, 0, rect.width, rect.height));
                                },
                                blendMode: BlendMode.dstIn,
                                child: CachedNetworkImage(
                                  fit: BoxFit.cover,
                                  errorWidget: (context, _, __) => Image(
                                    image: AssetImage('assets/artist.png'),
                                  ),
                                  imageUrl: widget.artistImage
                                      .replaceAll('http:', 'https:')
                                      .replaceAll('50x50', '500x500')
                                      .replaceAll('150x150', '500x500'),
                                  placeholder: (context, url) => Image(
                                    image: AssetImage('assets/artist.png'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate(
                              data.entries.map(
                                (entry) {
                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            25, 30, 0, 0),
                                        child: Row(
                                          children: [
                                            Text(
                                              entry.key,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .accentColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ListView.builder(
                                        itemCount: entry.value.length,
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        padding:
                                            EdgeInsets.fromLTRB(5, 10, 5, 0),
                                        itemBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 7, 7, 5),
                                            child: ListTile(
                                              contentPadding:
                                                  EdgeInsets.only(left: 15.0),
                                              title: Text(
                                                '${entry.value[index]["title"]}',
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              subtitle: Text(
                                                '${entry.value[index]["subtitle"]}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              leading: Card(
                                                elevation: 8,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7.0)),
                                                clipBehavior: Clip.antiAlias,
                                                child: CachedNetworkImage(
                                                  errorWidget:
                                                      (context, _, __) => Image(
                                                    image: AssetImage((entry
                                                                    .key ==
                                                                'Top Songs' ||
                                                            entry.key ==
                                                                'Latest Release')
                                                        ? 'assets/cover.jpg'
                                                        : 'assets/album.png'),
                                                  ),
                                                  imageUrl:
                                                      '${entry.value[index]["image"].replaceAll('http:', 'https:')}',
                                                  placeholder: (context, url) =>
                                                      Image(
                                                    image: AssetImage((entry
                                                                    .key ==
                                                                'Top Songs' ||
                                                            entry.key ==
                                                                'Latest Release' ||
                                                            entry.key ==
                                                                'Singles')
                                                        ? 'assets/cover.jpg'
                                                        : 'assets/album.png'),
                                                  ),
                                                ),
                                              ),
                                              trailing: (entry.key ==
                                                          'Top Songs' ||
                                                      entry.key ==
                                                          'Latest Release' ||
                                                      entry.key == 'Singles')
                                                  ? DownloadButton(
                                                      data: entry.value[index],
                                                      icon: 'download',
                                                    )
                                                  : null,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    pageBuilder: (_, __, ___) => (entry
                                                                    .key ==
                                                                'Top Songs' ||
                                                            entry.key ==
                                                                'Latest Release' ||
                                                            entry.key ==
                                                                'Singles')
                                                        ? PlayScreen(
                                                            data: {
                                                              'response':
                                                                  entry.value,
                                                              'index': index,
                                                              'offline': false,
                                                            },
                                                            fromMiniplayer:
                                                                false,
                                                          )
                                                        : SongsListPage(
                                                            listImage: entry
                                                                    .value[
                                                                index]["image"],
                                                            listItem: entry
                                                                .value[index]),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ).toList(),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        MiniPlayer(),
      ]),
    );
  }
}
