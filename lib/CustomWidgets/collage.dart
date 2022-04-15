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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Collage extends StatelessWidget {
  final bool showGrid;
  final List imageList;
  final String placeholderImage;
  final double borderRadius;
  const Collage({
    Key? key,
    this.borderRadius = 7.0,
    required this.showGrid,
    required this.imageList,
    required this.placeholderImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: 50,
        child: showGrid
            ? GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
  const OfflineCollage({
    Key? key,
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
          7.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.square(
        dimension: 50,
        child: showGrid
            ? GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
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
