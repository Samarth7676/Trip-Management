import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense.dart';
import '../services/hive_service.dart';

class ExpensesNotifier extends StateNotifier<List<Expense>> {
  final String tripId;

  ExpensesNotifier(this.tripId) : super(_load(tripId));

  static List<Expense> _load(String tripId) {
    final items = HiveService.expenseBox.values
        .where((e) => e.tripId == tripId)
        .toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  void refresh() => state = _load(tripId);

  Future<void> addExpense(Expense expense) async {
    await HiveService.expenseBox.put(expense.id, expense);
    refresh();
  }

  Future<void> updateExpense(Expense expense) async {
    await expense.save();
    refresh();
  }

  Future<void> deleteExpense(Expense expense) async {
    await expense.delete();
    refresh();
  }
}

final expensesProvider = StateNotifierProvider.family<ExpensesNotifier,
    List<Expense>, String>((ref, tripId) => ExpensesNotifier(tripId));
