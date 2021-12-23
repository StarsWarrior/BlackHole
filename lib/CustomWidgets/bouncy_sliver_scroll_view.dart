import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BouncyImageSliverScrollView extends StatelessWidget {
  final ScrollController? scrollController;
  final SliverList sliverList;
  final bool shrinkWrap;
  final List<Widget>? actions;
  final String title;
  final String? imageUrl;
  final bool localImage;
  final String placeholderImage;
  const BouncyImageSliverScrollView({
    Key? key,
    this.scrollController,
    this.shrinkWrap = false,
    required this.sliverList,
    required this.title,
    this.placeholderImage = 'assets/cover.jpg',
    this.localImage = false,
    this.imageUrl,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget image = imageUrl == null
        ? Image(
            fit: BoxFit.cover,
            image: AssetImage(placeholderImage),
          )
        : localImage
            ? Image(
                image: FileImage(
                  File(
                    imageUrl!,
                  ),
                ),
                fit: BoxFit.cover,
              )
            : CachedNetworkImage(
                fit: BoxFit.cover,
                errorWidget: (context, _, __) => Image(
                  fit: BoxFit.cover,
                  image: AssetImage(placeholderImage),
                ),
                imageUrl: imageUrl!,
                placeholder: (context, url) => Image(
                  fit: BoxFit.cover,
                  image: AssetImage(placeholderImage),
                ),
              );
    final bool rotated =
        MediaQuery.of(context).size.height < MediaQuery.of(context).size.width;
    return CustomScrollView(
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          elevation: 0,
          stretch: true,
          pinned: true,
          // floating: true,
          // backgroundColor: Colors.transparent,
          expandedHeight: MediaQuery.of(context).size.height * 0.4,
          actions: actions,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              title,
              textAlign: TextAlign.center,
            ),
            centerTitle: true,
            background: Stack(
              children: [
                SizedBox.expand(
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black,
                          Colors.transparent,
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
                    child: image,
                  ),
                ),
                if (rotated)
                  Align(
                    alignment: const Alignment(-0.85, 0.5),
                    child: Card(
                      elevation: 5,
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: image,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        sliverList,
      ],
    );
  }
}
