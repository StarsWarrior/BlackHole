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
import 'package:marquee/marquee.dart' as wrapped;

class AnimatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double? textScaleFactor;
  final TextDirection textDirection;
  final Axis scrollAxis;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign defaultAlignment;
  final double blankSpace;
  final double velocity;
  final Duration startAfter;
  final Duration pauseAfterRound;
  final int? numberOfRounds;
  final bool showFadingOnlyWhenScrolling;
  final double fadingEdgeStartFraction;
  final double fadingEdgeEndFraction;
  final double startPadding;
  final Duration accelerationDuration;
  final Curve accelerationCurve;
  final Duration decelerationDuration;
  final Curve decelerationCurve;
  final VoidCallback? onDone;

  const AnimatedText({
    required this.text,
    this.style,
    this.textScaleFactor,
    this.textDirection = TextDirection.ltr,
    this.scrollAxis = Axis.horizontal,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.defaultAlignment = TextAlign.center,
    this.blankSpace = 0.0,
    this.velocity = 50.0,
    this.startAfter = Duration.zero,
    this.pauseAfterRound = Duration.zero,
    this.showFadingOnlyWhenScrolling = true,
    this.fadingEdgeStartFraction = 0.0,
    this.fadingEdgeEndFraction = 0.0,
    this.numberOfRounds,
    this.startPadding = 0.0,
    this.accelerationDuration = Duration.zero,
    this.accelerationCurve = Curves.decelerate,
    this.decelerationDuration = Duration.zero,
    this.decelerationCurve = Curves.decelerate,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(
          text: text,
          style: style,
        );

        final tp = TextPainter(
          maxLines: 1,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          text: span,
        );

        tp.layout(maxWidth: constraints.maxWidth);

        if (tp.didExceedMaxLines) {
          return SizedBox(
            height: tp.height,
            width: constraints.maxWidth,
            child: wrapped.Marquee(
              text: '  $text${" " * 30}',
              style: style,
              textScaleFactor: textScaleFactor,
              textDirection: textDirection,
              scrollAxis: scrollAxis,
              crossAxisAlignment: crossAxisAlignment,
              blankSpace: blankSpace,
              velocity: velocity,
              startAfter: startAfter,
              pauseAfterRound: pauseAfterRound,
              numberOfRounds: numberOfRounds,
              showFadingOnlyWhenScrolling: showFadingOnlyWhenScrolling,
              fadingEdgeStartFraction: fadingEdgeStartFraction,
              fadingEdgeEndFraction: fadingEdgeEndFraction,
              startPadding: startPadding,
              accelerationDuration: accelerationDuration,
              accelerationCurve: accelerationCurve,
              decelerationDuration: decelerationDuration,
              decelerationCurve: decelerationCurve,
              onDone: onDone,
            ),
          );
        } else {
          return SizedBox(
            width: constraints.maxWidth,
            child: Text(
              text,
              style: style,
              textAlign: defaultAlignment,
            ),
          );
        }
      },
    );
  }
}
