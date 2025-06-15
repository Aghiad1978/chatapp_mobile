import 'package:chatapp/db/db_helper.dart';
import 'package:chatapp/models/friend_table.dart';
import 'package:chatapp/models/last_message_table.dart';
import 'package:chatapp/models/message_table.dart';
import 'package:chatapp/services/secure_storage.dart';
import 'package:chatapp/services/sharedpreferences_storage.dart';
import 'package:flutter/material.dart';

class DeveloperPopupmenu extends StatelessWidget {
  const DeveloperPopupmenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: Offset(0, 50),
      iconColor: Colors.white,
      itemBuilder: (context) {
        return [
          PopupMenuItem(
              child: Text(
            "Developer's Options",
            style: TextStyle(color: Colors.green),
          )),
          PopupMenuItem(child: PopupMenuDivider()),
          PopupMenuItem(
            child: InkWell(
              onTap: () {
                MessageTable.dropTable();
                print("Internal Db Deleted");
              },
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.delete, color: Colors.red),
                  ),
                  Text("Delete internal Db "),
                ],
              ),
            ),
          ),
          PopupMenuItem(
            child: InkWell(
              onTap: () {
                LastMessageTable.dropLastMessageTable();
                print("lastMessage Db Deleted");
              },
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {},
                    icon: Icon(Icons.delete, color: Colors.red),
                  ),
                  Text("Delete LastMessage Table "),
                ],
              ),
            ),
          ),
          PopupMenuItem(
            child: InkWell(
              onTap: () async {
                await SecureStorage.container.deleteSecureStorage(
                  "jwta",
                );
                await SecureStorage.container.deleteSecureStorage(
                  "jwtr",
                );
                await SharedpreferencesStorage.deleteSharedPreferences();
                await FriendTable.dropFriendTable();
                await DBHelper.instance.dropDataBase();
                await LastMessageTable.dropLastMessageTable();
                print("Destroy");
              },
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.fireplace, color: Colors.purple),
                  ),
                  Text("Destroy"),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }
}
