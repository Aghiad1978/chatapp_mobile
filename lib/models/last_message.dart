class LastMessage {
  LastMessage(
      {required this.senderUuid,
      required this.msgUuid,
      required this.lastMessage,
      required this.receiverUuid,
      required this.senderMobile,
      required this.createdAt,
      required this.type,
      required this.reservedMobile});
  String senderMobile;
  String lastMessage;
  String receiverUuid;
  String msgUuid;
  String senderUuid;
  String createdAt;
  String type;
  String reservedMobile;

  static List<LastMessage> lastMessagesFromData(
      List<Map<String, dynamic>> data) {
    List<LastMessage> lastmessages = [];
    for (Map<String, dynamic> lm in data) {
      lastmessages.add(LastMessage(
          msgUuid: lm["msgUuid"],
          senderUuid: lm["senderUuid"],
          lastMessage: lm["lastMessage"],
          receiverUuid: lm["receiverUuid"],
          senderMobile: lm["senderMobile"],
          createdAt: lm["createdAt"],
          reservedMobile: lm["reservedMobile"],
          type: lm["type"]));
    }
    return lastmessages;
  }

  @override
  String toString() {
    return "LastMessage(msg:$lastMessage,sender:$senderUuid,receiver:$receiverUuid,id:$msgUuid)";
  }
}
