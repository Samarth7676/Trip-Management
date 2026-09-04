import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/itinerary_item.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class ItineraryNotifier extends StateNotifier<List<ItineraryItem>> {
  final String tripId;

  ItineraryNotifier(this.tripId) : super(_load(tripId));

  static List<ItineraryItem> _load(String tripId) {
    final items = HiveService.itineraryBox.values
        .where((i) => i.tripId == tripId)
        .toList();
    items.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return items;
  }

  void refresh() => state = _load(tripId);

  Future<void> addItem(ItineraryItem item) async {
    await HiveService.itineraryBox.put(item.id, item);
    await NotificationService.scheduleForItineraryItem(item);
    refresh();
  }

  Future<void> updateItem(ItineraryItem item) async {
    await item.save();
    await NotificationService.cancel(item.notificationId);
    await NotificationService.scheduleForItineraryItem(item);
    refresh();
  }

  Future<void> deleteItem(ItineraryItem item) async {
    await NotificationService.cancel(item.notificationId);
    await item.delete();
    refresh();
  }
}

final itineraryProvider = StateNotifierProvider.family<ItineraryNotifier,
    List<ItineraryItem>, String>((ref, tripId) => ItineraryNotifier(tripId));
