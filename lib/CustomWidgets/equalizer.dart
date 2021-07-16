import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';

class Equalizer extends StatefulWidget {
  Equalizer({Key key}) : super(key: key);

  @override
  _EqualizerState createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer> {
  bool enabled = Hive.box('settings').get("setEqualizer") ?? false;
  final _equalizer = AndroidEqualizer();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SwitchListTile(
            title: Text('Equalizer'),
            value: enabled,
            onChanged: (value) {
              enabled = value;
              Hive.box('settings').put("equalizerEnabled", value);
              AudioService.customAction("equalizerEnabled", value);
              setState(() {});
            },
          ),
          EqualizerControls(
            equalizer: _equalizer,
          ),
        ],
      ),
    );
  }
}

class EqualizerControls extends StatelessWidget {
  final AndroidEqualizer equalizer;

  const EqualizerControls({
    Key key,
    @required this.equalizer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AndroidEqualizerParameters>(
      future: equalizer.parameters,
      builder: (context, snapshot) {
        final parameters = snapshot.data;
        if (parameters == null) return SizedBox();
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            for (var band in parameters.bands)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<double>(
                    stream: band.gainStream,
                    builder: (context, snapshot) {
                      return VerticalSlider(
                        min: parameters.minDecibels,
                        max: parameters.maxDecibels,
                        value: band.gain,
                        onChanged: band.setGain,
                      );
                    },
                  ),
                  Text('${band.centerFrequency.round()} Hz'),
                ],
              ),
          ],
        );
      },
    );
  }
}

class VerticalSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const VerticalSlider({
    Key key,
    @required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.fitHeight,
      alignment: Alignment.bottomCenter,
      child: Transform.rotate(
        angle: -pi / 2,
        child: Container(
          width: 400.0,
          height: 400.0,
          alignment: Alignment.center,
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
