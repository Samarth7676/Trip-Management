import '../models/expense.dart';

class Settlement {
  final String fromId;
  final String toId;
  final double amount;

  Settlement({required this.fromId, required this.toId, required this.amount});
}

class SettlementService {
  /// Computes each participant's net balance across a list of expenses.
  /// Positive => they are owed money overall. Negative => they owe money.
  static Map<String, double> computeNetBalances(
    List<Expense> expenses,
    List<String> participantIds,
  ) {
    final balances = {for (final id in participantIds) id: 0.0};

    for (final expense in expenses) {
      final shares = expense.resolveShares();
      balances[expense.payerId] =
          (balances[expense.payerId] ?? 0) + expense.amount;
      shares.forEach((participantId, share) {
        balances[participantId] = (balances[participantId] ?? 0) - share;
      });
    }

    return balances;
  }

  /// Greedy min-cash-flow debt simplification: produces the smallest set of
  /// "who pays whom" transactions that settles all net balances.
  static List<Settlement> simplifyDebts(Map<String, double> netBalances) {
    const epsilon = 0.005;
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    netBalances.forEach((id, balance) {
      if (balance > epsilon) {
        creditors.add(MapEntry(id, balance));
      } else if (balance < -epsilon) {
        debtors.add(MapEntry(id, -balance));
      }
    });

    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final settlements = <Settlement>[];
    var ci = 0;
    var di = 0;
    final creditorAmounts = creditors.map((e) => e.value).toList();
    final debtorAmounts = debtors.map((e) => e.value).toList();

    while (ci < creditors.length && di < debtors.length) {
      final owed = creditorAmounts[ci];
      final owes = debtorAmounts[di];
      final settled = owed < owes ? owed : owes;

      if (settled > epsilon) {
        settlements.add(
          Settlement(
            fromId: debtors[di].key,
            toId: creditors[ci].key,
            amount: double.parse(settled.toStringAsFixed(2)),
          ),
        );
      }

      creditorAmounts[ci] -= settled;
      debtorAmounts[di] -= settled;

      if (creditorAmounts[ci] <= epsilon) ci++;
      if (debtorAmounts[di] <= epsilon) di++;
    }

    return settlements;
  }

  static double totalSpend(List<Expense> expenses) =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  static Map<String, double> categoryBreakdown(List<Expense> expenses) {
    final breakdown = <String, double>{};
    for (final e in expenses) {
      final key = e.category.name;
      breakdown[key] = (breakdown[key] ?? 0) + e.amount;
    }
    return breakdown;
  }
}
