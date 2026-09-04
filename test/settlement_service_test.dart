import 'package:flutter_test/flutter_test.dart';
import 'package:trip_management/models/enums.dart';
import 'package:trip_management/models/expense.dart';
import 'package:trip_management/services/settlement_service.dart';

void main() {
  group('SettlementService', () {
    test('equal split produces correct net balances', () {
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 't1',
          title: 'Dinner',
          category: ExpenseCategory.food,
          amount: 90,
          currency: 'USD',
          payerId: 'a',
          participantIds: ['a', 'b', 'c'],
          splitType: SplitType.equal,
          splitValues: const {},
          date: DateTime(2026, 1, 1),
        ),
      ];

      final balances = SettlementService.computeNetBalances(expenses, ['a', 'b', 'c']);

      expect(balances['a'], closeTo(60, 0.001));
      expect(balances['b'], closeTo(-30, 0.001));
      expect(balances['c'], closeTo(-30, 0.001));
    });

    test('simplifyDebts settles balances with minimal transactions', () {
      final expenses = [
        Expense(
          id: 'e1',
          tripId: 't1',
          title: 'Hotel',
          category: ExpenseCategory.lodging,
          amount: 300,
          currency: 'USD',
          payerId: 'a',
          participantIds: ['a', 'b', 'c'],
          splitType: SplitType.equal,
          splitValues: const {},
          date: DateTime(2026, 1, 1),
        ),
        Expense(
          id: 'e2',
          tripId: 't1',
          title: 'Groceries',
          category: ExpenseCategory.food,
          amount: 60,
          currency: 'USD',
          payerId: 'b',
          participantIds: ['a', 'b', 'c'],
          splitType: SplitType.equal,
          splitValues: const {},
          date: DateTime(2026, 1, 2),
        ),
      ];

      final balances = SettlementService.computeNetBalances(expenses, ['a', 'b', 'c']);
      final settlements = SettlementService.simplifyDebts(balances);

      final totalPaid = settlements.fold<double>(0, (sum, s) => sum + s.amount);
      final totalOwed = balances.values.where((v) => v < 0).fold<double>(0, (s, v) => s - v);
      expect(totalPaid, closeTo(totalOwed, 0.01));

      // No participant should appear as both a payer and receiver in the
      // simplified settlement plan.
      final froms = settlements.map((s) => s.fromId).toSet();
      final tos = settlements.map((s) => s.toId).toSet();
      expect(froms.intersection(tos), isEmpty);
    });

    test('exact split resolves shares directly', () {
      final expense = Expense(
        id: 'e1',
        tripId: 't1',
        title: 'Taxi',
        category: ExpenseCategory.transport,
        amount: 50,
        currency: 'USD',
        payerId: 'a',
        participantIds: ['a', 'b'],
        splitType: SplitType.exact,
        splitValues: const {'a': 20, 'b': 30},
        date: DateTime(2026, 1, 1),
      );

      final shares = expense.resolveShares();
      expect(shares['a'], 20);
      expect(shares['b'], 30);
    });

    test('percentage split resolves shares proportionally', () {
      final expense = Expense(
        id: 'e1',
        tripId: 't1',
        title: 'Tour',
        category: ExpenseCategory.activities,
        amount: 200,
        currency: 'USD',
        payerId: 'a',
        participantIds: ['a', 'b'],
        splitType: SplitType.percentage,
        splitValues: const {'a': 25, 'b': 75},
        date: DateTime(2026, 1, 1),
      );

      final shares = expense.resolveShares();
      expect(shares['a'], closeTo(50, 0.001));
      expect(shares['b'], closeTo(150, 0.001));
    });
  });
}
