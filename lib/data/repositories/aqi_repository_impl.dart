import 'package:flutter/foundation.dart';
import 'package:hava/data/datasources/local/cache_service.dart';
import 'package:hava/data/datasources/remote/weather_api_service.dart';
import 'package:hava/data/datasources/remote/aqi_api_service.dart';
import 'package:hava/data/models/models.dart';
import 'package:hava/data/repositories/aqi_repository.dart';

/// Concrete [AqiRepository].
///
/// **Current AQI**: IQAir `/v2/nearest_city` (primary) → OWM (fallback).
/// IQAir returns exact US-based AQI (`aqius`) directly.
///
/// **AQI Forecast**: OWM `/data/2.5/air_pollution/forecast` (always).
/// IQAir's free/Community tier does **not** include the `forecasts`
/// field, so we go straight to OWM for hourly forecast data.
///
/// Results are cached via [CacheService].
class AqiRepositoryImpl implements AqiRepository {
  AqiRepositoryImpl({
    required WeatherApiService weatherApiService,
    required AqiApiService iqAirApiService,
    required CacheService cacheService,
  }) : _weatherApi = weatherApiService,
       _iqAirApi = iqAirApiService,
       _cache = cacheService;

  final WeatherApiService _weatherApi;
  final AqiApiService _iqAirApi;
  final CacheService _cache;

  // ────────────────────────────────────────────
  //  Current AQI  (IQAir → OWM → cache)
  // ────────────────────────────────────────────

  @override
  Future<AqiModel> getCurrentAqi({
    required double lat,
    required double lon,
  }) async {
    // Primary: IQAir (exact US AQI).
    try {
      final aqi = await _iqAirApi.fetchNearestCityAqi(lat: lat, lon: lon);
      await _cache.put(CacheKeys.currentAqi, aqi.toJson());
      return aqi;
    } catch (e) {
      debugPrint('[AQI] IQAir current failed: $e');
    }

    // Fallback: OpenWeatherMap Air Pollution (PM2.5 → EPA conversion).
    try {
      final aqi = await _weatherApi.fetchCurrentAqi(lat: lat, lon: lon);
      await _cache.put(CacheKeys.currentAqi, aqi.toJson());
      return aqi;
    } catch (e) {
      debugPrint('[AQI] OWM current failed: $e');
    }

    // Last resort: stale Hive cache.
    final stale = _cache.get(
      CacheKeys.currentAqi,
      maxAge: const Duration(hours: 24),
    );
    if (stale != null) return _aqiFromCache(stale);
    throw Exception('No AQI data available');
  }

  // ────────────────────────────────────────────
  //  Hourly AQI Forecast  (OWM → cache)
  // ────────────────────────────────────────────
  //
  // IQAir free/Community tier does NOT include the `forecasts` field.
  // Going straight to OWM avoids:
  //  • Returning an empty list when IQAir "succeeds" without forecasts.
  //  • A race condition with concurrent IQAir calls from the current-AQI
  //    provider running in parallel.
  //  • Burning IQAir rate-limit quota (5 calls/min on free tier).

  @override
  Future<List<AqiModel>> getHourlyAqiForecast({
    required double lat,
    required double lon,
  }) async {
    try {
      final forecast = await _weatherApi.fetchAqiForecast(lat: lat, lon: lon);
      await _cache.put(
        CacheKeys.aqiForecast,
        forecast.map((a) => a.toJson()).toList(),
      );
      return forecast;
    } catch (e) {
      debugPrint('[AQI] OWM forecast failed: $e');
    }

    // Fallback: stale Hive cache.
    final stale = _cache.get(
      CacheKeys.aqiForecast,
      maxAge: const Duration(hours: 24),
    );
    if (stale != null) {
      return (stale as List)
          .cast<Map<String, dynamic>>()
          .map(_aqiFromCache)
          .toList();
    }
    return [];
  }

  // ── Cache deserialiser ──

  AqiModel _aqiFromCache(dynamic raw) {
    final m = Map<String, dynamic>.from(raw as Map);
    return AqiModel(
      aqi: (m['aqi'] as num).toInt(),
      dominantPollutant: m['dominant_pollutant'] as String? ?? 'pm25',
      pm25: (m['pm25'] as num?)?.toDouble(),
      pm10: (m['pm10'] as num?)?.toDouble(),
      o3: (m['o3'] as num?)?.toDouble(),
      no2: (m['no2'] as num?)?.toDouble(),
      so2: (m['so2'] as num?)?.toDouble(),
      co: (m['co'] as num?)?.toDouble(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        ((m['dt'] as num?)?.toInt() ?? 0) * 1000,
      ),
    );
  }
}
