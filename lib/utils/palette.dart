import 'package:flutter/material.dart';

/// Brand-neutral palette used for participant avatars and trip covers.
const List<Color> kPalette = [
  Color(0xFF2F6FED),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFF06B6D4),
  Color(0xFFEC4899),
  Color(0xFF84CC16),
];

Color paletteColorFor(int index) => kPalette[index % kPalette.length];

const List<String> kAvatarEmojis = [
  '🧳', '🌍', '✈️', '🏖️', '🗺️', '🎒', '🚀', '🌴', '⛰️', '🏝️',
];

const List<String> kCoverEmojis = [
  '🏝️', '🏔️', '🏙️', '🗽', '🗼', '🏰', '⛩️', '🌋', '🏞️', '🚆',
];

const List<String> kCurrencies = [
  'USD', 'EUR', 'GBP', 'INR', 'JPY', 'AUD', 'CAD', 'AED', 'THB', 'CNY', 'SGD',
];
