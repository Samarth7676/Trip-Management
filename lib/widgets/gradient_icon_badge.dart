import 'package:flutter/material.dart';

/// A circular icon badge with a soft diagonal gradient - the recurring
/// "modern" motif used across itinerary, expense, and packing rows.
class GradientIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const GradientIconBadge({super.key, required this.icon, required this.color, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.92), Color.lerp(color, Colors.black, 0.25)!],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.48),
    );
  }
}
