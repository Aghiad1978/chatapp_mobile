import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:chatapp/config.dart';
import 'package:chatapp/main.dart';
import 'package:chatapp/models/friend.dart';
import 'package:chatapp/models/friend_table.dart';
import 'package:chatapp/models/message_table.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/providers/connectivity_provider.dart';
import 'package:chatapp/providers/counter_provider.dart';
import 'package:chatapp/providers/last_message_provider.dart';
import 'package:chatapp/providers/message_provider.dart';
import 'package:chatapp/screens/calling_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketLogic {
  late IO.Socket _socket;
  final getIt = GetIt.instance;
  late String uuid;
  static late String? friendUuid;
  AudioPlayer audioPlayer = AudioPlayer();

  late ConnectivityProvider connectivityProvider;
  static late MessageProvider messageProvider;
  static late LastMessageProvider lastMessageProvider;
  static late CounterProvider counterProvider;
  static final SocketLogic _instance = SocketLogic._internal();
  final StreamController<Map<String, dynamic>> _friendStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get friendStatusStream =>
      _friendStatusController.stream;

  factory SocketLogic() {
    return _instance;
  }
  static void setFriendUuid(String friendUuid) {
    SocketLogic.friendUuid = friendUuid;
  }

  static void setMessageProvider(MessageProvider provider) {
    messageProvider = provider;
  }

  static void setLMessageProvider(LastMessageProvider provider) {
    lastMessageProvider = provider;
  }

  static void setCounterProvider(CounterProvider provider) {
    counterProvider = provider;
  }

  void _playNotificationSound() {
    audioPlayer.play(AssetSource("sound/notification.mp3"), volume: 1.0);
  }

  SocketLogic._internal() {
    _socket = IO.io(
      Config.listenningIP,
      IO.OptionBuilder()
          .setTransports(["websocket"]) // Use WebSocket transport
          .disableAutoConnect() // Disable auto-connect to control it manually
          .build(),
    );
    uuid = getIt<String>(instanceName: "uuid");

    connectivityProvider = getIt<ConnectivityProvider>();

    _socket.connect();
    _socket.onConnect((_) {
      connectivityProvider.setOnline(true);
      socket.emit("register-user", uuid);
      messageProvider.sendPendingMessages();
      messageProvider.getMessagesFromServer();
    });
    _socket.on("call-request", (data) async {
      print("GOT the call request");
      _socket.emit("call-request-received", data);
      Friend? friend = await FriendTable.getFriendFromUuid(data["from"]);
      if (friend != null) {
        navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (context) => CallingScreen(
                  friend: friend,
                  uuid: uuid,
                )));
      } else {
        Friend friend = Friend(
            friendName: "unKnown",
            email: "unknown",
            mobile: "",
            uuid: data["from"]);
        navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (context) => CallingScreen(
                  friend: friend,
                  uuid: uuid,
                )));
      }
    });
    _socket.onDisconnect((_) {
      connectivityProvider.setOnline(false);
    });
    _socket.on("message", (message) {
      Message msg = Message.fromMapToMessage(message);
      messageProvider.incomingMessage(msg);
      _playNotificationSound();
    });
    _socket.on("received", (msgid) async {
      await MessageTable.updateMessageIntoReceived(msgid);
      messageProvider.updateMessageStatus(msgid, "received");
    });

    _socket.on("read", (msgid) async {
      await MessageTable.updateMessageIntoRead(msgid);
      messageProvider.updateMessageStatus(msgid, "read");
    });
    _socket.on("received-server", (msgid) async {
      messageProvider.deletePendingMessage(msgid);
    });
    socket.on("status", (data) {
      _friendStatusController.add(data);
    });
    _socket.on("checkMsgStatus", (result) async {
      if (result["result"] == 3) {
        await MessageTable.updateMessageIntoReceived(result["msgid"]);
        messageProvider.updateMessageStatus(result["msgid"], "received");
        await MessageTable.updateMessageIntoRead(result["msgid"]);
        messageProvider.updateMessageStatus(result["msgid"], "read");
        return;
      } else if (result["result"] == 1) {
        await MessageTable.updateMessageIntoReceived(result["msgid"]);
        messageProvider.updateMessageStatus(result["msgid"], "received");
      } else if (result["result"] == 2) {
        await MessageTable.updateMessageIntoRead(result["msgid"]);
        messageProvider.updateMessageStatus(result["msgid"], "read");
      }
    });
  }
  bool getOnlineStatus() {
    return connectivityProvider.isOnLine;
  }

  IO.Socket get socket => _socket;
}
