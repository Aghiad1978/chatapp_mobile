import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/logic/socket_logic.dart';
import 'package:chatapp/providers/message_provider.dart';
import 'package:chatapp/requests/files_uploader_downloader.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class AudioRecordScreen extends StatefulWidget {
  const AudioRecordScreen({super.key});

  @override
  State<AudioRecordScreen> createState() => _AudioRecordScreenState();
}

class _AudioRecordScreenState extends State<AudioRecordScreen> {
  @override
  bool _isRecording = false;
  bool _isLoading = false;
  double timerScreenVariable = 0.0;
  double size = 0.0;
  bool _isPlaying = false;
  bool fileExisted = false;
  GetIt getIt = GetIt.instance;
  final _record = AudioRecorder();
  final _player = AudioPlayer();
  late MessageProvider messageProvider;
  String? filePath;
  Timer? timer;
  void clean() {
    setState(() {
      _isRecording = false;
    });

    timer!.cancel();
  }

  @override
  void initState() {
    final getIt = GetIt.instance;
    messageProvider = getIt<MessageProvider>();
    super.initState();
  }

  void startRecording() async {
    if (_isPlaying) return;
    if (!_isRecording) {
      setState(() {
        _isRecording = true;
      });
      timerScreenVariable = 0.0;
      size = 0;
      if (fileExisted) {
        await File(filePath!).delete();
        fileExisted = false;
      }
      Directory dir = await getApplicationDocumentsDirectory();
      String filename = "${Uuid().v4()}.opus";
      filePath = "${dir.path}/$filename";
      timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) {
        setState(() {
          timerScreenVariable += 0.1;
        });
      });
      final config = RecordConfig(
        encoder: AudioEncoder.opus,
        bitRate: 10000,
        sampleRate: 8000,
        numChannels: 1,
      );
      if (await _record.hasPermission()) {
        await _record.start(config, path: filePath!);
        setState(() {
          fileExisted = true;
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("You don't have permission")));
        clean();
      }
    } else {
      await Future.delayed(Duration(milliseconds: 200));
      filePath = await _record.stop();
      final recordFileStats = await File(filePath!).stat();
      size = recordFileStats.size / 1024;
      setState(() {
        size;
      });

      clean();
    }
  }

  void playSound() async {
    if (_isRecording) return;
    _player.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
      });
    });
    if (!fileExisted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Record a file first!!",
            style: TextStyle(color: Colors.deepOrange),
          ),
          backgroundColor: AppColors.appBarColor,
        ),
      );
    } else {
      if (_isPlaying) {
        await _player.stop();
        setState(() {
          _isPlaying = false;
        });
      } else {
        setState(() {
          _isPlaying = true;
        });
        await _player.play(DeviceFileSource(filePath!), volume: 1.0);
      }
    }
  }

  void sendFile() async {
    if (!fileExisted || _isRecording || _isPlaying) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    if (getIt<SocketLogic>().getOnlineStatus()) {
      await FilesUploaderDownloader.uploadMediaIntoServer(
        filePath!,
        "sound",
      );
    }
    messageProvider.sendMessage(filePath!, "sound");
    setState(() {
      _isLoading = false;
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _record.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text("seconds: ${timerScreenVariable.toStringAsFixed(1)}"),
              Text("size: ${size.toStringAsFixed(1)} KB"),
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  playSound();
                },
                icon: _isPlaying
                    ? Icon(Icons.stop, size: 45)
                    : Icon(Icons.play_arrow, size: 45, color: Colors.green),
              ),
              IconButton(
                onPressed: () {
                  startRecording();
                },
                icon: _isRecording
                    ? Icon(Icons.stop, size: 45, color: Colors.black)
                    : Icon(size: 35, Icons.circle, color: Colors.red),
              ),
              FilledButton(
                onPressed: () {
                  sendFile();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orangeColor,
                ),
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text("Send"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
