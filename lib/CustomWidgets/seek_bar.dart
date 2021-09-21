import 'dart:math';

import 'package:blackhole/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeEnd;

  const SeekBar({
    required this.duration,
    required this.position,
    this.bufferedPosition = Duration.zero,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;
  bool _dragging = false;
  late SliderThemeData _sliderThemeData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 4.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = min(
      _dragValue ?? widget.position.inMilliseconds.toDouble(),
      widget.duration.inMilliseconds.toDouble(),
    );
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.95,
      child: Stack(
        children: [
          SliderTheme(
            data: _sliderThemeData.copyWith(
              thumbShape: HiddenThumbComponentShape(),
              activeTrackColor:
                  Theme.of(context).iconTheme.color!.withOpacity(0.5),
              inactiveTrackColor:
                  Theme.of(context).iconTheme.color!.withOpacity(0.3),
              trackHeight: 4.0,
              // trackShape: RoundedRectSliderTrackShape(),
              trackShape: const RectangularSliderTrackShape(),
            ),
            child: ExcludeSemantics(
              child: Slider(
                max: widget.duration.inMilliseconds.toDouble(),
                value: min(widget.bufferedPosition.inMilliseconds.toDouble(),
                    widget.duration.inMilliseconds.toDouble()),
                onChanged: (value) {},
              ),
            ),
          ),
          SliderTheme(
            data: _sliderThemeData.copyWith(
              inactiveTrackColor: Colors.transparent,
              activeTrackColor: Theme.of(context).iconTheme.color,
              thumbColor: Theme.of(context).iconTheme.color,
              trackHeight: 4.0,
            ),
            child: Slider(
              max: widget.duration.inMilliseconds.toDouble(),
              value: value,
              onChanged: (value) {
                if (!_dragging) {
                  _dragging = true;
                }
                setState(() {
                  _dragValue = value;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(Duration(milliseconds: value.round()));
                }
              },
              onChangeEnd: (value) {
                if (widget.onChangeEnd != null) {
                  widget.onChangeEnd!(Duration(milliseconds: value.round()));
                }
                _dragging = false;
              },
            ),
          ),
          Positioned(
            right: 13.0,
            bottom: 18.0,
            child: StreamBuilder<double>(
                stream: audioHandler.speed,
                builder: (context, snapshot) {
                  final String speedValue =
                      '${snapshot.data?.toStringAsFixed(1) ?? 1.0}x';
                  return IconButton(
                    icon: Text(
                      speedValue,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: speedValue == '1.0x'
                            ? Theme.of(context).disabledColor
                            : null,
                      ),
                    ),
                    onPressed: () {
                      showSliderDialog(
                        context: context,
                        title: 'Adjust Speed',
                        divisions: 25,
                        min: 0.5,
                        max: 3.0,
                      );
                    },
                  );
                }),
          ),
          Positioned(
            left: 25.0,
            bottom: -4.0,
            child: Text(
              RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch('$_position')
                      ?.group(1) ??
                  '$_position',
              // style: Theme.of(context).textTheme.caption,
            ),
          ),
          Positioned(
            right: 25.0,
            bottom: -4.0,
            child: Text(
              RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$')
                      .firstMatch('$_duration')
                      ?.group(1) ??
                  '$_duration',
              // style: Theme.of(context).textTheme.caption,
            ),
          ),
        ],
      ),
    );
  }

  Duration get _duration => widget.duration;
  Duration get _position => widget.position;
}

class HiddenThumbComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {}
}

void showSliderDialog({
  required BuildContext context,
  required String title,
  required int divisions,
  required double min,
  required double max,
  String valueSuffix = '',
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      content: StreamBuilder<double>(
          stream: audioHandler.speed,
          builder: (context, snapshot) {
            double value = snapshot.data ?? audioHandler.speed.value;
            if (value > max) {
              value = max;
            }
            if (value < min) {
              value = min;
            }
            return SizedBox(
              height: 100.0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.minus),
                        onPressed: audioHandler.speed.value > min
                            ? () {
                                audioHandler
                                    .setSpeed(audioHandler.speed.value - 0.1);
                              }
                            : null,
                      ),
                      Text('${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                          style: const TextStyle(
                              fontFamily: 'Fixed',
                              fontWeight: FontWeight.bold,
                              fontSize: 24.0)),
                      IconButton(
                        icon: const Icon(CupertinoIcons.plus),
                        onPressed: audioHandler.speed.value < max
                            ? () {
                                audioHandler
                                    .setSpeed(audioHandler.speed.value + 0.1);
                              }
                            : null,
                      ),
                    ],
                  ),
                  Slider(
                    inactiveColor:
                        Theme.of(context).iconTheme.color!.withOpacity(0.4),
                    activeColor: Theme.of(context).iconTheme.color,
                    divisions: divisions,
                    min: min,
                    max: max,
                    value: value,
                    onChanged: audioHandler.setSpeed,
                  ),
                ],
              ),
            );
          }),
    ),
  );
}
