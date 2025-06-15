import 'package:chatapp/logic/socket_logic.dart';
import 'package:chatapp/providers/message_provider.dart';
import 'package:chatapp/requests/files_uploader_downloader.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get_it/get_it.dart';

class PhotoShot extends StatefulWidget {
  const PhotoShot({
    super.key,
    required this.photoPath,
  });
  final String photoPath;

  @override
  State<PhotoShot> createState() => _PhotoShotState();
}

class _PhotoShotState extends State<PhotoShot> {
  bool isUploading = false;
  final getIt = GetIt.instance;
  late MessageProvider messageProvider;
  @override
  void initState() {
    final getIt = GetIt.instance;
    super.initState();
    messageProvider = getIt<MessageProvider>();
  }

  @override
  Widget build(BuildContext context) {
    File imageFile = File(widget.photoPath);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.cancel),
                color: Colors.white,
                iconSize: 30,
                onPressed: () async {
                  await imageFile.delete();
                  Navigator.of(context).pop();
                },
              ),
              Center(
                child: Image.file(
                  imageFile,
                  height: MediaQuery.of(context).size.height * 0.60,
                  width: MediaQuery.of(context).size.width * 0.60,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.white24,
                    ),
                    child: IconButton(
                      onPressed: () async {
                        setState(() {
                          isUploading = true;
                        });
                        String location =
                            getIt<String>(instanceName: "location");

                        if (location == "chat") {
                          if (getIt<SocketLogic>().getOnlineStatus()) {
                            final fileName = await FilesUploaderDownloader
                                .uploadMediaIntoServer(
                              widget.photoPath,
                              "image",
                            );
                            if (fileName == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Can't upload the image")),
                              );
                              Navigator.pop(context);
                              return;
                            }
                          }
                          await messageProvider.sendMessage(
                            widget.photoPath,
                            "image",
                          );
                        } else if (location == "main") {
                          final fileName = await FilesUploaderDownloader
                              .uploadMediaIntoServer(
                            widget.photoPath,
                            "userImage",
                          );
                          if (fileName == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Can't upload the image")),
                            );
                            Navigator.pop(context);
                            return;
                          }
                        }
                        setState(() {
                          isUploading = false;
                        });
                        Navigator.pop(context);
                      },
                      icon: Icon(size: 35, Icons.send, color: Colors.green),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
            ],
          ),
          if (isUploading)
            Container(
              color: Colors.transparent,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    Text(
                      "uploading image...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
