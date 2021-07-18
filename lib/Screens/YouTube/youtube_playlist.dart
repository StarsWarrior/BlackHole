import 'package:blackhole/CustomWidgets/gradientContainers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class YouTubePlaylist extends StatefulWidget {
  final String playlistId;
  final String playlistName;
  final String playlistImage;
  YouTubePlaylist(
      {Key key,
      @required this.playlistId,
      @required this.playlistName,
      @required this.playlistImage})
      : super(key: key);

  @override
  _YouTubePlaylistState createState() => _YouTubePlaylistState();
}

class _YouTubePlaylistState extends State<YouTubePlaylist> {
  bool status = false;
  List searchedList = [];
  bool fetched = false;
  bool done = true;
  List ytSearch = Hive.box('settings').get('ytSearch', defaultValue: []);

  @override
  void initState() {
    if (!status) {
      status = true;
      YouTubeServices().getPlaylistSongs(widget.playlistId).then((value) {
        if (value.isNotEmpty) {
          setState(() {
            searchedList = value;
            fetched = true;
          });
        } else {
          status = false;
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext cntxt) {
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  (!fetched)
                      ? Container(
                          child: Center(
                            child: Container(
                                height: MediaQuery.of(context).size.width / 7,
                                width: MediaQuery.of(context).size.width / 7,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).accentColor),
                                  strokeWidth: 5,
                                )),
                          ),
                        )
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
                                  widget.playlistName ?? 'Songs',
                                  textAlign: TextAlign.center,
                                ),
                                centerTitle: true,
                                stretchModes: [StretchMode.zoomBackground],
                                background: ShaderMask(
                                  shaderCallback: (rect) {
                                    return LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black,
                                        Colors.transparent
                                      ],
                                    ).createShader(Rect.fromLTRB(
                                        0, 0, rect.width, rect.height));
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: CachedNetworkImage(
                                    fit: BoxFit.cover,
                                    errorWidget: (context, _, __) => Image(
                                      image: AssetImage('assets/cover.jpg'),
                                    ),
                                    imageUrl: widget.playlistImage,
                                    placeholder: (context, url) => Image(
                                      image: AssetImage('assets/cover.jpg'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildListDelegate(
                                searchedList.map(
                                  (entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          left: 15.0,
                                          right: 15.0,
                                          bottom: 10.0),
                                      child: Card(
                                        elevation: 8,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0)),
                                        clipBehavior: Clip.antiAlias,
                                        child: GradientContainer(
                                          child: GestureDetector(
                                            child: Column(
                                              children: [
                                                CachedNetworkImage(
                                                  errorWidget:
                                                      (context, _, __) =>
                                                          CachedNetworkImage(
                                                    imageUrl: (entry.thumbnails
                                                        .standardResUrl),
                                                    errorWidget:
                                                        (context, _, __) =>
                                                            Image(
                                                      image: AssetImage(
                                                          'assets/ytCover.png'),
                                                    ),
                                                  ),
                                                  imageUrl: entry
                                                      .thumbnails.maxResUrl,
                                                  placeholder: (context, url) =>
                                                      Image(
                                                    image: AssetImage(
                                                        'assets/ytCover.png'),
                                                  ),
                                                ),
                                                ListTile(
                                                  dense: true,
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0),
                                                  title: Text(
                                                    entry.title,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                  // isThreeLine: true,
                                                  subtitle: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            entry.author,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .only(
                                                                right: 15.0),
                                                        child: Text(
                                                          entry.duration
                                                              .toString()
                                                              .split(".")[0],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            onTap: () async {
                                              setState(() {
                                                done = false;
                                              });

                                              Map response =
                                                  await YouTubeServices()
                                                      .formatVideo(entry);
                                              setState(() {
                                                done = true;
                                              });
                                              Navigator.push(
                                                context,
                                                PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder: (_, __, ___) =>
                                                      PlayScreen(
                                                    fromMiniplayer: false,
                                                    data: {
                                                      'response': [response],
                                                      'index': 0,
                                                      'offline': false,
                                                      'fromYT': true,
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                            if (!done)
                              Center(
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.width / 2,
                                  width: MediaQuery.of(context).size.width / 2,
                                  child: Card(
                                    elevation: 10,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    clipBehavior: Clip.antiAlias,
                                    child: GradientContainer(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            SizedBox(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    7,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    7,
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Theme.of(context)
                                                              .accentColor),
                                                  strokeWidth: 5,
                                                )),
                                            Text('Fetching Audio Stream'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                ],
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}
