import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:blackhole/Screens/Search/search.dart';
import 'package:blackhole/Services/youtube_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubePlaylist extends StatefulWidget {
  final String playlistId;
  final String playlistName;
  final String playlistImage;
  const YouTubePlaylist(
      {Key? key,
      required this.playlistId,
      required this.playlistName,
      required this.playlistImage})
      : super(key: key);

  @override
  _YouTubePlaylistState createState() => _YouTubePlaylistState();
}

class _YouTubePlaylistState extends State<YouTubePlaylist> {
  bool status = false;
  List<Video> searchedList = [];
  bool fetched = false;
  bool done = true;
  List ytSearch =
      Hive.box('settings').get('ytSearch', defaultValue: []) as List;

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
                  if (!fetched)
                    SizedBox(
                      child: Center(
                        child: SizedBox(
                            height: MediaQuery.of(context).size.width / 7,
                            width: MediaQuery.of(context).size.width / 7,
                            child: const CircularProgressIndicator()),
                      ),
                    )
                  else
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          stretch: true,
                          expandedHeight:
                              MediaQuery.of(context).size.height * 0.4,
                          flexibleSpace: FlexibleSpaceBar(
                            title: Text(
                              widget.playlistName,
                              textAlign: TextAlign.center,
                            ),
                            centerTitle: true,
                            background: ShaderMask(
                              shaderCallback: (rect) {
                                return const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.black, Colors.transparent],
                                ).createShader(Rect.fromLTRB(
                                    0, 0, rect.width, rect.height));
                              },
                              blendMode: BlendMode.dstIn,
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                errorWidget: (context, _, __) => const Image(
                                  image: AssetImage('assets/cover.jpg'),
                                ),
                                imageUrl: widget.playlistImage,
                                placeholder: (context, url) => const Image(
                                  image: AssetImage('assets/cover.jpg'),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildListDelegate(
                            searchedList.map(
                              (Video entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 5.0,
                                  ),
                                  child: ListTile(
                                      leading: Card(
                                        elevation: 8,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5.0)),
                                        clipBehavior: Clip.antiAlias,
                                        child: SizedBox(
                                          height: 50.0,
                                          width: 50.0,
                                          child: CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            errorWidget: (context, _, __) =>
                                                CachedNetworkImage(
                                              fit: BoxFit.cover,
                                              imageUrl: entry
                                                  .thumbnails.standardResUrl
                                                  .toString(),
                                              errorWidget: (context, _, __) =>
                                                  const Image(
                                                image: AssetImage(
                                                    'assets/cover.jpg'),
                                              ),
                                            ),
                                            imageUrl: entry.thumbnails.maxResUrl
                                                .toString(),
                                            placeholder: (context, url) =>
                                                const Image(
                                              image: AssetImage(
                                                  'assets/cover.jpg'),
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        entry.title.toString(),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.author.toString(),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          Text(
                                            entry.duration
                                                .toString()
                                                .split('.')[0]
                                                .replaceFirst('0:0', ''),
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        setState(() {
                                          done = false;
                                        });

                                        final Map? response =
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
                                      trailing: PopupMenuButton(
                                          icon: Icon(
                                            Icons.more_vert_rounded,
                                            color: Theme.of(context)
                                                .iconTheme
                                                .color,
                                          ),
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(15.0))),
                                          itemBuilder: (context) => [
                                                PopupMenuItem(
                                                    value: 0,
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          CupertinoIcons.search,
                                                          color:
                                                              Theme.of(context)
                                                                  .iconTheme
                                                                  .color,
                                                        ),
                                                        const SizedBox(
                                                            width: 10.0),
                                                        const Text(
                                                            'Search Home'),
                                                      ],
                                                    )),
                                              ],
                                          onSelected: (int? value) {
                                            if (value == 0) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SearchPage(
                                                    query: entry.title
                                                        .toString()
                                                        .split('|')[0]
                                                        .split('(')[0],
                                                  ),
                                                ),
                                              );
                                            }
                                          })),
                                );
                              },
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                  if (!done)
                    Center(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.width / 2,
                        width: MediaQuery.of(context).size.width / 2,
                        child: Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          clipBehavior: Clip.antiAlias,
                          child: GradientContainer(
                            child: Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                        'Use Main Section for Better Quality and Download Support',
                                        textAlign: TextAlign.center),
                                  ),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.width / 7,
                                      width:
                                          MediaQuery.of(context).size.width / 7,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Theme.of(context)
                                                    .colorScheme
                                                    .secondary),
                                        strokeWidth: 5,
                                      )),
                                  const Text('Fetching Audio Stream'),
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
          MiniPlayer(),
        ],
      ),
    );
  }
}
