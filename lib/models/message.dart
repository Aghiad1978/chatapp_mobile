class Message {
  Message({
    required this.senderUuid,
    required this.receiverUuid,
    required this.message,
    required this.createdAt,
    required this.senderName,
    required this.senderMobile,
    required this.msgid,
    required this.type,
    this.read = false,
    this.received = false,
    this.status = "",
  });
  String senderUuid;
  final String receiverUuid;
  String message;
  final String senderName;
  final String senderMobile;
  final String createdAt;
  final String msgid;
  String type;
  bool read;
  bool received;
  String status = "";

  static List<Message> messagesFromMap(
      List<Map<String, dynamic>> messagesList) {
    List<Message> messages = [];
    try {
      for (var message in messagesList) {
        Message msg = Message(
            msgid: message["msgid"],
            senderUuid: message["senderUuid"],
            receiverUuid: message["receiverUuid"],
            message: message["message"],
            senderMobile: message["senderMobile"],
            senderName: message["senderName"],
            createdAt: message["createdAt"],
            received: message["received"] == 1 ? true : false,
            read: message["read"] == 1 ? true : false,
            type: message["type"],
            status: message["status"] ?? "");
        messages.add(msg);
      }
    } catch (e) {
      print("ERROR messagesfromMap 32 message.dart $e");
    }
    return messages;
  }

  static Message fromMapToMessage(Map<String, dynamic> messageMap) {
    Message msg = Message(
      msgid: messageMap["msgid"]!,
      senderUuid: messageMap["senderUuid"]!,
      receiverUuid: messageMap["receiverUuid"]!,
      message: messageMap["message"]!,
      senderMobile: messageMap["senderMobile"]!,
      senderName: messageMap["senderName"],
      createdAt: messageMap["createdAt"]!,
      type: messageMap["type"]!,
    );
    return msg;
  }

  static Map<String, dynamic> createMapFromMessage(Message msg) {
    Map<String, dynamic> data = {};
    data["senderUuid"] = msg.senderUuid;
    data["msgid"] = msg.msgid;
    data["receiverUuid"] = msg.receiverUuid;
    data["createdAt"] = msg.createdAt;
    data["message"] = msg.message;
    data["type"] = msg.type;
    data["senderName"] = msg.senderName;
    data["senderMobile"] = msg.senderMobile;
    data["read"] = msg.read ? 1 : 0;
    data["received"] = msg.received ? 1 : 0;
    data["status"] = msg.status;
    return data;
  }
}
