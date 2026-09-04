import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_log.dart';
import '../models/enums.dart';
import '../models/expense.dart';
import '../models/itinerary_item.dart';
import '../models/packing_item.dart';
import '../models/participant.dart';
import '../models/trip.dart';
import '../models/user_profile.dart';

/// Box names.
class HiveBoxes {
  static const profiles = 'profiles';
  static const trips = 'trips';
  static const itinerary = 'itinerary';
  static const expenses = 'expenses';
  static const logs = 'logs';
  static const settings = 'settings';
  static const packing = 'packing';
}

/// Sets up local, encrypted, offline embedded storage (Hive) for the app.
///
/// An AES encryption key is generated once and kept in the platform secure
/// keystore (Keychain/Keystore) via flutter_secure_storage, so financial and
/// profile data at rest on disk stays encrypted even though the app itself
/// never needs network access.
class HiveService {
  static const _secureStorage = FlutterSecureStorage();
  static const _encryptionKeyName = 'trip_management_hive_key';

  static late Box<UserProfile> profileBox;
  static late Box<Trip> tripBox;
  static late Box<ItineraryItem> itineraryBox;
  static late Box<Expense> expenseBox;
  static late Box<AppLog> logBox;
  static late Box settingsBox;
  static late Box<PackingItem> packingBox;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    _registerAdapters();

    final key = await _getOrCreateEncryptionKey();
    final cipher = HiveAesCipher(key);

    profileBox = await Hive.openBox<UserProfile>(
      HiveBoxes.profiles,
      encryptionCipher: cipher,
    );
    tripBox = await Hive.openBox<Trip>(
      HiveBoxes.trips,
      encryptionCipher: cipher,
    );
    itineraryBox = await Hive.openBox<ItineraryItem>(
      HiveBoxes.itinerary,
      encryptionCipher: cipher,
    );
    expenseBox = await Hive.openBox<Expense>(
      HiveBoxes.expenses,
      encryptionCipher: cipher,
    );
    logBox = await Hive.openBox<AppLog>(
      HiveBoxes.logs,
      encryptionCipher: cipher,
    );
    settingsBox = await Hive.openBox(HiveBoxes.settings);
    packingBox = await Hive.openBox<PackingItem>(
      HiveBoxes.packing,
      encryptionCipher: cipher,
    );
  }

  static void _registerAdapters() {
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(TripAdapter());
    Hive.registerAdapter(ParticipantAdapter());
    Hive.registerAdapter(ItineraryItemAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(AppLogAdapter());
    Hive.registerAdapter(ItineraryTypeAdapter());
    Hive.registerAdapter(ExpenseCategoryAdapter());
    Hive.registerAdapter(SplitTypeAdapter());
    Hive.registerAdapter(PackingCategoryAdapter());
    Hive.registerAdapter(PackingItemAdapter());
  }

  static Future<List<int>> _getOrCreateEncryptionKey() async {
    final existing = await _secureStorage.read(key: _encryptionKeyName);
    if (existing != null) {
      return base64Url.decode(existing);
    }
    final key = Hive.generateSecureKey();
    await _secureStorage.write(
      key: _encryptionKeyName,
      value: base64UrlEncode(key),
    );
    return key;
  }

  static Future<void> log(String profileId, String message) async {
    final rand = Random();
    await logBox.add(
      AppLog(
        id: '${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(9999)}',
        timestamp: DateTime.now(),
        message: message,
        profileId: profileId,
      ),
    );
  }
}
