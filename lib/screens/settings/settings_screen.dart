import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/backup_service.dart';
import '../../services/hive_service.dart';
import '../trips/trip_detail_screen.dart';
import 'admin_logs_screen.dart';
import 'security_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _joinTrip(BuildContext context, WidgetRef ref) async {
    try {
      final json = await BackupService.pickAndParseImportFile();
      if (json == null) return;
      final parsed = BackupService.parseImportedTrip(json);

      await HiveService.tripBox.put(parsed.trip.id, parsed.trip);
      for (final item in parsed.itinerary) {
        await HiveService.itineraryBox.put(item.id, item);
      }
      for (final expense in parsed.expenses) {
        await HiveService.expenseBox.put(expense.id, expense);
      }
      ref.read(tripsProvider.notifier).refresh();

      final profile = ref.read(currentProfileProvider);
      if (profile != null) {
        await HiveService.log(profile.id, 'Joined trip via file import: ${parsed.trip.name}');
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${parsed.trip.name}"')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: parsed.trip.id)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not import trip file: $e')),
      );
    }
  }

  void _switchProfile(WidgetRef ref) {
    ref.read(currentProfileIdProvider.notifier).set(null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primaryContainer,
                child: Text(profile?.avatarEmoji ?? '🧳', style: const TextStyle(fontSize: 22)),
              ),
              title: Text(profile?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                'Default currency: ${profile?.defaultCurrency ?? ''}'
                '${profile?.isSuperAdmin == true ? ' • Super Admin' : ''}',
              ),
            ),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                ],
                selected: {themeMode},
                onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).setMode(s.first),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Security'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_rounded),
              title: const Text('PIN & biometric lock'),
              subtitle: Text(profile?.hasSecurityLock == true ? 'Enabled' : 'Not set'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _SectionLabel('Local Collaboration'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.file_open_rounded),
              title: const Text('Join a trip from file'),
              subtitle: const Text('Import a trip shared via AirDrop, Bluetooth, or local file transfer'),
              onTap: () => _joinTrip(context, ref),
            ),
          ),
          const SizedBox(height: 20),

          if (profile?.isSuperAdmin == true) ...[
            _SectionLabel('Super Admin'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded),
                title: const Text('Device activity logs'),
                subtitle: const Text('View local app activity across profiles'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminLogsScreen()),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          Card(
            child: ListTile(
              leading: Icon(Icons.switch_account_rounded, color: scheme.error),
              title: Text('Lock / switch profile', style: TextStyle(color: scheme.error)),
              onTap: () => _switchProfile(ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
