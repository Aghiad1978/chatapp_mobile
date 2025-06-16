import 'package:chatapp/models/friend_table.dart';
import 'package:chatapp/models/last_message_table.dart';
import 'package:chatapp/models/friend.dart';
import 'package:chatapp/models/last_message.dart';
import 'package:chatapp/models/message.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class LastMessageProvider extends ChangeNotifier {
  List<LastMessage> lMessages = [];
  List<Friend> friends = [];

  Future<void> incomingMessage(Message msg) async {
    await LastMessageTable.insertOrUpdateLastMessageTable(msg);
    await getLastMessagesFromInternalDB();
    await getFriendsListFromInternalDb();
    notifyListeners();
  }

  Future<void> inSendingMessage(Message msg) async {
    await LastMessageTable.insertOrUpdateLastMessageTable(msg);
    await getLastMessagesFromInternalDB();
    await getFriendsListFromInternalDb();
    notifyListeners();
  }

  Future<void> getLastMessagesFromInternalDB() async {
    List<LastMessage> fetchedLastMessages =
        await LastMessageTable.getAllLastMessages();
    lMessages = [...fetchedLastMessages];
  }

  Future<void> getFriendsListFromInternalDb() async {
    List<Friend> fetchedFriends = [];
    await getLastMessagesFromInternalDB();
    final getIt = GetIt.instance;
    final myUuid = getIt<String>(instanceName: "uuid");
    final myMobile = getIt<String>(instanceName: "mobile");
    Friend? friend;
    for (LastMessage lm in lMessages) {
      if (lm.senderUuid == myUuid) {
        friend = await FriendTable.getFriendFromUuid(lm.receiverUuid);
      } else {
        friend = await FriendTable.getFriendFromUuid(lm.senderUuid);
        friend ??= Friend(
            friendName: lm.reservedMobile,
            email: "unknown",
            mobile: lm.senderMobile,
            uuid: lm.senderUuid);
      }
      fetchedFriends.add(friend!);
    }
    friends = [...fetchedFriends];
    notifyListeners();
  }
}
