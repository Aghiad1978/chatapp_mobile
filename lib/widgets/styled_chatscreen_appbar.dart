import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/models/friend.dart';
import 'package:chatapp/logic/socket_logic.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class StyledChatscreenAppbar extends StatelessWidget
    implements PreferredSizeWidget {
  const StyledChatscreenAppbar({
    super.key,
    required this.friend,
    required this.uuid,
  });
  final Friend friend;
  final String uuid;

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;
    SocketLogic socketLogic = getIt<SocketLogic>();
    return AppBar(
      titleSpacing: 0,
      iconTheme: IconThemeData(color: AppColors.button2),
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(friend.image),
            backgroundColor: AppColors.appBarColor,
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friend.friendName,
                style: TextStyle(color: AppColors.writtingColor, fontSize: 18),
              ),
              StreamBuilder(
                stream: socketLogic.friendStatusStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final data = snapshot.data!;
                    final uuid = data["uuid"];
                    String status = data["status"];
                    if (uuid == friend.uuid) {
                      return Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          color: status != "online" ? Colors.red : Colors.green,
                        ),
                      );
                    }
                  }
                  return SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.appBarColor,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
