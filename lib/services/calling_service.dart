// import 'package:chatapp/config.dart';
// import 'package:chatapp/logic/socket_logic.dart';
// import 'package:chatapp/models/friend.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:get_it/get_it.dart';
// import 'package:permission_handler/permission_handler.dart';

// class CallingService {
//   final Friend friend;
//   final bool isCaller;

//   // Instance fields
//   RTCPeerConnection? _pc;
//   final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
//   final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
//   final getIt = GetIt.instance;
//   MediaStream? _localStream;
//   bool _isInitialized = false;

//   static final Map<String, dynamic> _configuration = {
//     "iceServers": [
//       {"urls": "stun:${Config.coturn}"}
//     ],
//     "iceCandidatePoolSize": 10, // Limit candidates
//   };

//   CallingService({required this.friend, required this.isCaller});

//   // --- Register signaling handlers and initialize renderers
//   Future<void> init() async {
//     if (_isInitialized) return;

//     print("🔧 Registering call handlers for friend: ${friend.uuid}");

//     // Register signaling event handlers with SocketLogic FIRST
//     SocketLogic().registerCallHandlers(
//       onOffer: (data) async {
//         print("📞 Handler: Received offer");
//         await onReceiveOffer(data);
//       },
//       onAnswer: (data) async {
//         print("📞 Handler: Received answer");
//         await onReceiveAnswer(data);
//       },
//       onCandidate: (data) async {
//         print("📞 Handler: Received candidate");
//         await onReceiveCandidate(data);
//       },
//     );

//     await _localRenderer.initialize();
//     await _remoteRenderer.initialize();
//     _isInitialized = true;
//     print("🔧 CallingService initialized successfully");
//   }

//   // --- Setup local media stream
//   Future<void> _setupLocalMedia() async {
//     if (_localStream != null) {
//       print("⚠️ Local stream already exists, skipping setup");
//       return; // Prevent duplicate setup
//     }

//     print("🎤 Requesting microphone permission...");
//     if (!await Permission.microphone.request().isGranted) {
//       throw Exception("Microphone permission not granted");
//     }

//     print("🎤 Getting user media (audio only)...");
//     _localStream = await navigator.mediaDevices.getUserMedia({"audio": true});
//     _localRenderer.srcObject = _localStream;
//     print("✅ Local media stream setup complete");
//   }

//   // --- Create and configure peer connection
//   Future<void> _createPeerConnection() async {
//     if (_pc != null) {
//       print("⚠️ Peer connection already exists, skipping creation");
//       return; // Prevent duplicate creation
//     }

//     print("🔧 Creating peer connection...");
//     _pc = await createPeerConnection(_configuration);
//     print("✅ Peer connection created successfully");

//     // Add local stream to peer connection
//     if (_localStream != null) {
//       for (var track in _localStream!.getTracks()) {
//         await _pc!.addTrack(track, _localStream!);
//       }
//       print(
//           "📡 Added ${_localStream!.getTracks().length} local tracks to peer connection");
//     }

//     // Set up event handlers with detailed logging
//     _pc!.onTrack = (event) {
//       print("🎵 Received remote track: ${event.track.kind}");
//       if (event.streams.isNotEmpty) {
//         _remoteRenderer.srcObject = event.streams[0];
//         print("📺 Set remote stream to renderer");
//       }
//     };

//     _pc!.onConnectionState = (RTCPeerConnectionState state) {
//       print('🔗 PeerConnection state changed: $state');
//       switch (state) {
//         case RTCPeerConnectionState.RTCPeerConnectionStateNew:
//           print("📊 Connection state: NEW");
//           break;
//         case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
//           print("📊 Connection state: CONNECTING");
//           break;
//         case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
//           print("✅ Connection state: CONNECTED - Call established!");
//           break;
//         case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
//           print("⚠️ Connection state: DISCONNECTED");
//           break;
//         case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
//           print("❌ Connection state: FAILED");
//           break;
//         case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
//           print("🔒 Connection state: CLOSED");
//           break;
//       }
//     };

