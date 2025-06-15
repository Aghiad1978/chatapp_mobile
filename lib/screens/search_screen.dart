import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/models/friend_table.dart';
import 'package:chatapp/models/friend.dart';
import 'package:chatapp/services/sharedpreferences_storage.dart';
import 'package:chatapp/widgets/styled_dialog_withprogress.dart';
import 'package:chatapp/widgets/styled_listView.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final uuid;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        uuid = await SharedpreferencesStorage.getJustOne("uuid");
      } catch (e) {
        print("ERROR: $e");
      }
    });
    super.initState();
  }

  Future<void> retryGetUsers(double secs) async {
    if (secs < 1) {
      await Future.delayed(
        Duration(milliseconds: (100 * secs).toInt()),
      ); // Retry after 5 seconds
      setState(() {}); // Trigger rebuild to retry the process
    } else {
      await Future.delayed(
        Duration(seconds: secs.toInt()),
      ); // Retry after 5 seconds
      setState(() {}); // Trigger rebuild to retry the process
    }
  }

  Future<List<Friend>> getAllUser(BuildContext context) async {
    List<Friend> friends = [];
    try {
      friends = await FriendTable.getAllFriends();
    } catch (e) {
      print("ERROR getAllUSer func-> main_screen.dart $e");
      throw Exception(e);
    }
    return friends;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search..", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.appBarColor,
        actions: [
          IconButton(
            onPressed: () async {
              await FriendTable.getPossibleFriendsFromServer();
              setState(() {});
            },
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            FutureBuilder(
              future: getAllUser(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showLoadingDialog(context, message: "loading...");
                  });
                  return Center(child: SizedBox());
                }
                if (snapshot.hasError) {
                  Navigator.pop(context);
                  retryGetUsers(5);
                  return Center(
                    child: Text(
                      "unable to get users sorry...",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  var friends = snapshot.data;
                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  return StyledListview(
                    friends: friends!,
                  );
                }
                return Text("data");
              },
            ),
            // StyledFilledbtn(
            //   onPressed: () async {
            //     await SecureStorage.container.deleteSecureStorage("jwta");
            //     await SecureStorage.container.deleteSecureStorage("jwtr");
            //     await SharedpreferencesStorage.deleteSharedPreferences();
            //     await FriendTable.dropFriendTable();
            //     await DBHelper.instance.dropDataBase();
            //   },
            //   child: Text("Destroy"),
            // ),
            SizedBox(height: 50, width: 15),
          ],
        ),
      ),
    );
  }
}
