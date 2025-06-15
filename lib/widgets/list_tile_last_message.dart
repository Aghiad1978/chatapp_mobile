import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/models/friend.dart';
import 'package:chatapp/models/last_message.dart';
import 'package:chatapp/providers/counter_provider.dart';
import 'package:chatapp/providers/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LastMessageTile extends StatefulWidget {
  const LastMessageTile({
    super.key,
    required this.friend,
    required this.lastMessage,
  });

  final Friend friend;
  final LastMessage lastMessage;

  @override
  State<LastMessageTile> createState() => _LastMessageTileState();
}

class _LastMessageTileState extends State<LastMessageTile> {
  String limitText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return "${text.substring(0, maxLength)}...";
    }
  }

  String dateConverter(String createdDate) {
    DateTime created = DateTime.parse(createdDate).toLocal();
    DateTime today = DateTime.now();
    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
    if (created.day == today.day &&
        created.month == today.month &&
        created.year == today.year) {
      return DateFormat("hh:mm a").format(created);
    } else if (created.day == yesterday.day &&
        created.month == yesterday.month &&
        created.year == yesterday.year) {
      return "yesterday";
    } else {
      String formatted = DateFormat("EE-d/MM/yyyy").format(created);
      return formatted;
    }
  }

  late final CounterProvider counterProvider;
  late final MessageProvider msgProvider;
  @override
  void initState() {
    super.initState();
    final getIt = GetIt.instance;
    counterProvider = getIt<CounterProvider>();
    msgProvider = Provider.of<MessageProvider>(context, listen: false);
    counterProvider.setInitialCounter(widget.friend.uuid);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: AssetImage(widget.friend.image),
          backgroundColor: AppColors.appBarColor,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.friend.friendName,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Text(
              dateConverter(widget.lastMessage.createdAt),
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.lastMessage.type == "text"
                  ? limitText(widget.lastMessage.lastMessage, 20)
                  : widget.lastMessage.type,
              style: TextStyle(fontSize: 16),
            ),
            Consumer<CounterProvider>(
              builder: (context, provider, child) {
                return provider.counterFor(widget.friend.uuid) > 0
                    ? CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color.fromARGB(255, 23, 69, 24),
                        foregroundColor: Colors.white,
                        child: Text(
                            provider.counterFor(widget.friend.uuid).toString()),
                      )
                    : SizedBox.shrink();
              },
            )
          ],
        ),
        onTap: () async {
          await Navigator.pushNamed(context, "/chat",
              arguments: {"friend": widget.friend});
          WidgetsBinding.instance.addPostFrameCallback((_) {
            msgProvider.clearMessages();
            counterProvider.clearCounter(widget.friend.uuid);
          });
        });
  }
}
