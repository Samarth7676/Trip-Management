import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../utils/formatters.dart';
import '../utils/palette.dart';

/// A large "travel pass" style card: full gradient cover, oversized emoji
/// motif, and a status pill - a much richer presentation than a flat list
/// row.
class TripPassCard extends StatelessWidget {
  final Trip trip;

  const TripPassCard({super.key, required this.trip});

  ({String label, Color color}) get _status {
    final now = DateTime.now();
    if (trip.isActive) {
      return (label: 'Active now', color: const Color(0xFF10B981));
    } else if (trip.isUpcoming) {
      final days = trip.startDate.difference(now).inHours / 24;
      return (label: days < 1 ? 'Today' : 'In ${days.ceil()}d', color: Colors.white);
    }
    return (label: 'Completed', color: Colors.white70);
  }

  @override
  Widget build(BuildContext context) {
    final base = Color(trip.coverColorValue);
    final status = _status;

    return Container(
      height: 176,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.black, 0.35)!],
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Oversized decorative emoji motif.
            Positioned(
              right: -18,
              bottom: -30,
              child: Opacity(
                opacity: 0.18,
                child: Transform.rotate(
                  angle: -0.25,
                  child: Text(trip.coverEmoji, style: const TextStyle(fontSize: 140)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.place_rounded, size: 13, color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 4),
                            Text(
                              trip.destination,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: status.color == const Color(0xFF10B981)
                              ? status.color
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.label,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    trip.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDateRange(trip.startDate, trip.endDate),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _AvatarStack(trip: trip),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final Trip trip;

  const _AvatarStack({required this.trip});

  @override
  Widget build(BuildContext context) {
    final shown = trip.participants.take(4).toList();
    final overflow = trip.participants.length - shown.length;

    return SizedBox(
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 20.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(shown[i].colorValue),
                  child: Text(
                    shown[i].name.isNotEmpty ? shown[i].name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * 20.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: paletteColorFor(shown.length + 3),
                  child: Text('+$overflow', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
