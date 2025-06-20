import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:chatapp/config.dart';
import 'package:chatapp/models/message_table.dart';
import 'package:chatapp/models/friend.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/models/pending_message.dart';
import 'package:chatapp/models/pending_messages_table.dart';
import 'package:chatapp/providers/counter_provider.dart';
import 'package:chatapp/requests/files_uploader_downloader.dart';
import 'package:chatapp/services/secure_storage.dart';
import 'package:chatapp/logic/socket_logic.dart';
import 'package:chatapp/providers/last_message_provider.dart';
import 'package:chatapp/services/sharedpreferences_storage.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:uuid/uuid.dart';

class MessageProvider extends ChangeNotifier {
  List<Message> messages = [];
  bool shouldscrolltoBottom = false;
  final getIt = GetIt.instance;
  void _playNotificationSound() async {
    AudioPlayer player = AudioPlayer();
    await player.play(AssetSource("sound/notification.mp3"), volume: 1.0);
    player.onPlayerComplete.listen((event) {
      player.dispose();
    });
  }

  void _playSendSound() async {
    AudioPlayer player = AudioPlayer();
    await player.play(AssetSource("sound/send.mp3"), volume: 0.25);
    player.onPlayerComplete.listen((event) {
      player.dispose();
    });
  }

  Future<Message?> createMessageFromData(
    Friend friend,
    String message,
    String type,
    IO.Socket socket,
  ) async {
    socket.emit("datetime");
    final completer = Completer<Message?>();
    late Message? msg;
    socket.once("datetime", (data) async {
      try {
        String mobile = await SharedpreferencesStorage.getJustOne("mobile");
        DateTime createdAt = DateTime.parse(data);
        String senderUuid = getIt<String>(instanceName: "uuid");
        String receiverUuid = friend.uuid;
        String mobileNumber = mobile;
        msg = Message(
          senderUuid: senderUuid,
          senderName: "userName",
          senderMobile: mobileNumber,
          receiverUuid: receiverUuid,
          message: message,
          createdAt: createdAt.toUtc().toString(),
          msgid: Uuid().v4(),
          type: type,
        );
        completer.complete(msg);
      } catch (e) {
        print("ERROR createMessagefromData func chat_screen.dart $e");
        completer.complete(null);
      }
    });
    return await completer.future;
  }

  Future<void> getMessagesFromInternalDB(int limit, int offset) async {
    Friend friend = getIt<Friend>(instanceName: "currentFriend");
    String uuid = getIt<String>(instanceName: "uuid");
    List<Message> fetchedMessages =
        await MessageTable.getPaginationMessagesFromInternalDB(
            friend.uuid, uuid, offset, limit);
    if (fetchedMessages.isNotEmpty) {
      IO.Socket socket = getIt<IO.Socket>();
      for (var msg in fetchedMessages) {
        bool containes = messages.any((message) => msg.msgid == message.msgid);
        if (containes) {
          continue;
        }
        if (msg.receiverUuid == uuid) {
          await MessageTable.updateMessageIntoReceived(msg.msgid);
          if (msg.received == false) {
            socket.emit("message-received",
                {"msgid": msg.msgid, "senderUuid": msg.senderUuid});
            msg.received = true;
          }
          if (msg.read == false && msg.received == true) {
            socket.emit("message-read",
                {"msgid": msg.msgid, "senderUuid": msg.senderUuid});
          }
          await MessageTable.updateMessageIntoRead(msg.msgid);
        }
      }
      messages = [...fetchedMessages, ...messages];
      final pendingMessages =
          await PendingMessagesTable.getPendingMessagesForUuid(friend.uuid);
      List<Message> addedPending = [];
      for (var pm in pendingMessages) {
        addedPending.add(PendingMessage.convertPendingMessageIntoMessage(pm));
      }
      messages = [...messages, ...addedPending];
      if (offset > 0) {
        shouldscrolltoBottom = false;
      } else {
        shouldscrolltoBottom = true;
      }
      notifyListeners();
    }
  }

