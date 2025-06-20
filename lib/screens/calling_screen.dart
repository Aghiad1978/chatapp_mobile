import 'package:chatapp/models/friend.dart';
import 'package:flutter/material.dart';

class CallingScreen extends StatelessWidget {
  const CallingScreen({
    super.key,
    required this.friend,
  });
  final Friend friend;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              friend.friendName,
              style: TextStyle(color: Colors.white, fontSize: 32),
            ),
            SizedBox(
              height: 20,
            ),
            RawMaterialButton(
              onPressed: () {
                Navigator.pop(context);
              },
              elevation: 2.0,
              fillColor: Colors.red,
              shape: const CircleBorder(),
              constraints: const BoxConstraints.tightFor(
                width: 56.0,
                height: 56.0,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 32.0,
              ),
            )
          ],
        ),
      ),
    );
  }
}
