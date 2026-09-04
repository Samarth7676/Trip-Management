// Basic smoke test: the app boots to the profile setup screen when no
// local profile exists yet (fresh install / cleared app data).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:trip_management/main.dart';
import 'package:trip_management/services/hive_service.dart';

void main() {
  setUpAll(() async {
    Hive.init('./.dart_tool/hive_test');
    HiveService.profileBox = await Hive.openBox('profiles_test');
    HiveService.settingsBox = await Hive.openBox('settings_test');
  });

  testWidgets('Shows profile setup when no local profile exists', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TripManagementApp()));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Trip Management'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
