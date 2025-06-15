import 'dart:io';
import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/widgets/audio_message_player.dart';
import 'package:chatapp/widgets/show_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageSent extends StatefulWidget {
  const MessageSent({super.key, required this.message});
  final Message message;

  @override
  State<MessageSent> createState() => _MessageSentState();
}

class _MessageSentState extends State<MessageSent> {
  Icon? statusIcon;
  Widget addedAdditionalList = SizedBox();
  @override
  void initState() {
    super.initState();
  }

  Widget getWidgetAccordingToMessage(Message message) {
    if (message.type == "text") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          message.message,
          style: TextStyle(
            fontSize: 16,
            color: const Color.fromRGBO(255, 255, 255, 0.84),
          ),
        ),
      );
    } else if (message.type == "image") {
      return InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ShowImage(imagePath: message.message),
            ),
          );
        },
        child: Image.file(File(message.message), fit: BoxFit.contain),
      );
    } else if (message.type == "sound") {
      return Column(children: [AudioMessagePlayer(assetPath: message.message)]);
    } else {
      return SizedBox.shrink();
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      if (date ==
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal()) {
        return "pending";
      }
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    } catch (e) {
      return isoString; // fallback if parsing fails
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Icon _iconForStatus(Message msg) {
    if (msg.read == true) {
      return Icon(Icons.done_all, color: Colors.blueAccent, size: 18);
    } else if (msg.received == true) {
      return Icon(Icons.done_all, color: Colors.grey, size: 18);
    } else {
      if (msg.status == "pending") {
        return Icon(Icons.access_time, color: Colors.redAccent, size: 18);
      }
      return Icon(Icons.check, color: Colors.grey, size: 18);
    }
  }

  @override
  Widget build(BuildContext context) {
    Message message = widget.message;
    return InkWell(
      onLongPress: () {},
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: IntrinsicWidth(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color:
                        AppColors.messageBck, // ✅ WhatsApp-style green bubble
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12), // ✅ Rounded on one side
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),

                            bottomRight: Radius.circular(
                              12,
                            ), // ✅ Rounded on one side
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "You",
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                color: AppColors.orangeColor,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      getWidgetAccordingToMessage(message),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _iconForStatus(message),
                            Text(
                              _formatDate(message.createdAt),
                              style: TextStyle(color: AppColors.writtingColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          addedAdditionalList,
        ],
      ),
    );
  }
}
