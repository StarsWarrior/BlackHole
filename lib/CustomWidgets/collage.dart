import 'dart:io';

import 'package:blackhole/Helpers/image_downs.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Collage extends StatelessWidget {
  final bool showGrid;
  final List imageList;
  final bool fixSize;
  final String placeholderImage;
  final String? artistName;
  final String? tempDirPath;
  const Collage({
    Key? key,
    required this.showGrid,
    required this.imageList,
    required this.placeholderImage,
    this.fixSize = true,
    this.artistName,
    this.tempDirPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          (artistName != null && tempDirPath != null) ? 100.0 : 7.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: fixSize ? 50 : null,
        child: (artistName != null && tempDirPath != null)
            ? Image(
                fit: BoxFit.cover,
                image: FileImage(
                  File(
                    '$tempDirPath/images/artists/${artistName!.split(", ").first}.jpg',
                  ),
                ),
                errorBuilder: (context, _, __) {
                  getArtistImage(
                    name: artistName!.split(', ').first,
                    tempDirPath: tempDirPath!,
                  );
                  return CachedNetworkImage(
                    fit: BoxFit.cover,
                    errorWidget: (context, _, __) => Image(
                      fit: BoxFit.cover,
                      image: AssetImage(placeholderImage),
                    ),
                    imageUrl: imageList[0]['image']
                        .toString()
                        .replaceAll('http:', 'https:'),
                    placeholder: (context, _) => Image(
                      fit: BoxFit.cover,
                      image: AssetImage(placeholderImage),
                    ),
                  );
                },
              )
            : showGrid
                ? GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: imageList.length < 3 ? 1 : 2,
                    children: imageList
                        .map(
                          (image) => CachedNetworkImage(
                            fit: BoxFit.cover,
                            errorWidget: (context, _, __) => Image(
                              fit: BoxFit.cover,
                              image: AssetImage(placeholderImage),
                            ),
                            imageUrl: image['image']
                                .toString()
                                .replaceAll('http:', 'https:'),
                            placeholder: (context, _) => Image(
                              fit: BoxFit.cover,
                              image: AssetImage(placeholderImage),
                            ),
                          ),
                        )
                        .toList(),
                  )
                : CachedNetworkImage(
                    fit: BoxFit.cover,
                    errorWidget: (context, _, __) => Image(
                      fit: BoxFit.cover,
                      image: AssetImage(placeholderImage),
                    ),
                    imageUrl: imageList[0]['image']
                        .toString()
                        .replaceAll('http:', 'https:'),
                    placeholder: (context, _) => Image(
                      fit: BoxFit.cover,
                      image: AssetImage(placeholderImage),
                    ),
                  ),
      ),
    );
  }
}

class OfflineCollage extends StatelessWidget {
  final List imageList;
  final String placeholderImage;
  final bool showGrid;
  final bool fixSize;
  final String? artistName;
  final String? tempDirPath;
  const OfflineCollage({
    Key? key,
    this.fixSize = true,
    this.artistName,
    this.tempDirPath,
    required this.showGrid,
    required this.imageList,
    required this.placeholderImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          (artistName != null && tempDirPath != null) ? 100.0 : 7.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: fixSize ? 50 : null,
        child: (artistName != null && tempDirPath != null)
            ? Image(
                fit: BoxFit.cover,
                image: FileImage(
                  File(
                    '$tempDirPath/images/artists/${artistName!.split(", ").first}.jpg',
                  ),
                ),
                errorBuilder: (context, _, __) {
                  getArtistImage(
                    name: artistName!.split(', ').first,
                    tempDirPath: tempDirPath!,
                  );
                  return imageList[0] == null
                      ? Image(
                          fit: BoxFit.cover,
                          image: AssetImage(placeholderImage),
                        )
                      : Image(
                          fit: BoxFit.cover,
                          image: FileImage(
                            File(
                              imageList[0]['image'].toString(),
                            ),
                          ),
                          errorBuilder: (context, _, __) => Image(
                            fit: BoxFit.cover,
                            image: AssetImage(placeholderImage),
                          ),
                        );
                },
              )
            : showGrid
                ? GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: imageList.length < 3 ? 1 : 2,
                    children: imageList.map((image) {
                      return image == null
                          ? Image(
                              fit: BoxFit.cover,
                              image: AssetImage(placeholderImage),
                            )
                          : Image(
                              fit: BoxFit.cover,
                              image: FileImage(
                                File(
                                  image['image'].toString(),
                                ),
                              ),
                              errorBuilder: (context, _, __) => Image(
                                fit: BoxFit.cover,
                                image: AssetImage(placeholderImage),
                              ),
                            );
                    }).toList(),
                  )
                : imageList[0] == null
                    ? Image(
                        fit: BoxFit.cover,
                        image: AssetImage(placeholderImage),
                      )
                    : Image(
                        fit: BoxFit.cover,
                        image: FileImage(
                          File(
                            imageList[0]['image'].toString(),
                          ),
                        ),
                        errorBuilder: (context, _, __) => Image(
                          fit: BoxFit.cover,
                          image: AssetImage(placeholderImage),
                        ),
                      ),
      ),
    );
  }
}
