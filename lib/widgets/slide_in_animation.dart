// lib/widgets/slide_in_animation.dart
import 'package:flutter/material.dart';

class SlideInAnimation extends StatelessWidget {
  final Widget child;
  final int delay;
  final Offset beginOffset;
  
  const SlideInAnimation({
    super.key,
    required this.child,
    this.delay = 0,
    this.beginOffset = const Offset(0, 0.3),
  });
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            beginOffset.dx * (1 - value) * 100,
            beginOffset.dy * (1 - value) * 100,
          ),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}