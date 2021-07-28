import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class Equalizer extends StatefulWidget {
  Equalizer({Key key}) : super(key: key);

  @override
  _EqualizerState createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer> {
  bool enabled = Hive.box('settings').get("setEqualizer") ?? false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Scaffold(
      content:
          // body:
          SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SwitchListTile(
              title: Text('Equalizer'),
              value: enabled,
              activeColor: Theme.of(context).accentColor,
              onChanged: (value) {
                enabled = value;
                Hive.box('settings').put("setEqualizer", value);
                AudioService.customAction("setEqualizer", value);
                setState(() {});
              },
            ),
            if (enabled)
              Container(
                height: MediaQuery.of(context).size.height / 2,
                child: EqualizerControls(),
              ),
          ],
        ),
      ),
    );
  }
}

class EqualizerControls extends StatefulWidget {
  @override
  _EqualizerControlsState createState() => _EqualizerControlsState();
}

class _EqualizerControlsState extends State<EqualizerControls> {
  Future<Map> getEq() async {
    final Map parameters =
        await AudioService.customAction('getEqualizerParams');
    return parameters;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map>(
      future: getEq(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return SizedBox();
        final data = snapshot.data;
        if (data == null) return SizedBox();
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            for (Map band in data['bands'])
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: VerticalSlider(
                        min: data['minDecibels'],
                        max: data['maxDecibels'],
                        value: band['gain'],
                        bandIndex: band['index'],
                      ),
                    ),
                    Text(
                      '${band['centerFrequency'].round()}\nHz',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class VerticalSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final int bandIndex;

  const VerticalSlider({
    Key key,
    @required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.bandIndex,
  }) : super(key: key);

  @override
  _VerticalSliderState createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  double sliderValue;

  void setGain(int bandIndex, double gain) {
    AudioService.customAction('setBandGain', {'band': bandIndex, 'gain': gain});
  }

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
              activeColor: Theme.of(context).accentColor,
              inactiveColor: Theme.of(context).accentColor.withOpacity(0.4),
              value: sliderValue ?? widget.value,
              min: widget.min,
              max: widget.max,
              onChanged: (double newValue) {
                setState(() {
                  sliderValue = newValue;
                  setGain(widget.bandIndex, newValue);
                });
              }),
        ),
      ),
    );
  }
}
