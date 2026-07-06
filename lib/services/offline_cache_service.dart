import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  Future<void> saveJson(String key, Map<String, dynamic> value) async {
    await _ensureInitialized();
    await _prefs?.setString(key, jsonEncode(value));
  }

  Future<Map<String, dynamic>?> loadJson(String key) async {
    await _ensureInitialized();
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OfflineCacheService: failed to decode json for $key: $e');
      return null;
    }
  }

  Future<void> saveJsonList(String key, List<Map<String, dynamic>> values) async {
    await _ensureInitialized();
    final payload = values.map((item) => item).toList();
    await _prefs?.setString(key, jsonEncode(payload));
  }

  Future<List<Map<String, dynamic>>> loadJsonList(String key) async {
    await _ensureInitialized();
    final raw = _prefs?.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      debugPrint('OfflineCacheService: failed to decode list for $key: $e');
      return [];
    }
  }

  Future<void> saveStringList(String key, List<String> values) async {
    await _ensureInitialized();
    await _prefs?.setStringList(key, values);
  }

  Future<List<String>> loadStringList(String key) async {
    await _ensureInitialized();
    return _prefs?.getStringList(key) ?? [];
  }

  Future<void> remove(String key) async {
    await _ensureInitialized();
    await _prefs?.remove(key);
  }
}