//     _pc!.onIceConnectionState = (RTCIceConnectionState state) {
//       print('🧊 ICE Connection state changed: $state');
//       switch (state) {
//         case RTCIceConnectionState.RTCIceConnectionStateNew:
//           print("🧊 ICE state: NEW");
//           break;
//         case RTCIceConnectionState.RTCIceConnectionStateChecking:
//           print("🧊 ICE state: CHECKING");
//           break;
//         case RTCIceConnectionState.RTCIceConnectionStateConnected:
//           print("✅ ICE state: CONNECTED");
//           break;
//         case RTCIceConnectionState.RTCIceConnectionStateCompleted:
//           print("✅ ICE state: COMPLETED");
//           break;
//         case RTCIceConnectionState.RTCIceConnectionStateFailed:
//           print("❌ ICE state: FAILED");
//           break;
//         case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
//           print("⚠️ ICE state: DISCONNECTED");
//           break;
//         case RTCIceConnectionState.RTCIceConnectionStateClosed:
//           print("🔒 ICE state: CLOSED");
//           break;
//         default:
//           print("Reached default");
//       }
//     };

//     _pc!.onIceGatheringState = (RTCIceGatheringState state) {
//       print('🧊 ICE Gathering state changed: $state');
//       switch (state) {
//         case RTCIceGatheringState.RTCIceGatheringStateNew:
//           print("🧊 ICE Gathering: NEW");
//           break;
//         case RTCIceGatheringState.RTCIceGatheringStateGathering:
//           print("🧊 ICE Gathering: GATHERING");
//           break;
//         case RTCIceGatheringState.RTCIceGatheringStateComplete:
//           print("✅ ICE Gathering: COMPLETE");
//           break;
//       }
//     };

//     _pc!.onSignalingState = (RTCSignalingState state) {
//       print('📡 Signaling state changed: $state');
//       switch (state) {
//         case RTCSignalingState.RTCSignalingStateStable:
//           print("📡 Signaling: STABLE");
//           break;
//         case RTCSignalingState.RTCSignalingStateHaveLocalOffer:
//           print("📡 Signaling: HAVE_LOCAL_OFFER");
//           break;
//         case RTCSignalingState.RTCSignalingStateHaveRemoteOffer:
//           print("📡 Signaling: HAVE_REMOTE_OFFER");
//           break;
//         case RTCSignalingState.RTCSignalingStateHaveLocalPrAnswer:
//           print("📡 Signaling: HAVE_LOCAL_PRANSWER");
//           break;
//         case RTCSignalingState.RTCSignalingStateHaveRemotePrAnswer:
//           print("📡 Signaling: HAVE_REMOTE_PRANSWER");
//           break;
//         case RTCSignalingState.RTCSignalingStateClosed:
//           print("📡 Signaling: CLOSED");
//           break;
//       }
//     };

//     _pc!.onIceCandidate = (RTCIceCandidate candidate) {
//       if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
//         print(
//             "🧊 Generated ICE candidate: ${candidate.candidate?.substring(0, 50)}...");
//         sendToPeer(friend.uuid, {
//           "type": "candidate",
//           "candidate": candidate.candidate,
//           "sdpMid": candidate.sdpMid,
//           "sdpMLineIndex": candidate.sdpMLineIndex
//         });
//       } else {
//         print("🧊 Received end-of-candidates signal");
//       }
//     };

//     print("🔧 All peer connection handlers set up");
//   }

//   // --- Handle incoming ICE candidate
//   Future<void> onReceiveCandidate(Map<String, dynamic> data) async {
//     print("🧊 Received ICE candidate from peer");
//     if (_pc == null) {
//       print("❌ PeerConnection not initialized when receiving candidate");
//       return;
//     }

//     try {
//       RTCIceCandidate candidate = RTCIceCandidate(
//         data['candidate'],
//         data['sdpMid'],
//         data['sdpMLineIndex'],
//       );
//       await _pc!.addCandidate(candidate);
//       print("✅ Added ICE candidate successfully");
//     } catch (e) {
//       print("❌ Error adding ICE candidate: $e");
//     }
//   }

//   // --- Handle incoming answer SDP
//   Future<void> onReceiveAnswer(Map<String, dynamic> data) async {
//     print("📞 Received answer from peer");
//     if (!isCaller || _pc == null) {
//       print("⚠️ Ignoring answer - not caller or no peer connection");
//       return;
//     }

//     try {
//       print("📞 Setting remote description (answer)...");
//       await _pc!
//           .setRemoteDescription(RTCSessionDescription(data['sdp'], 'answer'));
//       print("✅ Remote description (answer) set successfully");
//     } catch (e) {
//       print("❌ Error setting remote description (answer): $e");
//     }
//   }

