import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding/animated_splash_screen.dart';
import 'screens/onboarding/lock_screen.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/trips/home_shell.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await NotificationService.init();
  runApp(const ProviderScope(child: TripManagementApp()));
}

class TripManagementApp extends ConsumerWidget {
  const TripManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Trip Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AppRoot(),
    );
  }
}

class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return AnimatedSplashScreen(onFinished: () => setState(() => _showSplash = false));
    }

    final profile = ref.watch(currentProfileProvider);

    if (profile == null) {
      return const ProfileSetupScreen();
    }

    final locked = ref.watch(lockProvider);
    if (locked) {
      return const LockScreen();
    }

    return const HomeShell();
  }
}
