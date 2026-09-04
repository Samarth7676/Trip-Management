import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

/// Handles the optional PIN / biometric lock that protects the local
/// profile and its financial data, per the PRD's offline security
/// requirement (no server-side auth involved).
class AuthLockService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static String hashPin(String pin) {
    final bytes = utf8.encode('trip_management_salt::$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPin(String pin, String storedHash) =>
      hashPin(pin) == storedHash;

  static Future<bool> canCheckBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock Trip Management',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
