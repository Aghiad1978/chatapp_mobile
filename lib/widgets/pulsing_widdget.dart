import 'package:flutter/material.dart';

class PulsingWiddget extends StatefulWidget {
  const PulsingWiddget({super.key, required this.myWidget});
  final Widget myWidget;

  @override
  State<PulsingWiddget> createState() => _PulsingWiddgetState();
}

class _PulsingWiddgetState extends State<PulsingWiddget> {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.50), // Scale from 1.0 to 1.5
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: widget.myWidget,
    );
  }
}
