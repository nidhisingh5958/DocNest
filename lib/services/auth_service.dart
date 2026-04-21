// lib/services/auth_service.dart
// Optional app lock: biometric authentication or PIN
// All auth is local — no network required

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _localAuth = LocalAuthentication();

  static const String _kAppLockEnabled = 'app_lock_enabled';
  static const String _kPinHash        = 'pin_hash';
  static const String _kAuthType       = 'auth_type'; // 'biometric' | 'pin'

  // ── Settings ───────────────────────────────────────────────────────────────

  Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAppLockEnabled) ?? false;
  }

  Future<String> getAuthType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAuthType) ?? 'biometric';
  }

  Future<void> enableAppLock({required String type}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppLockEnabled, true);
    await prefs.setString(_kAuthType, type);
  }

  Future<void> disableAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAppLockEnabled, false);
    await prefs.remove(_kPinHash);
  }

  // ── Biometrics ─────────────────────────────────────────────────────────────

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to open DocNest',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow device PIN as fallback
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }

  // ── PIN ────────────────────────────────────────────────────────────────────

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    // Simple hash — for production use bcrypt or similar
    final hash = pin.codeUnits.fold<int>(0, (a, b) => a * 31 + b).toString();
    await prefs.setString(_kPinHash, hash);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kPinHash);
    if (stored == null) return false;
    final hash = pin.codeUnits.fold<int>(0, (a, b) => a * 31 + b).toString();
    return hash == stored;
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kPinHash);
  }
}
