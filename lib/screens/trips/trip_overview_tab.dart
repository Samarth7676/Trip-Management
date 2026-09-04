import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/expense_provider.dart';
import '../../providers/itinerary_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/settlement_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/countdown_ring.dart';
import '../../widgets/currency_converter_sheet.dart';

class TripOverviewTab extends ConsumerWidget {
  final String tripId;

  const TripOverviewTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripByIdProvider(tripId));
    final expenses = ref.watch(expensesProvider(tripId));
    final itinerary = ref.watch(itineraryProvider(tripId));
    final profile = ref.watch(currentProfileProvider);
    if (trip == null) return const SizedBox.shrink();

    final total = SettlementService.totalSpend(expenses);
    final scheme = Theme.of(context).colorScheme;
    final nextItem = itinerary
        .where((i) => i.startDateTime.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trip.destination,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(formatDateRange(trip.startDate, trip.endDate),
                              style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    CountdownRing(trip: trip),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatBox(label: 'Total spent', value: formatMoney(total, trip.currency)),
                    const SizedBox(width: 12),
                    _StatBox(label: 'Expenses logged', value: '${expenses.length}'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => CurrencyConverterSheet.show(
                      context,
                      fromCurrency: trip.currency,
                      toCurrency: profile?.defaultCurrency ?? trip.currency,
                    ),
                    icon: const Icon(Icons.currency_exchange_rounded, size: 18),
                    label: const Text('Currency converter'),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
        const SizedBox(height: 16),
        Text('Participants', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: trip.participants.map((p) {
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: Color(p.colorValue),
                child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
              label: Text(p.isYou ? '${p.name} (You)' : p.name),
            );
          }).toList(),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 20),
        Text('Coming up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (nextItem.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No upcoming itinerary items yet.', style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
          )
        else
          Card(
            child: ListTile(
              title: Text(nextItem.first.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(formatDateTime(nextItem.first.startDateTime)),
              leading: const Icon(Icons.event_rounded),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
