import 'package:flutter/material.dart';

import '../models/enums.dart';

IconData iconForItineraryType(ItineraryType type) {
  switch (type) {
    case ItineraryType.flight:
      return Icons.flight_takeoff_rounded;
    case ItineraryType.train:
      return Icons.train_rounded;
    case ItineraryType.bus:
      return Icons.directions_bus_rounded;
    case ItineraryType.hotel:
      return Icons.hotel_rounded;
    case ItineraryType.activity:
      return Icons.local_activity_rounded;
    case ItineraryType.other:
      return Icons.event_note_rounded;
  }
}

String labelForItineraryType(ItineraryType type) {
  switch (type) {
    case ItineraryType.flight:
      return 'Flight';
    case ItineraryType.train:
      return 'Train';
    case ItineraryType.bus:
      return 'Bus';
    case ItineraryType.hotel:
      return 'Hotel';
    case ItineraryType.activity:
      return 'Activity';
    case ItineraryType.other:
      return 'Other';
  }
}

IconData iconForCategory(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.food:
      return Icons.restaurant_rounded;
    case ExpenseCategory.transport:
      return Icons.directions_car_rounded;
    case ExpenseCategory.lodging:
      return Icons.bed_rounded;
    case ExpenseCategory.activities:
      return Icons.hiking_rounded;
    case ExpenseCategory.shopping:
      return Icons.shopping_bag_rounded;
    case ExpenseCategory.other:
      return Icons.receipt_long_rounded;
  }
}

String labelForCategory(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.food:
      return 'Food';
    case ExpenseCategory.transport:
      return 'Transport';
    case ExpenseCategory.lodging:
      return 'Lodging';
    case ExpenseCategory.activities:
      return 'Activities';
    case ExpenseCategory.shopping:
      return 'Shopping';
    case ExpenseCategory.other:
      return 'Other';
  }
}

Color colorForCategory(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.food:
      return const Color(0xFFF59E0B);
    case ExpenseCategory.transport:
      return const Color(0xFF2F6FED);
    case ExpenseCategory.lodging:
      return const Color(0xFF8B5CF6);
    case ExpenseCategory.activities:
      return const Color(0xFF10B981);
    case ExpenseCategory.shopping:
      return const Color(0xFFEC4899);
    case ExpenseCategory.other:
      return const Color(0xFF6B7280);
  }
}

IconData iconForPackingCategory(PackingCategory category) {
  switch (category) {
    case PackingCategory.documents:
      return Icons.badge_rounded;
    case PackingCategory.clothing:
      return Icons.checkroom_rounded;
    case PackingCategory.electronics:
      return Icons.power_rounded;
    case PackingCategory.toiletries:
      return Icons.soap_rounded;
    case PackingCategory.health:
      return Icons.medical_services_rounded;
    case PackingCategory.other:
      return Icons.inventory_2_rounded;
  }
}

String labelForPackingCategory(PackingCategory category) {
  switch (category) {
    case PackingCategory.documents:
      return 'Documents';
    case PackingCategory.clothing:
      return 'Clothing';
    case PackingCategory.electronics:
      return 'Electronics';
    case PackingCategory.toiletries:
      return 'Toiletries';
    case PackingCategory.health:
      return 'Health';
    case PackingCategory.other:
      return 'Other';
  }
}