  Future<void> checkMessagesStatusWithServer() async {
    Friend currentFriend = getIt<Friend>(instanceName: "currentFriend");
    String uuid = getIt<String>(instanceName: "uuid");
    IO.Socket socket = getIt<IO.Socket>();
    final fetchedMessages =
        await MessageTable.getAllMessagesFromInternalDBForSenderUuid(
            currentFriend.uuid, uuid);
    for (var msg in fetchedMessages) {
      if (msg.senderUuid == uuid &&
          (msg.read == false || msg.received == false)) {
        socket.emit(
          "checkMsgStatus",
          {"msgid": msg.msgid, "senderUuid": uuid},
        );
      }
    }
  }

  void updateMessageStatus(String msgid, String status) {
    bool updated = false;
    if (status == "read") {
      for (var i = 0; i < messages.length; i++) {
        if (messages[i].msgid == msgid) {
          messages[i].read = true;
          updated = true;
          break;
        }
      }
    } else if (status == "received") {
      for (var i = 0; i < messages.length; i++) {
        if (messages[i].msgid == msgid) {
          messages[i].received = true;
          updated = true;
          break;
        }
      }
    }
    if (updated) {
      messages = List<Message>.from(messages);
      shouldscrolltoBottom = true;
      notifyListeners();
    }
  }

  Future<void> incomingMessage(Message msg) async {
    await MessageTable.insertMessage(msg);
    String location = getIt<String>(instanceName: "location");
    final counterProvider = getIt<CounterProvider>();
    final lastMessageProvider = getIt<LastMessageProvider>();
    lastMessageProvider.incomingMessage(msg);
    counterProvider.incrementCounter(msg.senderUuid);
    IO.Socket socket = getIt<IO.Socket>();
    if (location == "chat") {
      counterProvider.clearCounter(msg.senderUuid);
      Friend friend = getIt<Friend>(instanceName: "currentFriend");
      if (friend.uuid == msg.senderUuid) {
        messages = [...messages, msg];
        await MessageTable.updateMessageIntoReceived(msg.msgid);
        socket.emit("message-received",
            ({"msgid": msg.msgid, "senderUuid": msg.senderUuid}));
        await MessageTable.updateMessageIntoRead(msg.msgid);
        socket.emit("message-read",
            ({"msgid": msg.msgid, "senderUuid": msg.senderUuid}));
        shouldscrolltoBottom = true;
        notifyListeners();
      } else {
        await MessageTable.updateMessageIntoReceived(msg.msgid);
        socket.emit("message-received",
            ({"msgid": msg.msgid, "senderUuid": msg.senderUuid}));
      }
    } else if (location == "main") {
      await MessageTable.updateMessageIntoReceived(msg.msgid);
      socket.emit("message-received",
          ({"msgid": msg.msgid, "senderUuid": msg.senderUuid}));
    }
  }

  Future<void> getMessagesFromServer() async {
    try {
      final socket = getIt<IO.Socket>();
      String location = getIt<String>(instanceName: "location");
      String uuid = getIt<String>(instanceName: "uuid");
      final String? jwta = await SecureStorage.container.readSecureStorage(
        "jwta",
      );
      if (jwta == null) {
        throw Exception("Null JWTA");
      }
      final url = Uri.parse("${Config.listenningIP}/api/v1/newMessages");
      final resp = await http.post(
        url,
        headers: {
          "content-type": "application/json",
          "authorization": "Bearer $jwta",
        },
        body: json.encode({"uuid": uuid}),
      );
      if (resp.statusCode == 200) {
        try {
          List<Map<String, dynamic>> unreadMessages =
              List<Map<String, dynamic>>.from(json.decode(resp.body));
          List<Message> newMessages = Message.messagesFromMap(unreadMessages);

          final lastMessageProvider = getIt<LastMessageProvider>();
          final counterProvider = getIt<CounterProvider>();
          for (Message msg in newMessages) {
            counterProvider.incrementCounter(msg.senderUuid);
            await MessageTable.insertMessage(msg);
            socket.emit("message-received", {
              "msgid": msg.msgid,
              "senderUuid": msg.senderUuid,
            });
            if (location == "chat") {
              try {
                Friend friend = getIt<Friend>(instanceName: "currentFriend");
                if (friend.uuid == msg.senderUuid) {
                  socket.emit("message-read",
                      {"msgid": msg.msgid, "senderUuid": msg.senderUuid});
                  counterProvider.clearCounter(msg.senderUuid);
                  messages.add(msg);
                }
              } catch (e) {
                print(
                    "ERROR:While getting messages from server messageProvider $e");
              }
            }
            await lastMessageProvider.incomingMessage(msg);
            _playNotificationSound();
            shouldscrolltoBottom = true;
            notifyListeners();
          }
        } catch (e) {
          print(
            "ERROR getUnreadMessagesfromservetr 43 get_messages_from_server.dart $e",
          );
          throw Exception(e.toString());
        }
      } else {
        print("ERROR while getting unread message");
        throw Exception("Error while getting unread messages");
      }
    } catch (e) {
      print("ERROR GetunreadMessagefromserver func 59 main_screen.dart $e");
      throw Exception(e.toString());
    }
  }

