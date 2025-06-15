import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:chatapp/models/message.dart';
import 'package:flutter/material.dart';

class AudioMessagePlayer extends StatefulWidget {
  const AudioMessagePlayer({super.key, required this.assetPath});
  final String assetPath;
  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  late Message msg;
  AudioPlayer player = AudioPlayer();
  Duration _maxDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  double speed = 1.0;
  String fileData = "";
  bool _isPlaying = false;
  late String assetPath;
  late StreamSubscription<void> _onPlayerCompleteSub;
  late StreamSubscription<Duration> _onDurationChangedSub;
  late StreamSubscription<Duration> _onPositionChangedSub;
  @override
  void initState() {
    assetPath = widget.assetPath;
    initAudioPlayer();
    getFileData();
    super.initState();
  }

  void initAudioPlayer() async {
    player.setSource(DeviceFileSource(assetPath));

    _onPlayerCompleteSub = player.onPlayerComplete.listen((_) async {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
      player.setSource(DeviceFileSource(assetPath));
      await player.seek(Duration.zero);
    });

    _onDurationChangedSub = player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() {
        _maxDuration = d;
      });
    });

    _onPositionChangedSub = player.onPositionChanged.listen((event) {
      if (!mounted) return;
      setState(() {
        _currentPosition = event;
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    // Cancel subscriptions
    _onPlayerCompleteSub.cancel();
    _onDurationChangedSub.cancel();
    _onPositionChangedSub.cancel();
    player.dispose();
    super.dispose();
  }

  // @override
  // void dispose() {
  //   player.dispose();
  //   super.dispose();
  // }

  // void initAudioPlayer() async {
  //   player.setSource(DeviceFileSource(assetPath));

  //   player.onPlayerComplete.listen((_) async {
  //     setState(() {
  //       _isPlaying = false;
  //       _currentPosition = Duration.zero;
  //     });
  //     player.setSource(DeviceFileSource(assetPath));
  //     await player.seek(Duration.zero);
  //   });

  //   player.onDurationChanged.listen((d) {
  //     setState(() {
  //       _maxDuration = d;
  //     });
  //   });
  //   player.onPositionChanged.listen((event) {
  //     setState(() {
  //       _currentPosition = event;
  //     });
  //   });
  //   setState(() {});
  // }

  Future<void> getFileData() async {
    final file = File(assetPath);

    final stats = await file.stat();
    setState(() {
      fileData = "${(stats.size / 1024).toStringAsFixed(1)} KB";
    });
  }

  Future<void> _playSound(String assetPath) async {
    if (!_isPlaying) {
      setState(() {
        _isPlaying = true;
      });
      await player.resume();
    } else if (_isPlaying) {
      setState(() {
        _isPlaying = false;
      });
      await player.pause();
    }
  }

  String formatAudioDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  Widget iconChanger() {
    if (_isPlaying == true) {
      return Icon(
        Icons.pause,
        size: 28, // smaller icon
      );
    } else {
      return Icon(
        Icons.play_arrow,
        color: Colors.green,
        size: 28, // smaller icon
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // shrink to fit content
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  padding: EdgeInsets.zero, // no extra padding
                  constraints: BoxConstraints(), // minimal constraints
                  visualDensity: VisualDensity.compact, // less space
                  onPressed: () async {
                    await _playSound(assetPath);
                  },
                  icon: iconChanger(),
                ),
                SizedBox(
                  width: constraints.maxWidth * 0.75,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2, // thinner slider
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                      // You can tweak more if needed
                    ),
                    child: Slider(
                      activeColor: Colors.green,
                      value: _currentPosition.inMilliseconds
                          .clamp(0, _maxDuration.inMilliseconds)
                          .toDouble(),
                      min: 0.0,
                      max: _maxDuration.inMilliseconds.toDouble(),
                      onChanged: (val) async {
                        await player.seek(Duration(milliseconds: val.toInt()));
                        setState(() {
                          _currentPosition = Duration(
                            milliseconds: val.toInt(),
                          );
                        });
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Use a minimal-height Row with tight padding
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                fileData,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.0,
                  color: const Color.fromARGB(255, 134, 35, 35),
                ), // smaller text
              ),
              Text(
                formatAudioDuration(_maxDuration),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.0,
                  color: const Color.fromARGB(255, 134, 35, 35),
                ),
              ), // smaller text),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.all(6), // minimal padding
                  minimumSize: Size(36, 38), // small button
                  shape: CircleBorder(),
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap, // shrink tap target
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  setState(() {
                    speed >= 2.0 ? speed = 1 : speed += 0.5;
                  });
                  await player.setPlaybackRate(speed);
                },
                child: Text(
                  "${speed}X",
                  style: TextStyle(fontSize: 10, height: 1.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
