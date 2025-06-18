import 'package:chatapp/config.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallingService {
  static final Map<String, dynamic> _configuration = {
    "iceServers": [
      {"urls": "stun:${Config.coturn}"}
    ]
  };
  RTCPeerConnection? _pc;
  Future<void> testConnection() async {
    _pc = await createPeerConnection(_configuration);
  }
}
