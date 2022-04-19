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

import 'package:blackhole/Helpers/config.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:palette_generator/palette_generator.dart';

Future<List<Color>> getColors({
  required ImageProvider imageProvider,
}) async {
  PaletteGenerator paletteGenerator;
  paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
  final Color dominantColor =
      paletteGenerator.dominantColor?.color ?? Colors.black;
  final Color darkMutedColor =
      paletteGenerator.darkMutedColor?.color ?? Colors.black;
  final Color lightMutedColor =
      paletteGenerator.lightMutedColor?.color ?? dominantColor;
  if (dominantColor.computeLuminance() < darkMutedColor.computeLuminance()) {
    // checks if the luminance of the darkMuted color is > than the luminance of the dominant
    GetIt.I<MyTheme>().playGradientColor = [
      darkMutedColor,
      dominantColor,
    ];
    return [
      darkMutedColor,
      dominantColor,
    ];
  } else if (dominantColor == darkMutedColor) {
    // if the two colors are the same, it will replace dominantColor by lightMutedColor
    GetIt.I<MyTheme>().playGradientColor = [
      lightMutedColor,
      darkMutedColor,
    ];
    return [
      lightMutedColor,
      darkMutedColor,
    ];
  } else {
    GetIt.I<MyTheme>().playGradientColor = [
      dominantColor,
      darkMutedColor,
    ];
    return [
      dominantColor,
      darkMutedColor,
    ];
  }
}
