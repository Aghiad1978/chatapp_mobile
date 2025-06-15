import 'package:chatapp/screens/camera_screen.dart';
import 'package:flutter/material.dart';

class SettingsPopupmenu extends StatelessWidget {
  const SettingsPopupmenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      iconColor: Colors.green,
      offset: Offset(0, 50),
      itemBuilder: (context) {
        return [
          PopupMenuItem(
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CameraScreen()));
            },
            child: Row(
              children: [
                Icon(Icons.camera_alt),
                SizedBox(
                  width: 15,
                ),
                Text("set your image"),
              ],
            ),
          ),
        ];
      },
    );
  }
}
