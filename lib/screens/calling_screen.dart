import 'package:chatapp/config.dart';
import 'package:chatapp/models/friend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO show Socket;

class CallingScreen extends StatefulWidget {
  const CallingScreen({
    super.key,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  late IO.Socket socket;
  late Friend friend;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final Map<String, dynamic> _config = {
    'iceServers': [
      {'urls': 'stun:${Config.coturn}'},
      // {'urls': 'stun:94.141.221.233:3478'}, // Add regular STUN
      // {
      //   "urls": "turn:94.141.221.233:3478", // Add regular TURN
      //   'username': Config.turnUsername,
      //   'credential': Config.turnPassword
      // },
      // {
      //   "urls": "turns:${Config.coturn}", // Keep secure TURN
      //   'username': Config.turnUsername,
      //   'credential': Config.turnPassword
      // }
    ],
    'iceTransportPolicy': 'all', // or 'relay' to force TURN
  };

  @override
  void initState() {
    super.initState();
    GetIt getIt = GetIt.instance;
    friend = getIt<Friend>(instanceName: "currentFriend");
    socket = getIt<IO.Socket>();

    _addSocketListeners();
  }

  void _addSocketListeners() {
    socket.on("answer", (data) async {
      if (_pc != null) {
        print("I got the answer");
        RTCSessionDescription answer =
            RTCSessionDescription(data["sdp"], data["type"]);
        await _pc!.setRemoteDescription(answer);
      }
    });

    socket.on("offer", (data) async {
      print("I got an offer");
      await _initializePeerConnection();

      RTCSessionDescription offer =
          RTCSessionDescription(data["sdp"], data["type"]);

      await _pc!.setRemoteDescription(offer);
      RTCSessionDescription answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);

      socket.emit("answer", {
        "uuid": friend.uuid,
        "sdp": answer.sdp,
        "type": answer.type,
      });
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
        print("Added remote ICE candidate");
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
        print("Local audio tracks: ($isEnabled)");
      } else {
        print("Local audio stream is null or has no audio tracks.");
      }
    } else {
      print("Microphone permission not granted");
      return;
    }

    _pc = await createPeerConnection(_config);
    print("Peer Connection Created");

    _pc!.onIceCandidate = (RTCIceCandidate candidate) {
      print("ICE Candidate generated: ${candidate.candidate}");
      socket.emit("candidate", {
        "uuid": friend.uuid,
        "candidate": candidate.toMap(),
      });
    };

    _pc!.onConnectionState = (RTCPeerConnectionState state) {
      print("Connection State: $state");
    };

    _pc!.onTrack = (RTCTrackEvent event) {
      print("REMOTE TRACK RECEIVED! Kind: ${event.track.kind}");
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
    print("Local tracks added to the peer connection");
  }

  // This is the clean, standard function for making a call.
  Future<void> _startCall() async {
    await _initializePeerConnection();

    try {
      print("CALLER: Preparing to create offer...");
      RTCSessionDescription offer = await _pc!.createOffer({
        'mandatory': {
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': false,
        },
        'optional': [],
      });
      print("CALLER: Offer created successfully.");

      print("CALLER: Preparing to set local description...");
      await _pc!.setLocalDescription(offer);
      print("CALLER: Local description set successfully.");

      print("CALLER: Preparing to emit offer to server...");
      socket.emit("offer", {
        "uuid": friend.uuid,
        "sdp": offer.sdp,
        "type": offer.type,
      });
      print("CALLER: Offer emitted to server.");
    } catch (e) {
      print("CALLER: An error occurred during _startCall: $e");
    }
  }

  void _closeTheCall() {
    if (_pc != null) {
      _pc!.close();
      _pc = null;
    }
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      _localStream!.dispose();
      _localStream = null;
    }
    if (_remoteStream != null) {
      _remoteStream!.getTracks().forEach((track) => track.stop());
      _remoteStream!.dispose();
      _remoteStream = null;
    }
    socket.off('offer');
    socket.off('answer');
    socket.off('candidate');
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
              friend.friendName,
              style: TextStyle(color: Colors.white, fontSize: 32),
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
                    Navigator.pop(context);
                  },
                  elevation: 2.0,
                  fillColor: Colors.red,
                  shape: const CircleBorder(),
                  constraints:
                      const BoxConstraints.tightFor(width: 56.0, height: 56.0),
                  child: const Icon(Icons.call_end,
                      color: Colors.white, size: 32.0),
                ),
                SizedBox(width: 50),
                RawMaterialButton(
                  onPressed: _startCall,
                  elevation: 2.0,
                  fillColor: Colors.green,
                  shape: const CircleBorder(),
                  constraints:
                      const BoxConstraints.tightFor(width: 56.0, height: 56.0),
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

// import 'package:chatapp/config.dart';
// import 'package:chatapp/models/friend.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:get_it/get_it.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO show Socket;

// class CallingScreen extends StatefulWidget {
//   const CallingScreen({
//     super.key,
//   });

//   @override
//   State<CallingScreen> createState() => _CallingScreenState();
// }

// class _CallingScreenState extends State<CallingScreen> {
//   late IO.Socket socket;
//   late Friend friend;

//   RTCPeerConnection? _pc;
//   MediaStream? _localStream;
//   MediaStream? _remoteStream;
//   final Map<String, dynamic> _config = {
//     'iceServers': [
//       {'urls': 'stun:${Config.coturn}'},
//       {
//         "urls": "turns:${Config.coturn}",
//         'username': Config.turnUsername,
//         'credential': Config.turnPassword
//       }
//     ],
//   };
// // Helper function to modify SDP to work with emulators
//   RTCSessionDescription _forceEmulatorCompatibility(RTCSessionDescription sdp) {
//     var sdpString = sdp.sdp!;
//     print("Original SDP: $sdpString");
//     var newSdp = sdpString.replaceAll('opus/48000', 'opus/16000');
//     print("Modified SDP: $newSdp"); // Good for debugging
//     return RTCSessionDescription(newSdp, sdp.type);
//   }

//   @override
//   void initState() {
//     super.initState();
//     GetIt getIt = GetIt.instance;
//     friend = getIt<Friend>(instanceName: "currentFriend");
//     socket = getIt<IO.Socket>();

//     _addSocketListeners();
//   }

//   void _addSocketListeners() {
//     socket.on("answer", (data) async {
//       if (_pc != null) {
//         print("I got the answer");
//         RTCSessionDescription answer =
//             RTCSessionDescription(data["sdp"], data["type"]);
//         await _pc!.setRemoteDescription(answer);
//       }
//     });

//     socket.on("offer", (data) async {
//       print("I got an offer");
//       await _initializePeerConnection();

//       RTCSessionDescription offer =
//           RTCSessionDescription(data["sdp"], data["type"]);

//       await _pc!.setRemoteDescription(offer);
//       RTCSessionDescription answer = await _pc!.createAnswer();
//       await _pc!.setLocalDescription(answer);

//       socket.emit("answer", {
//         "uuid": friend.uuid,
//         "sdp": answer.sdp,
//         "type": answer.type,
//       });
//     });

//     socket.on("candidate", (data) async {
//       if (_pc != null) {
//         var candidateMap = data['candidate'];
//         var candidate = RTCIceCandidate(
//           candidateMap['candidate'],
//           candidateMap['sdpMid'],
//           candidateMap['sdpMLineIndex'],
//         );
//         await _pc!.addCandidate(candidate);
//         print("Added remote ICE candidate");
//       }
//     });
//   }

//   // This is our new unified initialization function
//   Future<void> _initializePeerConnection() async {
//     // 1. Get Microphone Permissions and Local Audio Stream
//     if (await Permission.microphone.request().isGranted) {
//       _localStream = await navigator.mediaDevices.getUserMedia({
//         "audio": {
//           'echoCancellation': true, // Standard echo cancellation
//           'noiseSuppression': true,
//         },
//         "video": false
//       });
//       if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
//         bool isEnabled = _localStream!.getAudioTracks()[0].enabled;
//         print(
//             "Local audio tracks: ($isEnabled)"); // This will now print on both devices
//       } else {
//         print("Local audio stream is null or has no audio tracks.");
//       }
//     } else {
//       print("Microphone permission not granted");
//       return;
//     }

//     _pc = await createPeerConnection(_config);
//     print("Peer Connection Created");

//     // 3. Add all the essential event handlers
//     _pc!.onIceCandidate = (RTCIceCandidate candidate) {
//       print("ICE Candidate generated: ${candidate.candidate}");
//       socket.emit("candidate", {
//         "uuid": friend.uuid,
//         "candidate": candidate.toMap(),
//       });
//     };

//     _pc!.onConnectionState = (RTCPeerConnectionState state) {
//       print("Connection State: $state");
//       // You can add logic here to handle disconnection, failure, etc.
//     };

//     // THIS IS THE CRUCIAL PART THAT WAS MISSING FOR THE CALLEE

//     _pc!.onTrack = (RTCTrackEvent event) {
//       print("REMOTE TRACK RECEIVED! Kind: ${event.track.kind}");

//       if (event.track.kind == 'audio' && event.streams.isNotEmpty) {
//         // THIS IS THE CORRECTED DEBUG LOG. We use event.track.enabled
//         print(
//             "Assigning remote stream. Track is enabled: ${event.track.enabled}, Audio Tracks in Stream: ${event.streams[0].getAudioTracks().length}");

//         // No changes below this line
//         setState(() {
//           _remoteStream = event.streams[0];
//         });

//         // This will now execute without any errors.
//         Helper.setSpeakerphoneOn(true);
//       }
//     };
//     // 4. Add the local stream tracks to the connection
//     _localStream!.getTracks().forEach((track) {
//       _pc!.addTrack(track, _localStream!);
//     });
//     print("Local tracks added to the peer connection");
//   }

//   // This function is now simplified for the CALLER
//   Future<void> _startCall() async {
//     // Initialize the peer connection as a caller
//     await _initializePeerConnection();

//     try {
//       print("CALLER: Preparing to create offer...");
//       RTCSessionDescription offer = await _pc!.createOffer({
//         'mandatory': {
//           'OfferToReceiveAudio': true,
//           'OfferToReceiveVideo': false,
//         },
//         'optional': [],
//       });
//       print("CALLER: Offer created successfully.");
//       // --- START: APPLY THE WORKAROUND ---
//       print("CALLER: Applying emulator compatibility workaround...");
//       var modifiedOffer = _forceEmulatorCompatibility(offer);
//       // --- END: APPLY THE WORKAROUND ---
//       print("CALLER: Preparing to set local description...");
//       await _pc!.setLocalDescription(modifiedOffer);
//       print("CALLER: Local description set successfully.");

//       print("CALLER: Preparing to emit offer to server...");
//       socket.emit("offer", {
//         "uuid": friend.uuid,
//         "sdp": modifiedOffer.sdp,
//         "type": modifiedOffer.type,
//       });
//       print("CALLER: Offer emitted to server.");
//     } catch (e) {
//       print("CALLER: An error occurred during _startCall: $e");
//     }
//   }

//   void _closeTheCall() {
//     if (_pc != null) {
//       _pc!.close();
//       _pc = null;
//     }
//     if (_localStream != null) {
//       _localStream!.getTracks().forEach((track) => track.stop());
//       _localStream!.dispose();
//       _localStream = null;
//     }
//     if (_remoteStream != null) {
//       _remoteStream!.getTracks().forEach((track) => track.stop());
//       _remoteStream!.dispose();
//       _remoteStream = null;
//     }
//     // It's better to remove specific listeners rather than all of them
//     // if the socket is shared across the app.
//     socket.off('offer');
//     socket.off('answer');
//     socket.off('candidate');
//   }

//   @override
//   void dispose() {
//     _closeTheCall();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               friend.friendName,
//               style: TextStyle(color: Colors.white, fontSize: 32),
//             ),
//             SizedBox(height: 20),
//             CircleAvatar(
//               backgroundColor: Colors.grey,
//               backgroundImage: AssetImage("assets/images/avatar.png"),
//               radius: 175,
//             ),
//             SizedBox(height: 25),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 RawMaterialButton(
//                   onPressed: () {
//                     _closeTheCall();
//                     Navigator.pop(context);
//                   },
//                   elevation: 2.0,
//                   fillColor: Colors.red,
//                   shape: const CircleBorder(),
//                   constraints:
//                       const BoxConstraints.tightFor(width: 56.0, height: 56.0),
//                   child: const Icon(Icons.call_end,
//                       color: Colors.white, size: 32.0),
//                 ),
//                 SizedBox(width: 50),
//                 RawMaterialButton(
//                   onPressed: _startCall, // Use the new simplified function
//                   elevation: 2.0,
//                   fillColor: Colors.green,
//                   shape: const CircleBorder(),
//                   constraints:
//                       const BoxConstraints.tightFor(width: 56.0, height: 56.0),
//                   child:
//                       const Icon(Icons.call, color: Colors.white, size: 32.0),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
