import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/requests/files_uploader_downloader.dart';
import 'package:chatapp/widgets/audio_message_player.dart';
import 'package:chatapp/widgets/image_loader.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageReceived extends StatefulWidget {
  const MessageReceived({
    super.key,
    required this.message,
    required this.friendName,
  });
  final Message message;
  final String friendName;
  @override
  State<MessageReceived> createState() => _MessageReceivedState();
}

class _MessageReceivedState extends State<MessageReceived> {
  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    } catch (e) {
      return isoString; // fallback if parsing fails
    }
  }

  bool _gettingAsset = false;
  String? _localAssetPath;
  @override
  void initState() {
    if (widget.message.type == "image") {
      _initAsset("image");
    } else if (widget.message.type == "sound") {
      _initAsset("sound");
    }
    super.initState();
  }

  Future<void> _initAsset(String type) async {
    String? assetPathInternally =
        await FilesUploaderDownloader.getAssetFromInternal(
      widget.message.message,
    );
    if (assetPathInternally != null) {
      setState(() {
        _localAssetPath = assetPathInternally;
        _gettingAsset = false;
      });
      return;
    }

    setState(() {
      _gettingAsset = true;
    });
    final localAssetPath = await FilesUploaderDownloader.downloadFileFromServer(
      widget.message.message,
      type,
    );
    setState(() {
      _localAssetPath = localAssetPath;
      _gettingAsset = false;
    });
  }

  Widget chooseWidgetFromMessageType(BuildContext context, Message msg) {
    if (msg.type == "text") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          msg.message,
          style: TextStyle(
            fontSize: 16,
            color: const Color.fromRGBO(255, 255, 255, 0.84),
          ),
        ),
      );
    } else if (msg.type == "image") {
      return imageWidget(msg);
    } else if (msg.type == "sound" && _localAssetPath != null) {
      return AudioMessagePlayer(assetPath: _localAssetPath!);
    } else {
      return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    Message message = widget.message;
    String friendName = widget.friendName;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: IntrinsicWidth(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              color: AppColors.messageBck, // ✅ WhatsApp-style green bubble
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12), // ✅ Rounded on one side
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          friendName,
                          style: TextStyle(
                            color: AppColors.orangeColor,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                chooseWidgetFromMessageType(context, widget.message),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(message.createdAt),
                      style: TextStyle(color: AppColors.writtingColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
