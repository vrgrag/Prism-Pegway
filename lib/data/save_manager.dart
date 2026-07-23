import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences that stores the whole game state as one
/// JSON blob. All reads are defensive: corrupted or missing data returns an
/// empty map instead of throwing, so the app never crashes on bad saves.
class SaveManager {
  static const String _key = 'prism_pegway_save_v1';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Map<String, dynamic> load() {
    try {
      final raw = _prefs?.getString(_key);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      // Corrupted save — start fresh rather than crash.
      return {};
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    try {
      await _prefs?.setString(_key, jsonEncode(data));
    } catch (_) {
      // Persisting failed (e.g. storage full); ignore to keep gameplay alive.
    }
  }

  Future<void> clear() async {
    try {
      await _prefs?.remove(_key);
    } catch (_) {}
  }
}
