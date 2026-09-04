import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A page route that swings the incoming page in around the Y axis with
/// perspective, like a door opening in 3D, instead of a flat slide/fade.
class Flip3DPageRoute<T> extends PageRouteBuilder<T> {
  Flip3DPageRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: const Duration(milliseconds: 480),
          reverseTransitionDuration: const Duration(milliseconds: 360),
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return AnimatedBuilder(
              animation: curved,
              child: child,
              builder: (context, child) {
                final value = curved.value;
                final angle = (1 - value) * (math.pi / 2.4);
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateY(angle);
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: transform,
                    child: child,
                  ),
                );
              },
            );
          },
        );
}
