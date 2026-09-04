import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../providers/expense_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/settlement_service.dart';
import '../../utils/formatters.dart';
import '../../utils/icon_helpers.dart';
import '../../widgets/gradient_icon_badge.dart';
import '../../widgets/swipe_to_delete.dart';
import 'add_expense_screen.dart';

class ExpensesTab extends ConsumerStatefulWidget {
  final String tripId;

  const ExpensesTab({super.key, required this.tripId});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  ExpenseCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripByIdProvider(widget.tripId));
    final allExpenses = ref.watch(expensesProvider(widget.tripId));
    final scheme = Theme.of(context).colorScheme;
    if (trip == null) return const SizedBox.shrink();

    final expenses = _filter == null ? allExpenses : allExpenses.where((e) => e.category == _filter).toList();
    final total = SettlementService.totalSpend(allExpenses);
    final usedCategories = allExpenses.map((e) => e.category).toSet();

    return Scaffold(
      body: Column(
        children: [
          if (allExpenses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.3)!],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total spent', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(formatMoney(total, trip.currency),
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${allExpenses.length} logged',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),

          if (usedCategories.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    ...usedCategories.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: labelForCategory(c),
                            icon: iconForCategory(c),
                            color: colorForCategory(c),
                            selected: _filter == c,
                            onTap: () => setState(() => _filter = c),
                          ),
                        )),
                  ],
                ),
              ),
            ),

          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💸', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          Text(allExpenses.isEmpty ? 'No expenses yet' : 'Nothing in this category',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text('Log spend to track balances and who owes whom.',
                              textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) => _ExpenseCard(expense: expenses[index], trip: trip, index: index),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_expense',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddExpenseScreen(tripId: widget.tripId)),
          );
        },
        child: const Icon(Icons.add_rounded),
      ).animate().scale(delay: 150.ms, duration: 250.ms, curve: Curves.easeOutBack),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, this.icon, this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = color ?? scheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? baseColor : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : scheme.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(
              color: selected ? Colors.white : scheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  final Expense expense;
  final Trip trip;
  final int index;

  const _ExpenseCard({required this.expense, required this.trip, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final payer = trip.participants.firstWhere(
      (p) => p.id == expense.payerId,
      orElse: () => trip.participants.first,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwipeToDelete(
        keyValue: expense.id,
        confirmTitle: 'Delete "${expense.title}"?',
        onDelete: () => ref.read(expensesProvider(expense.tripId).notifier).deleteExpense(expense),
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddExpenseScreen(tripId: expense.tripId, existing: expense)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GradientIconBadge(icon: iconForCategory(expense.category), color: colorForCategory(expense.category)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(
                          'Paid by ${payer.name} • ${formatDate(expense.date)}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(expense.amount, expense.currency),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (30 * index).ms, duration: 280.ms).slideY(begin: 0.05, end: 0);
  }
}
