import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HorizontalAlbumsList extends StatelessWidget {
  final List songsList;
  final Function(int) onTap;
  const HorizontalAlbumsList({
    Key? key,
    required this.songsList,
    required this.onTap,
  }) : super(key: key);

  String formatString(String? text) {
    return text == null
        ? ''
        : text
            .replaceAll('&amp;', '&')
            .replaceAll('&#039;', "'")
            .replaceAll('&quot;', '"')
            .trim();
  }

  String getSubTitle(Map item) {
    final type = item['type'];
    if (type == 'charts') {
      return '';
    } else if (type == 'playlist' || type == 'radio_station') {
      return formatString(item['subtitle']?.toString());
    } else if (type == 'song') {
      return formatString(item['artist']?.toString());
    } else {
      if (item['subtitle'] != null) {
        return formatString(item['subtitle']?.toString());
      }
      final artists = item['more_info']?['artistMap']?['artists']
          .map((artist) => artist['name'])
          .toList();
      if (artists != null) {
        return formatString(artists?.join(', ')?.toString());
      }
      if (item['artist'] != null) {
        return formatString(item['artist']?.toString());
      }
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double boxSize =
        MediaQuery.of(context).size.height > MediaQuery.of(context).size.width
            ? MediaQuery.of(context).size.width
            : MediaQuery.of(context).size.height;

    return SizedBox(
      height: boxSize / 2 + 10,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        itemCount: songsList.length,
        itemBuilder: (context, index) {
          final Map item = songsList[index] as Map;
          final subTitle = getSubTitle(item);
          return GestureDetector(
            onLongPress: () {
              Feedback.forLongPress(context);
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    backgroundColor: Colors.transparent,
                    contentPadding: EdgeInsets.zero,
                    content: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          item['type'] == 'radio_station' ? 1000.0 : 15.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        errorWidget: (context, _, __) => const Image(
                          fit: BoxFit.cover,
                          image: AssetImage('assets/cover.jpg'),
                        ),
                        imageUrl: item['image']
                            .toString()
                            .replaceAll('http:', 'https:')
                            .replaceAll('50x50', '500x500')
                            .replaceAll('150x150', '500x500'),
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
                  );
                },
              );
            },
            onTap: () {
              onTap(index);
            },
            child: SizedBox(
              width: boxSize / 2 - 30,
              child: Column(
                children: [
                  SizedBox.square(
                    dimension: boxSize / 2 - 30,
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          item['type'] == 'radio_station' ||
                                  item['type'] == 'artist'
                              ? 1000.0
                              : 10.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        errorWidget: (context, _, __) => const Image(
                          fit: BoxFit.cover,
                          image: AssetImage('assets/cover.jpg'),
                        ),
                        imageUrl: item['image']
                            .toString()
                            .replaceAll('http:', 'https:')
                            .replaceAll('50x50', '500x500')
                            .replaceAll('150x150', '500x500'),
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
                  ),
                  Text(
                    formatString(item['title']?.toString()),
                    textAlign: TextAlign.center,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subTitle != '')
                    Text(
                      subTitle,
                      textAlign: TextAlign.center,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.caption!.color,
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
