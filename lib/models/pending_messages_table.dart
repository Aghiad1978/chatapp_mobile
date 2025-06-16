import 'package:chatapp/db/db_helper.dart';
import 'package:chatapp/models/pending_message.dart';
import 'package:sqflite/sqflite.dart';

class PendingMessagesTable {
  static final String tableName = "pendingMessagesTable";

  static Future<void> _createTable() async {
    Database db = await DBHelper.instance.database;
    await db.execute("""
CREATE TABLE IF NOT EXISTS $tableName (
      msgid TEXT PRIMARY KEY,
      senderUuid TEXT NOT NULL,
      receiverUuid TEXT NOT NULL ,
      senderName TEXT NOT NULL,
      senderMobile TEXT NOT NULL,
      message TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      received INTEGER NOT NULL DEFAULT 0 ,
      read INTEGER NOT NULL DEFAULT 0 ,
      type TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending'
      )
    """);
  }

  static Future<void> insertPendingMessage(PendingMessage msg) async {
    try {
      Database db = await DBHelper.instance.database;
      bool existed = await DBHelper.instance.tableExists(tableName);
      if (!existed) {
        await _createTable();
      }
      await db.insert(tableName, {
        "msgid": msg.msgID,
        "senderUuid": msg.senderUuid,
        "receiverUuid": msg.receiverUuid,
        "senderName": msg.senderName,
        "senderMobile": msg.senderMobile,
        "message": msg.msgText,
        "createdAt": msg.createdAt,
        "type": msg.type
      });
    } catch (e) {
      print("Error: in pendingMessagesTable $e");
    }
  }

  static Future<void> deletePendingMessage(String msgID) async {
    final db = await DBHelper.instance.database;
    bool existed = await DBHelper.instance.tableExists(tableName);
    if (!existed) {
      return;
    }
    await db.delete(tableName, where: "msgid = ?", whereArgs: [msgID]);
  }

  static Future<void> dropTable() async {
    final db = await DBHelper.instance.database;
    bool existed = await DBHelper.instance.tableExists(tableName);
    if (!existed) {
      return;
    }
    await db.execute("DROP TABLE IF EXISTS $tableName");
  }

  static Future<List<PendingMessage>> getPendingMessagesForUuid(
      String receiverUuid) async {
    final db = await DBHelper.instance.database;
    List<PendingMessage> pmList = [];
    bool existed = await DBHelper.instance.tableExists(tableName);
    if (!existed) {
      return pmList;
    }
    final List<Map<String, dynamic>> pendingMessagesListMap = await db
        .query(tableName, where: "receiverUuid = ?", whereArgs: [receiverUuid]);
    pmList = PendingMessage.fromListMapIntoPendmsgList(pendingMessagesListMap);
    return pmList;
  }

  static Future<List<PendingMessage>> getAllPendingMessages() async {
    final db = await DBHelper.instance.database;
    List<PendingMessage> pmList = [];
    bool existed = await DBHelper.instance.tableExists(tableName);
    if (!existed) {
      return pmList;
    }
    final List<Map<String, dynamic>> pendingMessagesListMap =
        await db.query(tableName);
    pmList = PendingMessage.fromListMapIntoPendmsgList(pendingMessagesListMap);
    return pmList;
  }
}
