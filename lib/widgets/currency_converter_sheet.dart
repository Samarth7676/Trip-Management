import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// A manual, fully-offline currency converter: the user enters their own
/// exchange rate (there is no live-rate lookup, per the app's offline-only
/// design) and gets an instant converted amount.
class CurrencyConverterSheet extends StatefulWidget {
  final String fromCurrency;
  final String toCurrency;

  const CurrencyConverterSheet({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
  });

  static Future<void> show(BuildContext context, {required String fromCurrency, required String toCurrency}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CurrencyConverterSheet(fromCurrency: fromCurrency, toCurrency: toCurrency),
    );
  }

  @override
  State<CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<CurrencyConverterSheet> {
  final _amountController = TextEditingController(text: '100');
  final _rateController = TextEditingController(text: '1');

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;
  double get _rate => double.tryParse(_rateController.text.trim()) ?? 0;

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final converted = _amount * _rate;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange_rounded),
              const SizedBox(width: 10),
              Text('Currency converter', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Offline — enter today\'s rate manually.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: 'Amount (${widget.fromCurrency})'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: '1 ${widget.fromCurrency} =',
              suffixText: widget.toCurrency,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Converted amount', style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  formatMoney(converted, widget.toCurrency),
                  style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
