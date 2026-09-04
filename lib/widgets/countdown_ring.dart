import 'package:flutter/material.dart';

import '../models/trip.dart';

class CountdownRing extends StatelessWidget {
  final Trip trip;

  const CountdownRing({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final totalDays = trip.endDate.difference(trip.startDate).inHours / 24;
    final elapsedDays = now.difference(trip.startDate).inHours / 24;

    String label;
    String sublabel;
    double progress;
    Color color;

    if (trip.isUpcoming) {
      final daysUntil = trip.startDate.difference(now).inHours / 24;
      label = daysUntil < 1 ? 'Today' : '${daysUntil.ceil()}';
      sublabel = daysUntil < 1 ? "It's trip day!" : 'days to go';
      progress = 0.0;
      color = scheme.primary;
    } else if (trip.isActive) {
      final daysLeft = trip.endDate.difference(now).inHours / 24;
      label = daysLeft < 1 ? 'Last day' : '${daysLeft.ceil()}';
      sublabel = daysLeft < 1 ? 'wrapping up' : 'days left';
      progress = totalDays <= 0 ? 1.0 : (elapsedDays / totalDays).clamp(0.0, 1.0);
      color = const Color(0xFF10B981);
    } else {
      label = '✓';
      sublabel = 'completed';
      progress = 1.0;
      color = scheme.onSurfaceVariant;
    }

    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CircularProgressIndicator(
              value: trip.isUpcoming ? 1.0 : value,
              strokeWidth: 7,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(
                trip.isUpcoming ? scheme.surfaceContainerHighest : color,
              ),
            ),
          ),
          if (trip.isUpcoming)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 7,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: label.length > 2 ? 16 : 20, color: color)),
              Text(sublabel, style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }
}
