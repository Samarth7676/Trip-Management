import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/profile_provider.dart';
import '../../services/auth_lock_service.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  final _pinController = TextEditingController();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    AuthLockService.canCheckBiometrics().then((available) {
      if (mounted) setState(() => _biometricAvailable = available);
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _setPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits')),
      );
      return;
    }
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    profile.pinHash = AuthLockService.hashPin(pin);
    await ref.read(profilesProvider.notifier).updateProfile(profile);
    _pinController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated')));
    }
  }

  Future<void> _removePin() async {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    profile.pinHash = null;
    profile.biometricEnabled = false;
    await ref.read(profilesProvider.notifier).updateProfile(profile);
  }

  Future<void> _toggleBiometric(bool value) async {
    final profile = ref.read(currentProfileProvider);
    if (profile == null) return;
    profile.biometricEnabled = value;
    await ref.read(profilesProvider.notifier).updateProfile(profile);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PIN & Biometric Lock')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              profile?.pinHash != null ? 'Change your PIN' : 'Set a PIN',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(hintText: 'Enter a 4-6 digit PIN'),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _setPin, child: const Text('Save PIN')),
            if (profile?.pinHash != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _removePin, child: const Text('Remove PIN & biometric lock')),
            ],
            const SizedBox(height: 24),
            if (_biometricAvailable)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable biometric unlock'),
                subtitle: const Text('Use fingerprint or face unlock alongside your PIN'),
                value: profile?.biometricEnabled ?? false,
                onChanged: profile?.pinHash != null ? _toggleBiometric : null,
              ),
            if (_biometricAvailable && profile?.pinHash == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Set a PIN first to enable biometric unlock as a quick alternative.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
