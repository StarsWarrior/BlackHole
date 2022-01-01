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

Future<Color> getColors(ImageProvider imageProvider) async {
  PaletteGenerator paletteGenerator;
  paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
  Color dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;
  if (dominantColor.computeLuminance() > 0.6) {
    Color contrastColor =
        paletteGenerator.darkMutedColor?.color ?? Colors.black;
    if (dominantColor == contrastColor) {
      contrastColor = paletteGenerator.lightMutedColor?.color ?? Colors.white;
    }
    if (contrastColor.computeLuminance() < 0.6) {
      dominantColor = contrastColor;
    }
  }
  GetIt.I<MyTheme>().playGradientColor = dominantColor;
  return dominantColor;
}
