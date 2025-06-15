import 'package:chatapp/models/message.dart';

class PendingMessage {
  PendingMessage(
      {required this.msgText,
      required this.msgID,
      required this.senderUuid,
      required this.receiverUuid,
      required this.type,
      required this.createdAt,
      required this.senderName,
      required this.senderMobile});

  String msgText;
  String msgID;
  String senderUuid;
  String receiverUuid;
  String type;
  String createdAt;
  String senderName;
  String senderMobile;
  String status = "pending";

  static Message convertPendingMessageIntoMessage(PendingMessage pm) {
    Message msg = Message(
      senderUuid: pm.senderUuid,
      receiverUuid: pm.receiverUuid,
      message: pm.msgText,
      createdAt: pm.createdAt,
      senderName: pm.senderName,
      senderMobile: pm.senderMobile,
      msgid: pm.msgID,
      type: pm.type,
      status: "pending",
    );
    return msg;
  }

  static List<PendingMessage> fromListMapIntoPendmsgList(
      List<Map<String, dynamic>> pendingListMap) {
    List<PendingMessage> pmList = [];
    for (var pmMap in pendingListMap) {
      PendingMessage pm = PendingMessage(
          msgText: pmMap["message"],
          msgID: pmMap["msgid"],
          senderUuid: pmMap["senderUuid"],
          receiverUuid: pmMap["receiverUuid"],
          type: pmMap["type"],
          createdAt: pmMap["createdAt"],
          senderName: pmMap["senderName"],
          senderMobile: pmMap["senderMobile"]);
      pmList.add(pm);
    }
    return pmList;
  }
}
