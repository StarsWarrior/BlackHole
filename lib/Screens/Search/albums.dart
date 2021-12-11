import 'package:blackhole/APIs/api.dart';
import 'package:blackhole/CustomWidgets/copy_clipboard.dart';
import 'package:blackhole/CustomWidgets/download_button.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/Screens/Common/song_list.dart';
import 'package:blackhole/Screens/Search/artists.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AlbumSearchPage extends StatefulWidget {
  final String query;
  final String type;

  const AlbumSearchPage({
    Key? key,
    required this.query,
    required this.type,
  }) : super(key: key);

  @override
  _AlbumSearchPageState createState() => _AlbumSearchPageState();
}

class _AlbumSearchPageState extends State<AlbumSearchPage> {
  int page = 1;
  bool loading = false;
  List<Map>? _searchedList;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !loading) {
        page += 1;
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _fetchData() {
    loading = true;
    switch (widget.type) {
      case 'Playlists':
        SaavnAPI()
            .fetchAlbums(
          searchQuery: widget.query,
          type: 'playlist',
          page: page,
        )
            .then((value) {
          final temp = _searchedList ?? [];
          temp.addAll(value);
          setState(() {
            _searchedList = temp;
            loading = false;
          });
        });
        break;
      case 'Albums':
        SaavnAPI()
            .fetchAlbums(
          searchQuery: widget.query,
          type: 'album',
          page: page,
        )
            .then((value) {
          final temp = _searchedList ?? [];
          temp.addAll(value);
          setState(() {
            _searchedList = temp;
            loading = false;
          });
        });
        break;
      case 'Artists':
        SaavnAPI()
            .fetchAlbums(
          searchQuery: widget.query,
          type: 'artist',
          page: page,
        )
            .then((value) {
          final temp = _searchedList ?? [];
          temp.addAll(value);
          setState(() {
            _searchedList = temp;
            loading = false;
          });
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: _searchedList == null
                  ? SizedBox(
                      child: Center(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.width / 7,
                          width: MediaQuery.of(context).size.width / 7,
                          child: const CircularProgressIndicator(),
                        ),
                      ),
                    )
                  : _searchedList!.isEmpty
                      ? emptyScreen(
                          context,
                          0,
                          ':( ',
                          100,
                          AppLocalizations.of(context)!.sorry,
                          60,
                          AppLocalizations.of(context)!.resultsNotFound,
                          20,
                        )
                      : CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          controller: _scrollController,
                          slivers: [
                            SliverAppBar(
                              // backgroundColor: Colors.transparent,
                              elevation: 0,
                              stretch: true,
                              pinned: true,
                              // floating: true,
                              expandedHeight:
                                  MediaQuery.of(context).size.height * 0.4,
                              flexibleSpace: FlexibleSpaceBar(
                                title: Text(
                                  widget.type,
                                  textAlign: TextAlign.center,
                                ),
                                centerTitle: true,
                                background: ShaderMask(
                                  shaderCallback: (rect) {
                                    return const LinearGradient(
                                      begin: Alignment.center,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black,
                                        Colors.transparent
                                      ],
                                    ).createShader(
                                      Rect.fromLTRB(
                                        0,
                                        0,
                                        rect.width,
                                        rect.height,
                                      ),
                                    );
                                  },
                                  blendMode: BlendMode.dstIn,
                                  child: Image(
                                    fit: BoxFit.cover,
                                    image: AssetImage(
                                      widget.type == 'Artists'
                                          ? 'assets/artist.png'
                                          : 'assets/album.png',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildListDelegate(
                                _searchedList!.map(
                                  (Map entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 7),
                                      child: ListTile(
                                        title: Text(
                                          '${entry["title"]}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        onLongPress: () {
                                          copyToClipboard(
                                            context: context,
                                            text: '${entry["title"]}',
                                          );
                                        },
                                        subtitle: Text(
                                          '${entry["subtitle"]}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        leading: Card(
                                          elevation: 8,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              widget.type == 'Artists'
                                                  ? 50.0
                                                  : 7.0,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            errorWidget: (context, _, __) =>
                                                Image(
                                              fit: BoxFit.cover,
                                              image: AssetImage(
                                                widget.type == 'Artists'
                                                    ? 'assets/artist.png'
                                                    : 'assets/album.png',
                                              ),
                                            ),
                                            imageUrl:
                                                '${entry["image"].replaceAll('http:', 'https:')}',
                                            placeholder: (context, url) =>
                                                Image(
                                              fit: BoxFit.cover,
                                              image: AssetImage(
                                                widget.type == 'Artists'
                                                    ? 'assets/artist.png'
                                                    : 'assets/album.png',
                                              ),
                                            ),
                                          ),
                                        ),
                                        trailing: widget.type != 'Albums'
                                            ? null
                                            : AlbumDownloadButton(
                                                albumName:
                                                    entry['title'].toString(),
                                                albumId: entry['id'].toString(),
                                              ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              opaque: false,
                                              pageBuilder: (_, __, ___) =>
                                                  widget.type == 'Artists'
                                                      ? ArtistSearchPage(
                                                          data: entry,
                                                        )
                                                      : SongsListPage(
                                                          listItem: entry,
                                                        ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
