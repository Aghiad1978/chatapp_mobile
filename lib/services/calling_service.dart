// import 'package:chatapp/config.dart';

import 'package:chatapp/config.dart';
import 'package:chatapp/models/friend.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class CallingService {
  final Friend friend;
  final String uuid;
  final bool isCaller;
  CallingService(
      {required this.friend, required this.uuid, required this.isCaller});

  static final Map<String, dynamic> _configuration = {
    "iceServers": [
      {"urls": "stun:${Config.coturn}"}
    ]
  };
  static RTCPeerConnection? _pc;
  static IO.Socket? socket;
  static final getIt = GetIt.instance;
  static final _localRenderrer = RTCVideoRenderer();
  static final _remoteRenderrer = RTCVideoRenderer();

  static Future<void> _initRenderrer() async {
    await _localRenderrer.initialize();
    await _remoteRenderrer.initialize();
  }

  void sendToPeer(String peerUuid, Map<String, dynamic> data) {
    socket = getIt<IO.Socket>();
    if (data["type"] == "candidate") {
      socket!.emit("candidate", {
        "uuid": peerUuid,
        "candidate": data["candidate"],
        "sdpMid": data["sdpMid"],
        "sdpMLineIndex": data["sdpMLineIndex"],
      });
    } else if (data["type"] == "offer") {
      socket!.emit("offer", {
        "uuid": peerUuid,
        "sdp": data["sdp"],
      });
    }
  }

  static Future<void> getCandidate() async {
    if (await Permission.microphone.request().isGranted) {
      print("Inside");
      try {
        _pc = await createPeerConnection(_configuration);
        _pc!.onIceCandidate = (RTCIceCandidate candidate) {
          print("ICE candidate ${candidate.candidate}");
        };
        // var offer = await _pc!.createOffer();
        // await _pc!.setLocalDescription(offer);
      } catch (e) {
        print("ERROR: $e");
      }
    } else {
      print("ERROR: audio permission is not granted");
    }
  }

  Future<void> startAudioCall() async {
    if (await Permission.microphone.request().isGranted) {
      final _localStream =
          await navigator.mediaDevices.getUserMedia({"audio": true});

      _localRenderrer.srcObject = _localStream;
      _pc = await createPeerConnection(_configuration);
      _localStream.getTracks().forEach((track) {
        _pc!.addTrack(track, _localStream);
      });
      _pc!.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate != null) {
          sendToPeer(friend.uuid, {
            "type": "candidate",
            "candidate": candidate.candidate,
            "sdpMid": candidate.sdpMid,
            "sdpMLineIndex": candidate.sdpMLineIndex
          });
        }
      };
      if (isCaller) {
        RTCSessionDescription offer = await _pc!.createOffer();
        await _pc!.setLocalDescription(offer);
        sendToPeer(friend.uuid, {
          "type": "offer",
          "sdp": offer.sdp,
        });
      }
    } else {
      print("Permission Not Granted");
    }
  }
}
