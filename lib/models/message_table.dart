import 'package:chatapp/db/db_helper.dart';
import 'package:chatapp/models/message.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class MessageTable {
  static final String tableName = "message";

  static Future<void> createTable(Database db) async {
    await db.execute("""  CREATE TABLE $tableName(
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
      status TEXT NOT NULL DEFAULT ''
      )
""");
  }

  static String formatDate(DateTime date) {
    String formatted = DateFormat("EEEE,MMM d,yyyy hh:mm a").format(date);
    return formatted;
  }

  static Future<void> insertMessage(Message msg) async {
    try {
      Database db = await DBHelper.instance.database;
      bool exist = await DBHelper.instance.tableExists(tableName);
      if (!exist) {
        await createTable(db);
      }
      await db.insert(
          tableName,
          {
            "msgid": msg.msgid,
            "senderUuid": msg.senderUuid,
            "receiverUuid": msg.receiverUuid,
            "senderMobile": msg.senderMobile,
            "senderName": msg.senderName,
            "message": msg.message,
            "createdAt":
                DateTime.parse(msg.createdAt).toUtc().toIso8601String(),
            "type": msg.type,
            "received": msg.received ? 1 : 0,
            "read": msg.read ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      print("ERROR InsertMessage func -> message_table.dart $e");
    }
  }

  static Future<List<Message>> getAllMessagesFromInternalDBForSenderUuid(
    String senderUuid,
    String myUuid,
  ) async {
    List<Message> messages = [];
    try {
      Database db = await DBHelper.instance.database;
      bool exist = await DBHelper.instance.tableExists(tableName);
      if (!exist) {
        await createTable(db);
      }
      List<Map<String, dynamic>> messagesList = await db.query(
        tableName,
        where: "senderUuid = ? OR receiverUuid = ?",
        whereArgs: [senderUuid, senderUuid],
        orderBy: 'STRFTIME(\'%Y-%m-%d %H:%M:%S\', createdAt) DESC',
      );
      messages = Message.messagesFromMap(messagesList);
    } catch (e) {
      print("ERROR getAllMessagesFromDB func message_table.dart $e");
    }
    // print("getting messages from internal db $messages");
    return messages;
  }

  static Future<List<Message>> getPaginationMessagesFromInternalDB(
    String senderUuid,
    String myUuid,
    int offset,
    int limit,
  ) async {
    List<Message> messages = [];
    try {
      Database db = await DBHelper.instance.database;
      bool exist = await DBHelper.instance.tableExists(tableName);
      if (!exist) {
        await createTable(db);
      }
      List<Map<String, dynamic>> messagesList = await db.query(
        tableName,
        where: "senderUuid = ? OR receiverUuid = ?",
        whereArgs: [senderUuid, senderUuid],
        limit: limit,
        offset: offset,
        orderBy: "createdAt DESC",
      );

      messages = Message.messagesFromMap(messagesList).reversed.toList();
    } catch (e) {
      print("ERROR getAllMessagesFromDB func message_table.dart $e");
    }
    // print("getting messages from internal db $messages");
    return messages;
  }

  static Future<int> getUnReadMessagesNumbers(String senderUuid) async {
    int counter = 0;
    try {
      Database db = await DBHelper.instance.database;
      final result = await db.query(
        tableName,
        where: "senderUuid=? AND read=0",
        whereArgs: [senderUuid],
      );
      counter = result.length;
    } catch (e) {
      print("Error in message_table getUnReadMessagesNumbers $e");
    }
    return counter;
  }

  //devlopment tool
  static Future<void> cleanDBMessages() async {
    Database db = await DBHelper.instance.database;
    await db.rawDelete("DELETE FROM $tableName");
  }

  static Future<void> saveReceivedUnreadMessages(List<Message> messages) async {
    try {
      for (Message message in messages) {
        //make the message received in internal DB
        message.received = true;
        message.read = false;
        await insertMessage(message);
      }
    } catch (e) {
      print("ERROR saveUnreadMessages func message_table.dart $e");
    }
  }

  static Future<void> dropTable() async {
    Database db = await DBHelper.instance.database;
    await db.execute("DROP TABLE IF EXISTS $tableName");
  }

  static Future<void> updateMessageIntoReceived(String msgid) async {
    try {
      Database db = await DBHelper.instance.database;
      await db.update(tableName, {"received": 1},
          where: "msgid=?", whereArgs: [msgid]);
    } catch (e) {
      print("Error updating the status of message into recieved $e");
    }
  }

  static Future<void> updateMessageIntoRead(String msgid) async {
    try {
      Database db = await DBHelper.instance.database;
      await db.update(
        MessageTable.tableName,
        {"read": 1},
        where: "msgid=?",
        whereArgs: [msgid],
      );
    } catch (e) {
      print("ERROR makeMessageReadInInternalDB func messagetable.dart $e");
    }
  }

  static Future<void> updateMessage(Message msg) async {
    try {
      Database db = await DBHelper.instance.database;
      await db.update(
        tableName,
        {"message": msg.message},
        where: "msgid=?",
        whereArgs: [msg.msgid],
      );
    } catch (e) {
      print("Error in updating message message_table.dart $e");
    }
  }

  static Future<void> updateMessageStatusInInternalDB(
    String msgid,
    int received,
    int read,
  ) async {
    try {
      Database db = await DBHelper.instance.database;
      await db.update(
        MessageTable.tableName,
        {"received": received, "read": read},
        where: "msgid=?",
        whereArgs: [msgid],
      );
    } catch (e) {
      print("ERROR makeMessageReceivedInInternalDB func messagetable.dart $e");
    }
  }
}
