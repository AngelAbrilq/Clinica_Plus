import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias NO sensibles de la app (en el dispositivo).
/// Para datos sensibles usar flutter_secure_storage.
class AppPreferences {
  AppPreferences([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _introSeenKey = 'intro_seen';

  final SharedPreferencesAsync _preferences;

  /// `true` si la intro completa ya se mostró alguna vez.
  /// Ante un error de almacenamiento asume `false` (mostrar intro).
  Future<bool> hasSeenIntro() async {
    try {
      return await _preferences.getBool(_introSeenKey) ?? false;
    } catch (error) {
      if (kDebugMode) debugPrint('[Prefs] read failed: $error');
      return false;
    }
  }

  Future<void> markIntroSeen() async {
    try {
      await _preferences.setBool(_introSeenKey, true);
    } catch (error) {
      if (kDebugMode) debugPrint('[Prefs] write failed: $error');
    }
  }
}
