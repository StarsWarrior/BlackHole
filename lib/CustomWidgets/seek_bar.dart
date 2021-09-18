import 'dart:math';

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
      width: MediaQuery.of(context).size.width * 0.975,
      child: Stack(
        children: [
          SliderTheme(
            data: _sliderThemeData.copyWith(
              thumbShape: HiddenThumbComponentShape(),
              activeTrackColor: Theme.of(context).accentColor.withOpacity(0.5),
              inactiveTrackColor:
                  Theme.of(context).accentColor.withOpacity(0.3),
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
              activeTrackColor: Theme.of(context).accentColor,
              thumbColor: Theme.of(context).accentColor,
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
            left: 25.0,
            bottom: 0.0,
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
            bottom: 0.0,
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
