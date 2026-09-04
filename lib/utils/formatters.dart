import 'package:intl/intl.dart';

String formatMoney(double amount, String currency) {
  final formatter = NumberFormat.currency(
    name: currency,
    symbol: currencySymbol(currency),
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

String currencySymbol(String code) {
  const symbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'AED': 'د.إ',
    'THB': '฿',
    'CNY': '¥',
    'SGD': 'S\$',
  };
  return symbols[code] ?? '$code ';
}

String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

String formatDateShort(DateTime date) => DateFormat('MMM d').format(date);

String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

String formatDateTime(DateTime date) =>
    DateFormat('MMM d, yyyy • h:mm a').format(date);

String formatDateRange(DateTime start, DateTime end) {
  if (start.year == end.year && start.month == end.month) {
    return '${DateFormat('MMM d').format(start)} - ${DateFormat('d, yyyy').format(end)}';
  }
  return '${formatDateShort(start)} - ${formatDate(end)}';
}
