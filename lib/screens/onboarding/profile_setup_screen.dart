import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/profile_provider.dart';
import '../../services/auth_lock_service.dart';
import '../../services/hive_service.dart';
import '../../utils/id.dart';
import '../../utils/palette.dart';
import '../../widgets/app_logo.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  String _avatar = kAvatarEmojis.first;
  String _currency = kCurrencies.first;
  bool _enablePin = false;
  bool _enableBiometric = false;
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
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    if (_enablePin && _pinController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits')),
      );
      return;
    }

    final isFirstProfile = HiveService.profileBox.isEmpty;

    final profile = UserProfile(
      id: newId(),
      name: name,
      avatarEmoji: _avatar,
      defaultCurrency: _currency,
      pinHash: _enablePin ? AuthLockService.hashPin(_pinController.text.trim()) : null,
      biometricEnabled: _enableBiometric && _biometricAvailable,
      isSuperAdmin: isFirstProfile,
      createdAt: DateTime.now(),
    );

    await ref.read(profilesProvider.notifier).addProfile(profile);
    ref.read(currentProfileIdProvider.notifier).set(profile.id);
    await HiveService.log(profile.id, 'Profile created: ${profile.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const AppLogo(size: 64),
              const SizedBox(height: 16),
              Text(
                'Welcome to Trip Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your local, offline profile. Everything stays on this device.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              Text('Choose an avatar', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: kAvatarEmojis.map((emoji) {
                  final selected = emoji == _avatar;
                  return GestureDetector(
                    onTap: () => setState(() => _avatar = emoji),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              Text('Your name', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'e.g. Alex Rivera'),
              ),
              const SizedBox(height: 24),

              Text('Default currency', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCurrencies.map((c) {
                  return ChoiceChip(
                    label: Text(c),
                    selected: _currency == c,
                    onSelected: (_) => setState(() => _currency = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Secure with a PIN'),
                subtitle: const Text('Protect your trips and financial data locally'),
                value: _enablePin,
                onChanged: (v) => setState(() => _enablePin = v),
              ),
              if (_enablePin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(hintText: 'Enter a 4-6 digit PIN'),
                  ),
                ),
              if (_biometricAvailable)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable biometric unlock'),
                  subtitle: const Text('Use fingerprint or face unlock'),
                  value: _enableBiometric,
                  onChanged: (v) => setState(() => _enableBiometric = v),
                ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _createProfile,
                  child: const Text('Get Started'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