  Future<void> sendPendingMessages() async {
    final socket = getIt<IO.Socket>();
    String location = getIt<String>(instanceName: "location");
    //
    List<PendingMessage> pendingMessages =
        await PendingMessagesTable.getAllPendingMessages();
    if (pendingMessages.isEmpty) {
      return;
    }
    for (var pm in pendingMessages) {
      Message msg = PendingMessage.convertPendingMessageIntoMessage(pm);
      if (getIt<SocketLogic>().getOnlineStatus()) {
        msg.received = false;
        msg.read = false;
        msg.status = "";
        var data = Message.createMapFromMessage(msg);
        if (msg.type == "image" || msg.type == "sound") {
          await FilesUploaderDownloader.uploadMediaIntoServer(
              msg.message, msg.type);
          String fileName = msg.message.split("/").last;
          data["message"] = fileName;
        }
        socket.emit("message", jsonEncode(data));
        await MessageTable.insertMessage(msg);
        if (location == "chat") {
          Friend currentFriend = getIt<Friend>(instanceName: "currentFriend");
          if (msg.receiverUuid == currentFriend.uuid) {
            messages.removeWhere((message) => message.msgid == msg.msgid);
            messages = [...messages, msg];
            shouldscrolltoBottom = true;
            notifyListeners();
          }
        }
      }
    }
  }

  Future<void> deletePendingMessage(String msgid) async {
    await PendingMessagesTable.deletePendingMessage(msgid);
    print("Pending message $msgid deleted");
  }

  Future<void> sendMessage(String msgText, String type) async {
    Message? msg;
    try {
      final socket = getIt<IO.Socket>();
      final friend = getIt<Friend>(instanceName: "currentFriend");
      String uuid = getIt<String>(instanceName: "uuid");
      final lastMessageProvider = getIt<LastMessageProvider>();
      String myMobile = await SharedpreferencesStorage.getJustOne("mobile");
      if (msgText == "") {
        return;
      }
      _playSendSound();
      if (getIt<SocketLogic>().getOnlineStatus()) {
        if (type == "image" || type == "sound") {
          String sendPhotoFileName = msgText.split("/").last;
          msg = await createMessageFromData(
            friend,
            sendPhotoFileName,
            type,
            socket,
          );
        } else {
          msg = await createMessageFromData(
            friend,
            msgText,
            type,
            socket,
          );
        }
        if (msg != null) {
          msg.received = false;
          msg.read = false;
          var data = Message.createMapFromMessage(msg);
          socket.emit("message", jsonEncode(data));
          msg.message = msgText;
          await MessageTable.insertMessage(msg);
          msg.senderUuid = friend.uuid;
          await lastMessageProvider.inSendingMessage(msg);
          msg.senderUuid = getIt<String>(instanceName: "uuid");
          messages = [...messages, msg];
          shouldscrolltoBottom = true;
          notifyListeners();
        }
      }
      //TODO modify sending audio and images
      //sending message while offline
      else {
        PendingMessage pm = PendingMessage(
            msgText: msgText,
            msgID: Uuid().v4(),
            senderUuid: uuid,
            receiverUuid: friend.uuid,
            type: type,
            createdAt: DateTime.now().toString(),
            senderName: "senderName",
            senderMobile: myMobile);
        await PendingMessagesTable.insertPendingMessage(pm);
        Message msg = PendingMessage.convertPendingMessageIntoMessage(pm);
        msg.senderUuid = friend.uuid;
        await lastMessageProvider.inSendingMessage(msg);
        msg.senderUuid = getIt<String>(instanceName: "uuid");
        messages = [...messages, msg];
        notifyListeners();
      }
    } catch (e) {
      print("ERROR: sendingMessage UI message_provider $e");
    }
  }

  void clearMessages() {
    messages.clear();
    // notifyListeners();
  }
}
