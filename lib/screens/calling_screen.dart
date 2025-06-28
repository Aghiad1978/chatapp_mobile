import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:chatapp/config.dart';
import 'package:chatapp/models/friend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO show Socket;

class CallingScreen extends StatefulWidget {
  CallingScreen(
      {super.key,
      required this.friend,
      required this.uuid,
      this.isCaller = false});
  final Friend friend;
  final String uuid;
  bool isCaller;
  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  late IO.Socket socket;
  String status = "";

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final AudioPlayer _player = AudioPlayer();

  final Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:${Config.coturn}'},
      //if i want to use not encrypted connection...
      // {'urls': 'stun:94.141.221.233:3478'}, // Add regular STUN
      // {
      //   "urls": "turn:94.141.221.233:3478", // Add regular TURN
      //   'username': Config.turnUsername,
      //   'credential': Config.turnPassword
      // },
      {
        "urls": "turns:${Config.coturn}", // Keep secure TURN
        'username': Config.turnUsername,
        'credential': Config.turnPassword
      }
    ],
    'iceTransportPolicy': 'all', // or 'relay' to force TURN
  };
  bool approved = false;

  @override
  void initState() {
    super.initState();
    GetIt getIt = GetIt.instance;

    socket = getIt<IO.Socket>();
    _player.setReleaseMode(ReleaseMode.loop);
    _addSocketListeners();
    if (widget.isCaller == true) {
      _startCall();
    }
  }

  void timer() {
    int minutes = 0;
    int seconds = 0;
    int hours = 0;
    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      seconds += 1;
      if (seconds == 60) {
        seconds = 0;
        minutes += 1;
      }
      if (minutes == 60) {
        minutes = 0;
        hours += 1;
      }
      setState(() {
        if (hours == 0) {
          if (seconds < 10 && minutes < 10) {
            status = "0$minutes:0$seconds";
          } else if (seconds < 10 && minutes > 10) {
            status = "$minutes:0$seconds";
          } else if (seconds > 10 && minutes < 10) {
            status = "0$minutes:$seconds";
          } else {
            status = "$minutes:$seconds";
          }
        } else {
          status = "$hours:$minutes:$seconds";
        }
      });
    });
  }

  void _addSocketListeners() {
    socket.on("answer", (data) async {
      if (_pc != null) {
        RTCSessionDescription answer =
            RTCSessionDescription(data["sdp"], data["type"]);
        await _pc!.setRemoteDescription(answer);
      }
    });

    socket.on("offer", (data) async {
      await _initializePeerConnection();

      RTCSessionDescription offer =
          RTCSessionDescription(data["sdp"], data["type"]);

      await _pc!.setRemoteDescription(offer);
      await _player.play(AssetSource("sound/ring.mp3"));
    });

    socket.on("candidate", (data) async {
      if (_pc != null) {
        var candidateMap = data['candidate'];
        var candidate = RTCIceCandidate(
          candidateMap['candidate'],
          candidateMap['sdpMid'],
          candidateMap['sdpMLineIndex'],
        );
        await _pc!.addCandidate(candidate);
      }
    });
    socket.on("close-call", (_) {
      _closeTheCall();
    });
    socket.on("call-request-received", (data) async {
      if (data["to"] == widget.friend.uuid) {
        await _initializePeerConnection();
        try {
          RTCSessionDescription offer = await _pc!.createOffer({
            'mandatory': {
              'OfferToReceiveAudio': true,
              'OfferToReceiveVideo': false,
            },
            'optional': [],
          });
          await _pc!.setLocalDescription(offer);
          await Future.delayed(Duration(seconds: 2));
          socket.emit("offer", {
            "uuid": widget.friend.uuid,
            "sdp": offer.sdp,
            "type": offer.type,
          });
          setState(() {
            status = "Ringing..";
          });
        } catch (e) {
          print("CALLER: An error occurred during _startCall: $e");
        }
      }
    });
  }

  Future<void> _initializePeerConnection() async {
    if (await Permission.microphone.request().isGranted) {
      _localStream = await navigator.mediaDevices.getUserMedia({
        "audio": {
          'echoCancellation': true,
          'noiseSuppression': true,
        },
        "video": false
      });
      if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
        bool isEnabled = _localStream!.getAudioTracks()[0].enabled;
      } else {
        print("Local audio stream is null or has no audio tracks.");
      }
    } else {
      print("Microphone permission not granted");
      return;
    }

    _pc = await createPeerConnection(_config);

    _pc!.onIceCandidate = (RTCIceCandidate candidate) {
      socket.emit("candidate", {
        "uuid": widget.friend.uuid,
        "candidate": candidate.toMap(),
      });
    };

    _pc!.onConnectionState = (RTCPeerConnectionState state) async {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Connection started!!!")));
        timer();
      }
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Connection Closed!!!")));
      }
    };

    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'audio' && event.streams.isNotEmpty) {
        setState(() {
          _remoteStream = event.streams[0];
        });
        Helper.setSpeakerphoneOn(true);
      }
    };
    _localStream!.getTracks().forEach((track) {
      _pc!.addTrack(track, _localStream!);
    });
  }

  Future<void> _startCall() async {
    setState(() {
      status = "Calling";
    });
    socket
        .emit("call-request", {"to": widget.friend.uuid, "from": widget.uuid});
  }

  void _closeTheCall() async {
    if (_pc != null) {
      await _pc!.close();
      _pc = null;
      socket.off('offer');
      socket.off('answer');
      socket.off('candidate');
      socket.off('close-call');
      socket.off('call-request-received');
    }
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      await _localStream!.dispose();
      _localStream = null;
    }
    if (_remoteStream != null) {
      _remoteStream!.getTracks().forEach((track) => track.stop());
      await _remoteStream!.dispose();
      _remoteStream = null;
    }
    _player.dispose();
    socket.emit("close-call", widget.friend.uuid);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _closeTheCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.friend.friendName,
              style: TextStyle(color: Colors.white, fontSize: 32),
            ),
            SizedBox(height: 20),
            Text(
              status,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 20),
            CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: AssetImage("assets/images/avatar.png"),
              radius: 175,
            ),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RawMaterialButton(
                  onPressed: () {
                    _closeTheCall();
                  },
                  elevation: 2.0,
                  fillColor: Colors.red,
                  shape: const CircleBorder(),
                  constraints:
                      const BoxConstraints.tightFor(width: 56.0, height: 56.0),
                  child: const Icon(Icons.call_end,
                      color: Colors.white, size: 32.0),
                ),
                if (widget.isCaller == false) SizedBox(width: 50),
                if (widget.isCaller == false)
                  RawMaterialButton(
                    onPressed: () async {
                      await _player.stop();
                      RTCSessionDescription answer = await _pc!.createAnswer();
                      await _pc!.setLocalDescription(answer);
                      socket.emit("answer", {
                        "uuid": widget.friend.uuid,
                        "sdp": answer.sdp,
                        "type": answer.type,
                      });
                    },
                    elevation: 2.0,
                    fillColor: Colors.green,
                    shape: const CircleBorder(),
                    constraints: const BoxConstraints.tightFor(
                        width: 56.0, height: 56.0),
                    child:
                        const Icon(Icons.call, color: Colors.white, size: 32.0),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
