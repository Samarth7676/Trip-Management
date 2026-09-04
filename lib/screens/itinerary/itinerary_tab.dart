import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/itinerary_item.dart';
import '../../providers/itinerary_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/icon_helpers.dart';
import '../../widgets/gradient_icon_badge.dart';
import '../../widgets/swipe_to_delete.dart';
import 'add_itinerary_item_screen.dart';

const _typeColors = {
  ItineraryType.flight: Color(0xFF2F6FED),
  ItineraryType.train: Color(0xFF8B5CF6),
  ItineraryType.bus: Color(0xFF06B6D4),
  ItineraryType.hotel: Color(0xFFF59E0B),
  ItineraryType.activity: Color(0xFF10B981),
  ItineraryType.other: Color(0xFF6B7280),
};

class ItineraryTab extends ConsumerWidget {
  final String tripId;

  const ItineraryTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itineraryProvider(tripId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🧭', style: TextStyle(fontSize: 56))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .rotate(begin: -0.03, end: 0.03, duration: 1400.ms, curve: Curves.easeInOut),
                    const SizedBox(height: 12),
                    Text('No itinerary items yet', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('Add flights, trains, hotels and activities to get offline reminders.',
                        textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ).animate().fadeIn(duration: 350.ms),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              itemBuilder: (context, index) => _TimelineRow(
                item: items[index],
                tripId: tripId,
                isFirst: index == 0,
                isLast: index == items.length - 1,
                index: index,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_itinerary',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddItineraryItemScreen(tripId: tripId)),
          );
        },
        child: const Icon(Icons.add_rounded),
      ).animate().scale(delay: 150.ms, duration: 250.ms, curve: Curves.easeOutBack),
    );
  }
}

class _TimelineRow extends ConsumerWidget {
  final ItineraryItem item;
  final String tripId;
  final bool isFirst;
  final bool isLast;
  final int index;

  const _TimelineRow({
    required this.item,
    required this.tripId,
    required this.isFirst,
    required this.isLast,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color = _typeColors[item.type] ?? scheme.primary;

    return SwipeToDelete(
      keyValue: item.id,
      confirmTitle: 'Delete "${item.title}"?',
      onDelete: () => ref.read(itineraryProvider(tripId).notifier).deleteItem(item),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 2,
                  height: 12,
                  color: isFirst ? Colors.transparent : scheme.outlineVariant,
                ),
                GradientIconBadge(icon: iconForItineraryType(item.type), color: color, size: 42),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : scheme.outlineVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AddItineraryItemScreen(tripId: tripId, existing: item)),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                labelForItineraryType(item.type),
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(formatDateTime(item.startDateTime),
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                        if (item.location.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.place_rounded, size: 13, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(item.location,
                                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                        if (item.confirmationNumber.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Confirmation: ${item.confirmationNumber}',
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms, duration: 300.ms).slideX(begin: 0.06, end: 0);
  }
}
