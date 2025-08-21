import 'package:flutter/material.dart';

class CircularButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final double size;

  const CircularButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = Colors.blue,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Center(
        child: GestureDetector(
          onTap: onPressed,
          child: child,
        ),
      ),
    );
  }
}
