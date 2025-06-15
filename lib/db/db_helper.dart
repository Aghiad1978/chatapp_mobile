import 'package:chatapp/models/friend_table.dart';
import 'package:chatapp/models/message_table.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  DBHelper._init();
  static final DBHelper instance = DBHelper._init();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("chat_app.db");
    return _database!;
  }

  Future<Database> _initDB(String filename) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filename);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await FriendTable.createTable(db);
        await MessageTable.createTable(db);
      },
    );
  }

  Future<bool> tableExists(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );

    return result.isNotEmpty;
  }

  Future<void> dropDataBase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "chat_app.db");
    await deleteDatabase(path);
  }
}
