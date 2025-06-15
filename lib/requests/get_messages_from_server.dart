import 'dart:convert';

import 'package:chatapp/config.dart';
import 'package:chatapp/models/last_message_table.dart';
import 'package:chatapp/models/message_table.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/services/secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

Future<void> getMessagesFromServer(String uuid, IO.Socket? socket) async {
  try {
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
        List<Message> messages = Message.messagesFromMap(unreadMessages);

        await MessageTable.saveReceivedUnreadMessages(messages);
        for (Message msg in messages) {
          socket!.emit("message-received", {
            "msgid": msg.msgid,
            "senderUuid": msg.senderUuid,
          });
          await LastMessageTable.insertOrUpdateLastMessageTable(msg);
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
