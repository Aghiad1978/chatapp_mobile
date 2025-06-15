import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/models/friend.dart';
import 'package:chatapp/providers/connectivity_provider.dart';
import 'package:chatapp/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FriendsListTile extends StatefulWidget {
  const FriendsListTile({
    super.key,
    required this.friend,
  });

  final Friend friend;

  @override
  State<FriendsListTile> createState() => _FriendsListTileState();
}

class _FriendsListTileState extends State<FriendsListTile> {
  late ConnectivityProvider connectivityProvider;
  int counter = 0;
  // late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    connectivityProvider =
        Provider.of<ConnectivityProvider>(context, listen: false);
  }

  @override
  void dispose() {
    // _subscription.cancel(); // Always cancel stream
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(widget.friend.image),
        backgroundColor: AppColors.appBarColor,
      ),
      title: Text(
        widget.friend.friendName,
        style: TextStyle(color: AppColors.writtingColor),
      ),
      trailing: counter > 0
          ? CircleAvatar(
              radius: 15,
              backgroundColor: const Color.fromARGB(255, 23, 69, 24),
              foregroundColor: Colors.white,
              child: Text(counter.toString()),
            )
          : SizedBox.shrink(),
      onTap: () async {
        setState(() {
          counter = 0;
        });
        Navigator.of(context).pushReplacementNamed(
          "/chat",
          arguments: {"friend": widget.friend},
        );
      },
    );
  }
}
