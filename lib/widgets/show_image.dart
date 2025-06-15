import 'dart:io';

import 'package:flutter/material.dart';

class ShowImage extends StatelessWidget {
  const ShowImage({super.key, required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        // appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        //   automaticallyImplyLeading: false,
        // ),
        body: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 35,
                    )),
              ],
            ),
            // SizedBox(
            //   height: 10,
            // ),
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  panEnabled: false, // Set to false to prevent panning
                  minScale: 1.0,
                  maxScale: 4.0, // Adjust as needed
                  child: Image.file(File(imagePath)),
                ),
              ),
            ),
          ],
        ));
  }
}
