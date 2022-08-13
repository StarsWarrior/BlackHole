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

import 'package:flutter/material.dart';

class HoverBox extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext, bool, Widget?) builder;
  const HoverBox({
    super.key,
    required this.child,
    required this.builder,
  });

  @override
  _HoverBox createState() => _HoverBox();
}

class _HoverBox extends State<HoverBox> {
  final ValueNotifier<bool> isInside = ValueNotifier<bool>(false);

  void _onEnter(PointerEvent details) {
    isInside.value = true;
  }

  void _onExit(PointerEvent details) {
    isInside.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: ValueListenableBuilder(
        valueListenable: isInside,
        child: widget.child,
        builder: (
          BuildContext context,
          bool isHover,
          Widget? child,
        ) {
          return widget.builder(context, isHover, child);
        },
      ),
    );
  }
}
