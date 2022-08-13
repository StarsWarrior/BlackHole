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

import 'dart:math';

import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

class Equalizer extends StatefulWidget {
  const Equalizer({super.key});

  @override
  _EqualizerState createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer> {
  bool enabled =
      Hive.box('settings').get('setEqualizer', defaultValue: false) as bool;
  AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      content: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.equalizer),
              value: enabled,
              activeColor: Theme.of(context).colorScheme.secondary,
              onChanged: (value) {
                enabled = value;
                Hive.box('settings').put('setEqualizer', value);
                audioHandler.customAction('setEqualizer', {'value': value});
                setState(() {});
              },
            ),
            if (enabled)
              SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                child: EqualizerControls(
                  audioHandler: audioHandler,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EqualizerControls extends StatefulWidget {
  final AudioPlayerHandler audioHandler;
  const EqualizerControls({required this.audioHandler});
  @override
  _EqualizerControlsState createState() => _EqualizerControlsState();
}

class _EqualizerControlsState extends State<EqualizerControls> {
  Future<Map> getEq() async {
    final Map parameters =
        await widget.audioHandler.customAction('getEqualizerParams') as Map;
    return parameters;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map>(
      future: getEq(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox();
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox();
        return Row(
          children: [
            for (final band in data['bands'])
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: VerticalSlider(
                        min: data['minDecibels'] as double,
                        max: data['maxDecibels'] as double,
                        value: band['gain'] as double,
                        bandIndex: band['index'] as int,
                        audioHandler: widget.audioHandler,
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
  final double? value;
  final double? min;
  final double? max;
  final int bandIndex;
  final AudioPlayerHandler audioHandler;

  const VerticalSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.bandIndex,
    required this.audioHandler,
  });

  @override
  _VerticalSliderState createState() => _VerticalSliderState();
}

class _VerticalSliderState extends State<VerticalSlider> {
  double? sliderValue;

  void setGain(int bandIndex, double gain) {
    widget.audioHandler
        .customAction('setBandGain', {'band': bandIndex, 'gain': gain});
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
            activeColor: Theme.of(context).colorScheme.secondary,
            inactiveColor:
                Theme.of(context).colorScheme.secondary.withOpacity(0.4),
            value: sliderValue ?? widget.value!,
            min: widget.min!,
            max: widget.max!,
            onChanged: (double newValue) {
              setState(() {
                sliderValue = newValue;
                setGain(widget.bandIndex, newValue);
              });
            },
          ),
        ),
      ),
    );
  }
}
