import 'package:chatapp/db/db_helper.dart';
import 'package:chatapp/models/last_message.dart';

import 'package:chatapp/models/message.dart';

import 'package:sqflite/sqflite.dart';

class LastMessageTable {
  static final String tableName = "lastMessageTable";
  static Future<void> createLastMessageTable(Database db) async {
    await db.execute("""
        CREATE TABLE $tableName(
      userID TEXT PRIMARY KEY,
      msgUuid TEXT NOT NULL,
      lastMessage TEXT NOT NULL,
      receiverUuid TEXT NOT NULL ,
      senderUuid TEXT NOT NULL,
      senderMobile TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      type TEXT NOT NULL 
  )
      """);
  }

  static Future<void> _updateLastMessage(Database db, Message msg) async {
    await db.update(
      tableName,
      {
        "msgUuid": msg.msgid,
        "lastMessage": msg.message,
        "receiverUuid": msg.receiverUuid,
        "senderUuid": msg.senderUuid,
        "senderMobile": msg.senderMobile,
        "createdAt": msg.createdAt,
        "type": msg.type,
      },
      where: "senderUuid=? OR receiverUuid=?",
      whereArgs: [msg.senderUuid, msg.senderUuid],
    );
  }

  static Future<void> insertOrUpdateLastMessageTable(Message msg) async {
    Database db = await DBHelper.instance.database;
    final exists = await DBHelper.instance.tableExists(tableName);
    if (!exists) {
      await createLastMessageTable(db);
    }
    final result = await db.query(
      tableName,
      where: "senderUuid=? OR receiverUuid=?",
      whereArgs: [msg.senderUuid, msg.senderUuid],
    );

    if (result.isEmpty) {
      await db.insert(tableName, {
        "msgUuid": msg.msgid,
        "lastMessage": msg.message,
        "receiverUuid": msg.receiverUuid,
        "senderUuid": msg.senderUuid,
        "senderMobile": msg.senderMobile,
        "createdAt": msg.createdAt,
        "type": msg.type,
      });
    } else {
      await _updateLastMessage(db, msg);
    }
  }

  static Future<List<LastMessage>> getAllLastMessages() async {
    // getMessagesFromServer(uuid, socket);
    final existed = await DBHelper.instance.tableExists(tableName);
    Database db = await DBHelper.instance.database;

    List<LastMessage> messages = [];
    if (!existed) {
      await createLastMessageTable(db);
    }
    List<Map<String, dynamic>> resultList = await db.query(tableName);
    messages = LastMessage.lastMessagesFromData(resultList);
    return messages;
  }

  static Future<void> dropLastMessageTable() async {
    Database db = await DBHelper.instance.database;
    await db.execute("DROP TABLE IF EXISTS $tableName");
  }
}
