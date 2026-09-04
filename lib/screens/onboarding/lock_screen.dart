import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/profile_provider.dart';
import '../../services/auth_lock_service.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    if (profile != null && profile.biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  Future<void> _tryBiometric() async {
    final success = await AuthLockService.authenticateWithBiometrics();
    if (success && mounted) {
      ref.read(lockProvider.notifier).unlock();
    }
  }

  void _submitPin() {
    final profile = ref.read(currentProfileProvider);
    if (profile?.pinHash == null) return;
    final ok = AuthLockService.verifyPin(_pinController.text.trim(), profile!.pinHash!);
    if (ok) {
      ref.read(lockProvider.notifier).unlock();
    } else {
      setState(() => _error = 'Incorrect PIN, try again');
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(profile?.avatarEmoji ?? '🔒', style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 16),
                Text('Welcome back, ${profile?.name ?? ''}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),
                if (profile?.pinHash != null) ...[
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _submitPin(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: _submitPin, child: const Text('Unlock')),
                  ),
                ],
                if (profile?.biometricEnabled == true) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Use biometric unlock'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
