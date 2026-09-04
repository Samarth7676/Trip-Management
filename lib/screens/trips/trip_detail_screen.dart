import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/expense_provider.dart';
import '../../providers/itinerary_provider.dart';
import '../../providers/packing_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/backup_service.dart';
import '../../services/hive_service.dart';
import '../../services/pdf_service.dart';
import '../emergency/emergency_tab.dart';
import '../expenses/balances_tab.dart';
import '../expenses/expenses_tab.dart';
import '../itinerary/itinerary_tab.dart';
import '../packing/packing_tab.dart';
import 'edit_trip_screen.dart';
import 'trip_overview_tab.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(BuildContext context) async {
    final trip = ref.read(tripByIdProvider(widget.tripId));
    if (trip == null) return;
    setState(() => _busy = true);
    try {
      final itinerary = ref.read(itineraryProvider(widget.tripId));
      final expenses = ref.read(expensesProvider(widget.tripId));
      final packing = ref.read(packingProvider(widget.tripId));
      await PdfService.exportAndShareTripSummary(
        trip: trip,
        expenses: expenses,
        itinerary: itinerary,
        packing: packing,
      );
      final profile = ref.read(currentProfileProvider);
      if (profile != null) {
        await HiveService.log(profile.id, 'PDF summary exported for trip: ${trip.name}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareTripFile(BuildContext context) async {
    final trip = ref.read(tripByIdProvider(widget.tripId));
    if (trip == null) return;
    setState(() => _busy = true);
    try {
      final itinerary = ref.read(itineraryProvider(widget.tripId));
      final expenses = ref.read(expensesProvider(widget.tripId));
      final json = BackupService.tripToJson(trip, itinerary, expenses);
      final file = await BackupService.exportTripToFile(json, trip.name);
      await BackupService.shareTripFile(file, trip.name);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final trip = ref.read(tripByIdProvider(widget.tripId));
    if (trip == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text('This will permanently delete "${trip.name}" and all its itinerary and expense data from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(tripsProvider.notifier).deleteTrip(trip.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripByIdProvider(widget.tripId));
    if (trip == null) {
      return const Scaffold(body: Center(child: Text('Trip not found')));
    }

    final coverColor = Color(trip.coverColorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [coverColor, Color.lerp(coverColor, Colors.black, 0.35)!],
            ),
          ),
        ),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'pdf':
                    _exportPdf(context);
                    break;
                  case 'share':
                    _shareTripFile(context);
                    break;
                  case 'edit':
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EditTripScreen(tripId: trip.id)),
                    );
                    break;
                  case 'delete':
                    _confirmDelete(context);
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'pdf', child: Text('Export PDF summary')),
                PopupMenuItem(value: 'share', child: Text('Share trip file (offline)')),
                PopupMenuItem(value: 'edit', child: Text('Edit trip')),
                PopupMenuItem(value: 'delete', child: Text('Delete trip')),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Itinerary'),
            Tab(text: 'Packing'),
            Tab(text: 'Expenses'),
            Tab(text: 'Balances'),
            Tab(text: 'Emergency'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TripOverviewTab(tripId: trip.id),
          ItineraryTab(tripId: trip.id),
          PackingTab(tripId: trip.id),
          ExpensesTab(tripId: trip.id),
          BalancesTab(tripId: trip.id),
          EmergencyTab(destination: trip.destination),
        ],
      ),
    );
  }
}
