import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/expense_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/settlement_service.dart';
import '../../utils/formatters.dart';

class BalancesTab extends ConsumerWidget {
  final String tripId;

  const BalancesTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripByIdProvider(tripId));
    final expenses = ref.watch(expensesProvider(tripId));
    if (trip == null) return const SizedBox.shrink();

    final participantIds = trip.participants.map((p) => p.id).toList();
    final byId = {for (final p in trip.participants) p.id: p};
    final balances = SettlementService.computeNetBalances(expenses, participantIds);
    final settlements = SettlementService.simplifyDebts(balances);
    final scheme = Theme.of(context).colorScheme;

    final maxAbs = balances.values.fold<double>(0.01, (m, v) => v.abs() > m ? v.abs() : m);

    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚖️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('Nothing to settle yet', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('Log some expenses to see balances here.',
                  textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ).animate().fadeIn(duration: 300.ms),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('Net balances', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...balances.entries.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final p = byId[e.key];
          if (p == null) return const SizedBox.shrink();
          final isPositive = e.value >= 0;
          final fraction = (e.value.abs() / maxAbs).clamp(0.0, 1.0);
          final barColor = isPositive ? const Color(0xFF10B981) : scheme.error;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
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
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(p.colorValue),
                        child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(isPositive ? 'is owed' : 'owes', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(
                        formatMoney(e.value.abs(), trip.currency),
                        style: TextStyle(fontWeight: FontWeight.w800, color: barColor, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 6,
                      child: Stack(
                        children: [
                          Container(color: scheme.surfaceContainerHighest),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: fraction),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => FractionallySizedBox(
                              widthFactor: value,
                              alignment: Alignment.centerLeft,
                              child: Container(color: barColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (40 * i).ms, duration: 300.ms).slideX(begin: 0.05, end: 0);
        }),
        const SizedBox(height: 24),
        Text('Settle up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (settlements.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0D9668)]),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Everyone is settled up!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1))
        else
          ...settlements.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final from = byId[s.fromId];
            final to = byId[s.toId];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: from != null ? Color(from.colorValue) : scheme.primary,
                      child: Text(from?.name.isNotEmpty == true ? from!.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.arrow_forward_rounded, size: 16, color: scheme.onSurfaceVariant),
                    ),
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: to != null ? Color(to.colorValue) : scheme.primary,
                      child: Text(to?.name.isNotEmpty == true ? to!.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${from?.name ?? s.fromId} pays ${to?.name ?? s.toId}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                    Text(formatMoney(s.amount, trip.currency), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (40 * i).ms, duration: 300.ms).slideX(begin: 0.05, end: 0);
          }),
      ],
    );
  }
}
