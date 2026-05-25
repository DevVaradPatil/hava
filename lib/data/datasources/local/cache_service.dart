import 'dart:convert';

import 'package:hive/hive.dart';

/// Keys used for Hive cache boxes.
abstract final class CacheKeys {
  static const String weatherBox = 'weather_cache';
  static const String currentWeather = 'current_weather';
  static const String hourlyForecast = 'hourly_forecast';
  static const String currentAqi = 'current_aqi';
  static const String aqiForecast = 'aqi_forecast';

  /// Preferences box.
  static const String prefsBox = 'preferences';
  static const String onboardingComplete = 'onboarding_complete';
  static const String healthProfile = 'health_profile';
  static const String savedLocation = 'saved_location';
  static const String themeMode = 'theme_mode';

  /// Timestamp prefix — appended per key to track freshness.
  static String timestampKey(String key) => '${key}_ts';
}

/// Local cache service backed by Hive.
///
/// Stores serialised JSON strings so we avoid Hive TypeAdapters at this
/// stage. Data is read/written as `Map<String, dynamic>` or `List`.
class CacheService {
  CacheService(this._weatherBox, this._prefsBox);

  final Box<String> _weatherBox;
  final Box<dynamic> _prefsBox;

  // ──────────────────────────────────────────────
  //  Weather / AQI cache
  // ──────────────────────────────────────────────

  /// Stores a JSON-encodable value under [key] with a timestamp.
  Future<void> put(String key, dynamic value) async {
    await _weatherBox.put(key, jsonEncode(value));
    await _weatherBox.put(
      CacheKeys.timestampKey(key),
      DateTime.now().toIso8601String(),
    );
  }

  /// Reads a cached JSON string for [key] and decodes it.
  ///
  /// Returns `null` if missing or if the cache is older than [maxAge].
  dynamic get(String key, {Duration maxAge = const Duration(hours: 3)}) {
    final raw = _weatherBox.get(key);
    if (raw == null) return null;

    final tsRaw = _weatherBox.get(CacheKeys.timestampKey(key));
    if (tsRaw != null) {
      final ts = DateTime.tryParse(tsRaw);
      if (ts != null && DateTime.now().difference(ts) > maxAge) {
        return null; // stale
      }
    }

    return jsonDecode(raw);
  }

  /// Clears all weather/AQI cache.
  Future<void> clearWeatherCache() async {
    await _weatherBox.clear();
  }

  // ──────────────────────────────────────────────
  //  Preferences
  // ──────────────────────────────────────────────

  /// Whether onboarding has been completed.
  bool get isOnboardingComplete =>
      _prefsBox.get(CacheKeys.onboardingComplete, defaultValue: false) as bool;

  Future<void> setOnboardingComplete(bool value) =>
      _prefsBox.put(CacheKeys.onboardingComplete, value);

  /// Health profile index (maps to HealthProfile enum ordinal).
  int get healthProfileIndex =>
      _prefsBox.get(CacheKeys.healthProfile, defaultValue: 0) as int;

  Future<void> setHealthProfileIndex(int index) =>
      _prefsBox.put(CacheKeys.healthProfile, index);

  /// Saved location as JSON string.
  String? get savedLocationJson =>
      _prefsBox.get(CacheKeys.savedLocation) as String?;

  Future<void> setSavedLocation(String json) =>
      _prefsBox.put(CacheKeys.savedLocation, json);

  /// Theme mode: 0 = system, 1 = light, 2 = dark.
  int get themeModeIndex =>
      _prefsBox.get(CacheKeys.themeMode, defaultValue: 0) as int;

  Future<void> setThemeModeIndex(int index) =>
      _prefsBox.put(CacheKeys.themeMode, index);
}
