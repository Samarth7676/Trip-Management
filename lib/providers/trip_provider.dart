import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip.dart';
import '../services/hive_service.dart';

class TripsNotifier extends StateNotifier<List<Trip>> {
  TripsNotifier() : super(_sorted());

  static List<Trip> _sorted() {
    final trips = HiveService.tripBox.values.toList();
    trips.sort((a, b) => a.startDate.compareTo(b.startDate));
    return trips;
  }

  void refresh() => state = _sorted();

  Future<void> addTrip(Trip trip) async {
    await HiveService.tripBox.put(trip.id, trip);
    refresh();
  }

  Future<void> updateTrip(Trip trip) async {
    await trip.save();
    refresh();
  }

  Future<void> deleteTrip(String id) async {
    final trip = HiveService.tripBox.get(id);
    await trip?.delete();
    // Cascade-delete related itinerary items and expenses.
    final itineraryKeys = HiveService.itineraryBox.values
        .where((i) => i.tripId == id)
        .map((i) => i.key)
        .toList();
    await HiveService.itineraryBox.deleteAll(itineraryKeys);

    final expenseKeys = HiveService.expenseBox.values
        .where((e) => e.tripId == id)
        .map((e) => e.key)
        .toList();
    await HiveService.expenseBox.deleteAll(expenseKeys);

    final packingKeys = HiveService.packingBox.values
        .where((p) => p.tripId == id)
        .map((p) => p.key)
        .toList();
    await HiveService.packingBox.deleteAll(packingKeys);

    refresh();
  }
}

final tripsProvider =
    StateNotifierProvider<TripsNotifier, List<Trip>>((ref) => TripsNotifier());

final tripByIdProvider = Provider.family<Trip?, String>((ref, id) {
  final trips = ref.watch(tripsProvider);
  try {
    return trips.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
});
