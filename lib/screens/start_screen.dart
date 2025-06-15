import 'package:chatapp/Theme/app_colors.dart';
import 'package:chatapp/services/secure_storage.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  SecureStorage storage = SecureStorage.container;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    isRegisterd();
    super.initState();
  }

  Future<void> isRegisterd() async {
    String? jwta = await storage.readSecureStorage("jwta");
    if (!mounted) return;
    if (jwta == null) {
      Navigator.of(context).pushReplacementNamed("/register");
    } else {
      Navigator.of(context).pushReplacementNamed("/main");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Crypto Chat",
              style: TextStyle(color: AppColors.writtingColor, fontSize: 45),
            ),
            Text(
              "an app for weirdos",
              style: TextStyle(
                color: Colors.deepOrange,
                letterSpacing: 2.25,
                fontSize: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
