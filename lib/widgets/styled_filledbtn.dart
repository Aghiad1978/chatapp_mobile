import 'package:flutter/material.dart';

class StyledFilledbtn extends StatelessWidget {
  const StyledFilledbtn(
      {super.key, required this.onPressed, required this.child});
  final Widget child;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: child,
    );
  }
}
