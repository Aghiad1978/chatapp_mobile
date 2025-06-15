import 'dart:io';

import 'package:chatapp/models/message.dart';
import 'package:chatapp/requests/files_uploader_downloader.dart';
import 'package:chatapp/widgets/show_image.dart';
import 'package:flutter/material.dart';

Widget imageWidget(Message msg) {
  return FutureBuilder<String?>(
    future: FilesUploaderDownloader.getAssetFromInternal(msg.message)
        .then((path) async {
      if (path != null) return path;
      return await FilesUploaderDownloader.downloadFileFromServer(
          msg.message, "image");
    }),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator();
      }
      if (!snapshot.hasData) {
        return Stack(
          children: [
            Image.asset("assets/images/image.jpg", fit: BoxFit.contain),
            Center(child: CircularProgressIndicator()),
          ],
        );
      }
      return InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ShowImage(imagePath: snapshot.data!),
          ));
        },
        child: Image.file(File(snapshot.data!), fit: BoxFit.scaleDown),
      );
    },
  );
}
