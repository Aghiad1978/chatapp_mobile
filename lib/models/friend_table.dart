import 'dart:convert';
import 'package:chatapp/config.dart';
import 'package:chatapp/db/db_helper.dart';
import 'package:chatapp/models/friend.dart';
import 'package:chatapp/services/secure_storage.dart';
import 'package:chatapp/services/sharedpreferences_storage.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

class FriendTable {
  static final String tableName = "friend";

  static Future<List<Contact>?> _getContacts() async {
    final permission = await Permission.contacts.request();
    if (permission.isGranted) {
      var contacts = await FastContacts.getAllContacts();
      return contacts;
    } else {
      print("Permission for getting contacts not granted");
    }
    return null;
  }

  static String _formatNumber(String number, String code) {
    number = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (number.startsWith("+")) {
      return number;
    }
    if (number.startsWith("0")) {
      number = number.substring(1);
    }
    return "+$code$number";
  }

  static Future<List<Map<String, String>>> _getFormattedNumbersList(
    String code,
  ) async {
    List<Contact>? contacts = await _getContacts();
    List<Map<String, String>> formattedContacts = [];
    if (contacts != null) {
      for (var contact in contacts) {
        if (contact.phones.isNotEmpty) {
          for (var phone in contact.phones) {
            var formattedPhone = _formatNumber(phone.number, code);
            formattedContacts.add({formattedPhone: contact.displayName});
          }
        }
      }
    }
    return formattedContacts;
  }

  static Future<void> getPossibleFriendsFromServer() async {
    String code = await SharedpreferencesStorage.getJustOne("code");
    String uuidShared = await SharedpreferencesStorage.getJustOne("uuid");
    String mobileShared = await SharedpreferencesStorage.getJustOne("mobile");
    try {
      final jwta = await SecureStorage.container.readSecureStorage("jwta");
      Uri url = Uri.parse("${Config.listenningIP}/api/v1/getFriends");
      final numbersToCheck = await _getFormattedNumbersList(code);
      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwta",
          "uuid": uuidShared,
        },
        body: json.encode(numbersToCheck),
      );
      if (resp.statusCode == 200) {
        List<dynamic> friends = json.decode(resp.body);

        for (var friend in friends) {
          String friendName = friend["name"];
          String email = friend["email"];
          String uuid = friend["uuid"];
          String mobile = friend["mobile"];
          if (friend["mobile"] != mobileShared) {
            await FriendTable.insertFriend(
              Friend(
                friendName: friendName,
                email: email,
                mobile: mobile,
                uuid: uuid,
              ),
            );
          }
        }
      } else if (resp.statusCode == 401) {
        throw Exception("you are unauthorized to use the app");
      } else if (resp.statusCode == 403) {
        throw Exception("token has been modified or expired");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Database> _getDB() async {
    return await DBHelper.instance.database;
  }

  //Main functions of the friend Table
  static Future<void> createTable(Database db) async {
    await db.execute("""
    CREATE TABLE $tableName(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      friendName TEXT NOT NULL,
      mobile TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      uuid TEXT NOT NULL UNIQUE,
      isBlocked INTEGER DEFAULT 0
    )
      """);
  }

  static Future<void> insertFriend(Friend friend) async {
    try {
      final db = await _getDB();
      bool exists = await DBHelper.instance.tableExists(tableName);
      if (!exists) {
        await createTable(db);
      }
      await db.insert(
          tableName,
          {
            "friendName": friend.friendName,
            "mobile": friend.mobile,
            "email": friend.email,
            "uuid": friend.uuid,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw Exception(e);
    }
  }

  static Future<List<Friend>> getAllFriends() async {
    // await getPossibleFriendsFromServer();

    List<Friend> friends = [];
    try {
      final db = await _getDB();
      final friendsMap = await db.query("friend");
      friends = friendsMap.map((item) {
        return Friend(
          friendName: item["friendName"].toString(),
          email: item["email"].toString(),
          mobile: item["mobile"].toString(),
          uuid: item["uuid"].toString(),
        );
      }).toList();
    } catch (e) {
      print("ERROR:getAllfriends func friend_table.dart $e ");
      throw Exception(e);
    }

    return friends;
  }

  static Future<Friend?> getFriendFromUuid(String uuid) async {
    Friend? friend;
    try {
      Database db = await DBHelper.instance.database;
      final result = await db.query(
        tableName,
        where: "uuid=?",
        whereArgs: [uuid],
        limit: 1,
      );
      friend = Friend.friendFromData(result[0]);
      return friend;
    } catch (e) {
      return null;
    }
  }

  static Future<void> dropFriendTable() async {
    final db = await DBHelper.instance.database;
    await db.execute("DROP TABLE IF EXISTS $tableName");
    print("Friends table is DELETED .");
  }
}
