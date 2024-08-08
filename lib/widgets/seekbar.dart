import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this for HapticFeedback
import 'package:just_audio/just_audio.dart';
import 'package:music_player_3/widgets/themenotifier.dart';
import 'package:provider/provider.dart';

class Seekbar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangedEnd;

  const Seekbar({
    super.key,
    required this.position,
    required this.duration,
    this.onChanged,
    this.onChangedEnd,
  });

  @override
  State<Seekbar> createState() => _SeekbarState();
}

class _SeekbarState extends State<Seekbar> {
  late AudioPlayer _audioPlayer;
  double? dragValue;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.durationStream.listen((duration) {
      setState(() {});
    });
    _audioPlayer.positionStream.listen((position) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) {
      return '--:--';
    } else {
      String minutes = duration.inMinutes.toString().padLeft(1, '0');
      String seconds =
          (duration.inSeconds.remainder(60)).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    double position = widget.position.inMilliseconds.toDouble();
    double duration = widget.duration.inMilliseconds.toDouble();
    final globalThemeColor = Provider.of<ThemeNotifier>(context).themeColor;
    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
        left: 15,
        right: 15,
      ), // Individual padding
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(
                disabledThumbRadius: 8,
                enabledThumbRadius: 6,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 10,
              ),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: globalThemeColor,
              overlayColor: Colors.white,
            ),
            child: Slider(
              min: 0.0,
              max: duration,
              value: min(dragValue ?? position, duration),
              onChanged: (value) {
                setState(() {
                  dragValue = value;
                  HapticFeedback
                      .selectionClick(); // Add subtle haptic feedback while dragging
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(Duration(milliseconds: value.round()));
                }
              },
              onChangeEnd: (value) {
                _audioPlayer.seek(Duration(milliseconds: value.round()));
                if (widget.onChangedEnd != null) {
                  widget.onChangedEnd!(Duration(milliseconds: value.round()));
                }
                setState(() {
                  dragValue = null;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 10,
            ), // Adjust vertical spacing
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(widget.position)),
                Text(_formatDuration(widget.duration)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
