import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Collage extends StatelessWidget {
  final List imageList;
  final String placeholderImage;
  const Collage(
      {Key key, @required this.imageList, @required this.placeholderImage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 50,
          width: 50,
          child: Stack(
            children: [
              GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: imageList.length < 3 ? 1 : 2,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  children: [
                    for (int _ in [1, 2, 3, 4])
                      Image(
                        image: AssetImage(placeholderImage),
                      ),
                  ]),
              GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: imageList.length < 3 ? 1 : 2,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  children: imageList
                      .map(
                        (image) => CachedNetworkImage(
                          errorWidget: (context, _, __) => Image(
                            image: AssetImage(placeholderImage),
                          ),
                          imageUrl:
                              image['image'].replaceAll('http:', 'https:'),
                          placeholder: (context, _) => Image(
                            image: AssetImage(placeholderImage),
                          ),
                        ),
                      )
                      .toList()),
            ],
          ),
        ));
  }
}

class OfflineCollage extends StatelessWidget {
  final List imageList;
  final String placeholderImage;
  const OfflineCollage(
      {Key key, @required this.imageList, @required this.placeholderImage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 50,
          width: 50,
          child: Stack(
            children: [
              GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: imageList.length < 3 ? 1 : 2,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  children: [
                    for (int _ in [1, 2, 3, 4])
                      Image(
                        image: AssetImage(placeholderImage),
                      ),
                  ]),
              GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: imageList.length < 3 ? 1 : 2,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  children: imageList.map((image) {
                    return image == null
                        ? Image(
                            image: AssetImage('assets/album.png'),
                          )
                        : Image(
                            image: MemoryImage(image['image']),
                          );
                  }).toList()),
            ],
          ),
        ));
  }
}
