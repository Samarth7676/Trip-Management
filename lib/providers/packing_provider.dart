import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/packing_item.dart';
import '../services/hive_service.dart';

class PackingNotifier extends StateNotifier<List<PackingItem>> {
  final String tripId;

  PackingNotifier(this.tripId) : super(_load(tripId));

  static List<PackingItem> _load(String tripId) {
    final items = HiveService.packingBox.values
        .where((i) => i.tripId == tripId)
        .toList();
    items.sort((a, b) => a.title.compareTo(b.title));
    return items;
  }

  void refresh() => state = _load(tripId);

  Future<void> addItem(PackingItem item) async {
    await HiveService.packingBox.put(item.id, item);
    refresh();
  }

  Future<void> togglePacked(PackingItem item) async {
    item.isPacked = !item.isPacked;
    await item.save();
    refresh();
  }

  Future<void> deleteItem(PackingItem item) async {
    await item.delete();
    refresh();
  }
}

final packingProvider = StateNotifierProvider.family<PackingNotifier,
    List<PackingItem>, String>((ref, tripId) => PackingNotifier(tripId));
