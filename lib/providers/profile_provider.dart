import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/hive_service.dart';

class ProfilesNotifier extends StateNotifier<List<UserProfile>> {
  ProfilesNotifier() : super(HiveService.profileBox.values.toList());

  void refresh() => state = HiveService.profileBox.values.toList();

  Future<UserProfile> addProfile(UserProfile profile) async {
    await HiveService.profileBox.put(profile.id, profile);
    refresh();
    return profile;
  }

  Future<void> updateProfile(UserProfile profile) async {
    await profile.save();
    refresh();
  }

  Future<void> deleteProfile(String id) async {
    await HiveService.profileBox.delete(id);
    refresh();
  }
}

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, List<UserProfile>>((ref) => ProfilesNotifier());

/// The id of the profile currently active on this device.
class CurrentProfileIdNotifier extends StateNotifier<String?> {
  CurrentProfileIdNotifier() : super(HiveService.settingsBox.get('currentProfileId') as String?);

  void set(String? id) {
    state = id;
    if (id == null) {
      HiveService.settingsBox.delete('currentProfileId');
    } else {
      HiveService.settingsBox.put('currentProfileId', id);
    }
  }
}

final currentProfileIdProvider =
    StateNotifierProvider<CurrentProfileIdNotifier, String?>((ref) => CurrentProfileIdNotifier());

final currentProfileProvider = Provider<UserProfile?>((ref) {
  final id = ref.watch(currentProfileIdProvider);
  final profiles = ref.watch(profilesProvider);
  if (id == null) return null;
  try {
    return profiles.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

/// Whether the app is currently behind the PIN/biometric lock screen.
/// Starts locked whenever the active profile has a PIN/biometric lock set,
/// computed eagerly here rather than via an imperative call from a widget's
/// initState (which Riverpod disallows during the build phase).
class LockNotifier extends StateNotifier<bool> {
  LockNotifier() : super(_computeInitialLock());

  static bool _computeInitialLock() {
    final id = HiveService.settingsBox.get('currentProfileId') as String?;
    if (id == null) return false;
    final profile = HiveService.profileBox.get(id);
    return profile?.hasSecurityLock ?? false;
  }

  void lock() => state = true;
  void unlock() => state = false;
}

final lockProvider = StateNotifierProvider<LockNotifier, bool>((ref) => LockNotifier());
