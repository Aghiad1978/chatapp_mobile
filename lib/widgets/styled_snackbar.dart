import 'package:flutter/material.dart';

class StyledSnackbar {
  static void showSnackbar(BuildContext ctx, String text, int seconds) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: Duration(seconds: seconds),
      ),
    );
  }
}
