import 'package:chatapp/models/friend.dart';
import 'package:chatapp/widgets/friends_list_tile.dart';
import 'package:flutter/material.dart';

class StyledListview extends StatelessWidget {
  const StyledListview({
    super.key,
    required this.friends,
  });

  final List<Friend> friends;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          var friend = friends[index];
          return FriendsListTile(friend: friend);
        },
      ),
    );
  }
}
