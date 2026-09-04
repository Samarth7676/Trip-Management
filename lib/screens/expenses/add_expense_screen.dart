import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/trip_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/icon_helpers.dart';
import '../../utils/id.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String tripId;
  final Expense? existing;

  const AddExpenseScreen({super.key, required this.tripId, this.existing});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _splitControllers = {};

  ExpenseCategory _category = ExpenseCategory.food;
  SplitType _splitType = SplitType.equal;
  String? _payerId;
  Set<String> _selectedParticipantIds = {};
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _amountController.text = e.amount.toString();
      _notesController.text = e.notes;
      _category = e.category;
      _splitType = e.splitType;
      _payerId = e.payerId;
      _selectedParticipantIds = e.participantIds.toSet();
      _date = e.date;
      for (final entry in e.splitValues.entries) {
        _splitControllers[entry.key] = TextEditingController(text: entry.value.toString());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String participantId) {
    return _splitControllers.putIfAbsent(participantId, () => TextEditingController());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final trip = ref.read(tripByIdProvider(widget.tripId));
    if (trip == null) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid title and amount')),
      );
      return;
    }
    if (_payerId == null || _selectedParticipantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a payer and at least one participant')),
      );
      return;
    }

    final participantIds = _selectedParticipantIds.toList();
    Map<String, double> splitValues = {};

    if (_splitType == SplitType.exact) {
      double sum = 0;
      for (final id in participantIds) {
        final v = double.tryParse(_controllerFor(id).text.trim()) ?? 0;
        splitValues[id] = v;
        sum += v;
      }
      if ((sum - amount).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exact amounts must sum to ${formatMoney(amount, trip.currency)} (currently ${formatMoney(sum, trip.currency)})')),
        );
        return;
      }
    } else if (_splitType == SplitType.percentage) {
      double sum = 0;
      for (final id in participantIds) {
        final v = double.tryParse(_controllerFor(id).text.trim()) ?? 0;
        splitValues[id] = v;
        sum += v;
      }
      if ((sum - 100).abs() > 0.5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Percentages must sum to 100% (currently ${sum.toStringAsFixed(1)}%)')),
        );
        return;
      }
    }

    final notifier = ref.read(expensesProvider(widget.tripId).notifier);

    if (widget.existing != null) {
      final e = widget.existing!;
      e.title = title;
      e.category = _category;
      e.amount = amount;
      e.payerId = _payerId!;
      e.participantIds = participantIds;
      e.splitType = _splitType;
      e.splitValues = splitValues;
      e.date = _date;
      e.notes = _notesController.text.trim();
      await notifier.updateExpense(e);
    } else {
      final expense = Expense(
        id: newId(),
        tripId: widget.tripId,
        title: title,
        category: _category,
        amount: amount,
        currency: trip.currency,
        payerId: _payerId!,
        participantIds: participantIds,
        splitType: _splitType,
        splitValues: splitValues,
        date: _date,
        notes: _notesController.text.trim(),
      );
      await notifier.addExpense(expense);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripByIdProvider(widget.tripId));
    if (trip == null) return const Scaffold(body: SizedBox.shrink());

    if (_payerId == null && trip.participants.isNotEmpty) {
      _payerId = trip.participants.first.id;
    }
    if (_selectedParticipantIds.isEmpty && widget.existing == null) {
      _selectedParticipantIds = trip.participants.map((p) => p.id).toSet();
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Edit Expense' : 'Add Expense')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExpenseCategory.values.map((c) {
                return ChoiceChip(
                  avatar: Icon(iconForCategory(c), size: 18),
                  label: Text(labelForCategory(c)),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text('Title', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Dinner at Sunset Cafe'),
            ),
            const SizedBox(height: 16),

            Text('Amount (${trip.currency})', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '0.00'),
            ),
            const SizedBox(height: 16),

            Text('Date', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text(formatDate(_date)),
            ),
            const SizedBox(height: 16),

            Text('Paid by', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trip.participants.map((p) {
                return ChoiceChip(
                  label: Text(p.name),
                  selected: _payerId == p.id,
                  onSelected: (_) => setState(() => _payerId = p.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text('Split between', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trip.participants.map((p) {
                final selected = _selectedParticipantIds.contains(p.id);
                return FilterChip(
                  label: Text(p.name),
                  selected: selected,
                  onSelected: (val) => setState(() {
                    if (val) {
                      _selectedParticipantIds.add(p.id);
                    } else {
                      _selectedParticipantIds.remove(p.id);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text('Split method', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<SplitType>(
              segments: const [
                ButtonSegment(value: SplitType.equal, label: Text('Equal')),
                ButtonSegment(value: SplitType.exact, label: Text('Exact')),
                ButtonSegment(value: SplitType.percentage, label: Text('Percent')),
              ],
              selected: {_splitType},
              onSelectionChanged: (s) => setState(() => _splitType = s.first),
            ),
            const SizedBox(height: 12),

            if (_splitType != SplitType.equal)
              Column(
                children: trip.participants
                    .where((p) => _selectedParticipantIds.contains(p.id))
                    .map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(p.name)),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _controllerFor(p.id),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              suffixText: _splitType == SplitType.percentage ? '%' : trip.currency,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 8),
            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Optional'),
            ),
            const SizedBox(height: 28),

            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
