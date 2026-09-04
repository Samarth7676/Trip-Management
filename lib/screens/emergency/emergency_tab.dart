import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/emergency_numbers.dart';

class EmergencyTab extends StatelessWidget {
  final String destination;

  const EmergencyTab({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    final info = findEmergencyInfoFor(destination);
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              const Text('🆘', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Emergency numbers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(info.country, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Available offline', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: info.entries.asMap().entries.map((e) => _EmergencyTile(entry: e.value, index: e.key)).toList(),
        ),
        const SizedBox(height: 16),
        if (info.embassyHint.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('🏛️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(child: Text(info.embassyHint, style: TextStyle(color: scheme.onSurfaceVariant))),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
      ],
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  final EmergencyEntry entry;
  final int index;

  const _EmergencyTile({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => launchUrl(Uri.parse('tel:${entry.number.replaceAll(RegExp(r'[^0-9+]'), '')}')),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(entry.icon, style: const TextStyle(fontSize: 26)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_rounded, size: 14, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
              const Spacer(),
              Text(entry.number, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 2),
              Text(
                entry.service,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (60 * index).ms, duration: 300.ms).scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}
