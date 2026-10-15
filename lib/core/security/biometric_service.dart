import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biometric authentication service — fingerprint/face unlock.
class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final _auth = LocalAuthentication();
  static const _keyEnabled = 'biometric_enabled';

  /// Check if device supports biometric auth.
  Future<bool> get isAvailable async {
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types.
  Future<List<BiometricType>> get availableTypes async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Authenticate the user.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Buka kunci Cuan dengan biometrik',
        biometricOnly: true,
      );
    } on PlatformException {
      return false;
    }
  }

  /// Check if biometric lock is enabled by user.
  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  /// Save user preference.
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
  }
}
