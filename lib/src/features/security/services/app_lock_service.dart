import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for app security (PIN/Fingerprint lock)
class AppLockService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  static const String _pinKey = 'app_lock_pin';
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _biometricEnabledKey = 'biometric_enabled';
  
  /// Check if device supports biometric authentication
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }
  
  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }
  
  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access CalcNote',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }
  
  /// Set PIN
  static Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }
  
  /// Verify PIN
  static Future<bool> verifyPin(String pin) async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    return storedPin == pin;
  }
  
  /// Check if PIN is set
  static Future<bool> isPinSet() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }
  
  /// Enable app lock
  static Future<void> enableLock() async {
    await _secureStorage.write(key: _lockEnabledKey, value: 'true');
  }
  
  /// Disable app lock
  static Future<void> disableLock() async {
    await _secureStorage.write(key: _lockEnabledKey, value: 'false');
  }
  
  /// Check if app lock is enabled
  static Future<bool> isLockEnabled() async {
    final enabled = await _secureStorage.read(key: _lockEnabledKey);
    return enabled == 'true';
  }
  
  /// Enable biometric authentication
  static Future<void> enableBiometric() async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
  }
  
  /// Disable biometric authentication
  static Future<void> disableBiometric() async {
    await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
  }
  
  /// Check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }
  
  /// Remove PIN
  static Future<void> removePin() async {
    await _secureStorage.delete(key: _pinKey);
  }
  
  /// Authenticate (try biometric first, then PIN)
  static Future<bool> authenticate() async {
    // Try biometric if enabled
    if (await isBiometricEnabled() && await isBiometricAvailable()) {
      return await authenticateWithBiometrics();
    }
    
    // Otherwise, require PIN entry through UI
    return false;
  }
  
  /// Reset all security settings
  static Future<void> resetSecurity() async {
    await _secureStorage.delete(key: _pinKey);
    await _secureStorage.delete(key: _lockEnabledKey);
    await _secureStorage.delete(key: _biometricEnabledKey);
  }
}
