import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:hava/core/constants/api_constants.dart';
import 'package:hava/data/models/models.dart';

/// Remote service for OpenWeatherMap endpoints.
class WeatherApiService {
  WeatherApiService(this._dio);
  final Dio _dio;

  /// Fetches data from the One Call API 3.0.
  ///
  /// Returns the raw JSON map containing `current`, `hourly`, `daily`, etc.
  Future<Map<String, dynamic>> fetchOneCall({
    required double lat,
    required double lon,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.openWeatherOneCallPath,
      queryParameters: {'lat': lat, 'lon': lon, 'exclude': 'minutely,alerts'},
    );
    return response.data!;
  }

  /// Convenience: parses current weather from One Call response.
  WeatherModel parseCurrentWeather(Map<String, dynamic> oneCallData) {
    return WeatherModel.fromJson(
      oneCallData['current'] as Map<String, dynamic>,
    );
  }

  /// Convenience: parses hourly forecast from One Call response.
  List<ForecastHourModel> parseHourlyForecast(
    Map<String, dynamic> oneCallData,
  ) {
    final hourly = oneCallData['hourly'] as List<dynamic>? ?? [];
    return hourly
        .map((h) => ForecastHourModel.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  // ──────────────────────────────────────────────
  //  Free-tier endpoints (2.5)
  // ──────────────────────────────────────────────

  /// Fetches current weather from `/data/2.5/weather` (free tier).
  Future<WeatherModel> fetchCurrentWeatherFree({
    required double lat,
    required double lon,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/data/2.5/weather',
      queryParameters: {'lat': lat, 'lon': lon},
    );
    return WeatherModel.fromFreeJson(response.data!);
  }

  /// Fetches 5-day / 3-hour forecast from `/data/2.5/forecast` (free tier).
  Future<List<ForecastHourModel>> fetchForecastFree({
    required double lat,
    required double lon,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/data/2.5/forecast',
      queryParameters: {'lat': lat, 'lon': lon},
    );
    final list = response.data?['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => ForecastHourModel.fromFreeJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Geocoding: search cities by name.
  ///
  /// Returns up to [limit] **unique** results (deduplicated by
  /// city + state + country).
  Future<List<LocationModel>> searchCities(
    String query, {
    int limit = 5,
  }) async {
    // Request extra results so deduplication still yields enough.
    final response = await _dio.get<List<dynamic>>(
      ApiConstants.openWeatherGeoPath,
      queryParameters: {'q': query, 'limit': 10},
    );
    final all = (response.data ?? [])
        .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final unique = LocationModel.deduplicate(all);
    return unique.length > limit ? unique.sublist(0, limit) : unique;
  }

  // ──────────────────────────────────────────────
  //  Open-Meteo UV Index (free, no key required)
  // ──────────────────────────────────────────────

  static final Dio _openMeteoDio = Dio(
    BaseOptions(
      baseUrl: 'https://api.open-meteo.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Fetches current UV index and hourly UV forecast from Open-Meteo.
  ///
  /// Returns a map with keys:
  ///   - `current` — current UV index as [double]
  ///   - `hourly`  — [Map<DateTime, double>] of hour → UV index
  Future<Map<String, dynamic>> fetchUvIndex({
    required double lat,
    required double lon,
  }) async {
    final response = await _openMeteoDio.get<Map<String, dynamic>>(
      '/v1/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'uv_index',
        'hourly': 'uv_index',
        'forecast_days': 2,
        // Return timestamps in the location's local timezone so they
        // align with OWM forecast DateTimes (also local).
        'timezone': 'auto',
      },
    );
    final data = response.data!;

    // Parse current UV.
    final currentBlock = data['current'] as Map<String, dynamic>? ?? {};
    final currentUv = (currentBlock['uv_index'] as num?)?.toDouble() ?? 0;
    debugPrint('[UV] Open-Meteo current UV: $currentUv');

    // Parse hourly UV.
    final hourlyBlock = data['hourly'] as Map<String, dynamic>? ?? {};
    final times = (hourlyBlock['time'] as List<dynamic>?) ?? [];
    final uvValues = (hourlyBlock['uv_index'] as List<dynamic>?) ?? [];

    final hourlyUv = <DateTime, double>{};
    for (var i = 0; i < times.length && i < uvValues.length; i++) {
      final raw = times[i] as String;
      // Open-Meteo with timezone=auto returns local times WITHOUT a
      // timezone suffix (e.g. "2026-05-19T12:00"). DateTime.tryParse
      // treats these as local time, which is exactly what we want since
      // OWM timestamps are also decoded as local time via
      // DateTime.fromMillisecondsSinceEpoch (local by default).
      final dt = DateTime.tryParse(raw);
      final uv = (uvValues[i] as num?)?.toDouble() ?? 0;
      if (dt != null) hourlyUv[dt] = uv;
    }

    debugPrint('[UV] Parsed ${hourlyUv.length} hourly UV entries');
    return {'current': currentUv, 'hourly': hourlyUv};
  }

  /// Fetches Air Pollution data from OpenWeatherMap (free tier).
  ///
  /// Returns current AQI + component concentrations.
  Future<AqiModel> fetchCurrentAqi({
    required double lat,
    required double lon,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/data/2.5/air_pollution',
      queryParameters: {'lat': lat, 'lon': lon},
    );
    return AqiModel.fromOpenWeatherJson(response.data!);
  }

  /// Fetches Air Pollution forecast from OpenWeatherMap.
  ///
  /// Returns hourly AQI predictions (up to 24 h).
  Future<List<AqiModel>> fetchAqiForecast({
    required double lat,
    required double lon,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/data/2.5/air_pollution/forecast',
      queryParameters: {'lat': lat, 'lon': lon},
      options: Options(
        // This endpoint returns ~120 hourly entries (5 days) with full
        // pollutant data — significantly larger than other endpoints.
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    final list = response.data?['list'] as List<dynamic>? ?? [];

    // Only keep the next 24 hours to match the chart UI.
    final now = DateTime.now();
    final cutoff = now.add(const Duration(hours: 24));

    return list
        .where((item) {
          final dt = (item as Map<String, dynamic>)['dt'] as num?;
          if (dt == null) return false;
          final time = DateTime.fromMillisecondsSinceEpoch(dt.toInt() * 1000);
          return time.isAfter(now) && time.isBefore(cutoff);
        })
        .map((item) {
          final map = item as Map<String, dynamic>;
          final components = map['components'] as Map<String, dynamic>? ?? {};
          final pm25 = (components['pm2_5'] as num?)?.toDouble();
          final europeanIndex =
              ((map['main'] as Map<String, dynamic>?)?['aqi'] as num?)
                  ?.toInt() ??
              0;

          final usAqi = pm25 != null
              ? AqiModel.pm25ToUsAqi(pm25)
              : AqiModel.europeanToApproxUsAqi(europeanIndex);

          return AqiModel(
            aqi: usAqi,
            dominantPollutant: 'pm25',
            pm25: pm25,
            pm10: (components['pm10'] as num?)?.toDouble(),
            o3: (components['o3'] as num?)?.toDouble(),
            no2: (components['no2'] as num?)?.toDouble(),
            so2: (components['so2'] as num?)?.toDouble(),
            co: (components['co'] as num?)?.toDouble(),
            dateTime: DateTime.fromMillisecondsSinceEpoch(
              ((map['dt'] as num?)?.toInt() ?? 0) * 1000,
            ),
          );
        })
        .toList();
  }
}