//   // --- Handle incoming offer SDP and reply with answer
//   Future<void> onReceiveOffer(Map<String, dynamic> data) async {
//     print("📞 Received offer from peer");
//     if (isCaller) {
//       print("⚠️ Ignoring offer - I am the caller");
//       return;
//     }

//     try {
//       print("📞 Setting up media and peer connection for callee...");
//       // Setup media and peer connection for callee
//       await _setupLocalMedia();
//       await _createPeerConnection();

//       print("📞 Setting remote description (offer)...");
//       await _pc!
//           .setRemoteDescription(RTCSessionDescription(data["sdp"], "offer"));

//       print("📞 Creating answer...");
//       RTCSessionDescription answer = await _pc!.createAnswer();

//       print("📞 Setting local description (answer)...");
//       await _pc!.setLocalDescription(answer);

//       print("📞 Sending answer...");
//       sendToPeer(friend.uuid, {
//         'type': 'answer',
//         'sdp': answer.sdp,
//       });

//       print("✅ Answer sent successfully");
//     } catch (e) {
//       print("❌ Error handling offer: $e");
//     }
//   }

//   // --- Send signaling data to peer
//   void sendToPeer(String peerUuid, Map<String, dynamic> data) {
//     final socket = SocketLogic().socket;
//     if (!socket.connected) {
//       print("❌ Socket not connected, cannot send data");
//       return;
//     }

//     print("📤 Sending ${data['type']} to peer $peerUuid");

//     if (data["type"] == "candidate") {
//       socket.emit("candidate", {
//         "uuid": peerUuid,
//         "candidate": data["candidate"],
//         "sdpMid": data["sdpMid"],
//         "sdpMLineIndex": data["sdpMLineIndex"],
//       });
//     } else if (data["type"] == "offer") {
//       socket.emit("offer", {
//         "uuid": peerUuid,
//         "sdp": data["sdp"],
//       });
//     } else if (data["type"] == "answer") {
//       socket.emit("answer", {
//         "uuid": peerUuid,
//         "sdp": data["sdp"],
//       });
//     }
//   }

//   // --- Start audio call (for caller)
//   Future<void> startAudioCall() async {
//     try {
//       print("🚀 Starting audio call...");

//       // Setup media and peer connection for caller
//       await _setupLocalMedia();
//       await _createPeerConnection();

//       if (isCaller) {
//         print("📞 Creating offer...");
//         RTCSessionDescription offer = await _pc!.createOffer();
//         print("📞 Offer created, setting local description...");

//         await _pc!.setLocalDescription(offer);
//         print("📞 Local description set, sending offer...");

//         sendToPeer(friend.uuid, {
//           "type": "offer",
//           "sdp": offer.sdp,
//         });

//         print("✅ Offer sent successfully to ${friend.uuid}");
//       }
//     } catch (e) {
//       print("❌ Error starting audio call: $e");
//     }
//   }

//   // --- Clean up resources
//   Future<void> endCall() async {
//     try {
//       print("🔚 Ending call...");

//       // Stop local stream tracks
//       if (_localStream != null) {
//         _localStream!.getTracks().forEach((track) {
//           track.stop();
//         });
//         _localStream = null;
//         print("🛑 Local stream stopped");
//       }

//       // Close peer connection
//       await _pc?.close();
//       _pc = null;
//       print("🔒 Peer connection closed");

//       // Dispose renderers
//       await _localRenderer.dispose();
//       await _remoteRenderer.dispose();
//       print("🗑️ Renderers disposed");

//       _isInitialized = false;
//       print("✅ Call ended successfully");
//     } catch (e) {
//       print("❌ Error ending call: $e");
//     }
//   }

//   // --- Getters for renderers
//   RTCVideoRenderer get localRenderer => _localRenderer;
//   RTCVideoRenderer get remoteRenderer => _remoteRenderer;

//   // --- Getter for connection state (useful for UI)
//   RTCPeerConnectionState? get connectionState => _pc?.connectionState;
//   RTCIceConnectionState? get iceConnectionState => _pc?.iceConnectionState;
//   RTCSignalingState? get signalingState => _pc?.signalingState;

//   // --- Check if call is active
//   bool get isCallActive =>
//       _pc != null &&
//       (_pc!.connectionState ==
//               RTCPeerConnectionState.RTCPeerConnectionStateConnected ||
//           _pc!.connectionState ==
//               RTCPeerConnectionState.RTCPeerConnectionStateConnecting);
// }
