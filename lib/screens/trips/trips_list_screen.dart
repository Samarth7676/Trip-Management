import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/trip.dart';
import '../../models/user_profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/trip_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flip_page_route.dart';
import '../../widgets/tilt_press.dart';
import '../../widgets/trip_pass_card.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripsListScreen extends ConsumerWidget {
  const TripsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripsProvider);
    final profile = ref.watch(currentProfileProvider);
    final scheme = Theme.of(context).colorScheme;

    final active = trips.where((t) => t.isActive).toList();
    final upcoming = trips.where((t) => t.isUpcoming).toList();
    final past = trips.where((t) => t.isPast).toList();

    return Scaffold(
      body: trips.isEmpty
          ? Column(
              children: [
                _GradientHeader(profile: profile),
                Expanded(child: _EmptyState(onCreate: () => _openCreateTrip(context))),
              ],
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _GradientHeader(profile: profile)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (active.isNotEmpty) _Section(title: 'Active now', trips: active, startIndex: 0),
                      if (upcoming.isNotEmpty) _Section(title: 'Upcoming', trips: upcoming, startIndex: active.length),
                      if (past.isNotEmpty) _Section(title: 'Past trips', trips: past, startIndex: active.length + upcoming.length),
                    ]),
                  ),
                ),
              ],
            ),
      backgroundColor: scheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateTrip(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Trip'),
      ).animate().scale(delay: 200.ms, duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  void _openCreateTrip(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateTripScreen()),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  final UserProfile? profile;

  const _GradientHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.seed, Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${profile?.name.split(' ').first ?? 'there'} 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.08, end: 0),
                const SizedBox(height: 4),
                Text(
                  'Where to next?',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(profile?.avatarEmoji ?? '🧳', style: const TextStyle(fontSize: 22)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Trip> trips;
  final int startIndex;

  const _Section({required this.title, required this.trips, required this.startIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        ...trips.asMap().entries.map((e) => _TripCard(trip: e.value, index: startIndex + e.key)),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final int index;

  const _TripCard({required this.trip, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TiltPress(
        onTap: () {
          Navigator.of(context).push(
            Flip3DPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
          );
        },
        child: TripPassCard(trip: trip),
      ),
    )
        .animate()
        .fadeIn(delay: (60 * index).ms, duration: 350.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 64))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -6, end: 6, duration: 1600.ms, curve: Curves.easeInOut),
            const SizedBox(height: 16),
            Text('No trips yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Create your first trip to start planning itineraries and splitting expenses — fully offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a trip'),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}
