import 'package:flutter/foundation.dart';
import 'package:hava/data/datasources/local/cache_service.dart';
import 'package:hava/data/datasources/remote/weather_api_service.dart';
import 'package:hava/data/models/models.dart';
import 'package:hava/data/repositories/weather_repository.dart';

/// Concrete [WeatherRepository] that fetches from OpenWeatherMap and
/// caches results locally via Hive.
class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl({
    required WeatherApiService apiService,
    required CacheService cacheService,
  }) : _api = apiService,
       _cache = cacheService;

  final WeatherApiService _api;
  final CacheService _cache;

  @override
  Future<WeatherModel> getCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    try {
      // Use free-tier /data/2.5/weather endpoint.
      var weather = await _api.fetchCurrentWeatherFree(lat: lat, lon: lon);

      // Free-tier weather endpoint doesn't include UV — fetch from Open-Meteo.
      try {
        final uvData = await _api.fetchUvIndex(lat: lat, lon: lon);
        final currentUv = (uvData['current'] as num).toDouble();
        weather = weather.copyWithUvIndex(currentUv);
        debugPrint('[Weather] UV merged into current weather: $currentUv');
      } catch (e) {
        debugPrint('[Weather] UV fetch failed for current weather: $e');
      }

      await _cache.put(CacheKeys.currentWeather, weather.toJson());
      return weather;
    } catch (e) {
      // Attempt to serve stale cache on network failure.
      final stale = _cache.get(
        CacheKeys.currentWeather,
        maxAge: const Duration(hours: 24),
      );
      if (stale != null) {
        return WeatherModel.fromJson(Map<String, dynamic>.from(stale as Map));
      }
      rethrow;
    }
  }

  @override
  Future<List<ForecastHourModel>> getHourlyForecast({
    required double lat,
    required double lon,
  }) async {
    try {
      // Use free-tier /data/2.5/forecast (5-day / 3-hour intervals).
      var forecast = await _api.fetchForecastFree(lat: lat, lon: lon);

      // Free-tier forecast endpoint doesn't include UV — merge from Open-Meteo.
      try {
        final uvData = await _api.fetchUvIndex(lat: lat, lon: lon);
        final hourlyUv = uvData['hourly'] as Map<DateTime, double>;
        forecast = forecast.map((hour) {
          // Match by truncating both DateTimes to the same hour.
          // This avoids mismatches from different minute/second values.
          final hourKey = DateTime(
            hour.dateTime.year,
            hour.dateTime.month,
            hour.dateTime.day,
            hour.dateTime.hour,
          );

          // Direct match first.
          if (hourlyUv.containsKey(hourKey)) {
            return hour.copyWithUvIndex(hourlyUv[hourKey]!);
          }

          // Fallback: find the closest UV hour within a 90-minute window.
          double? bestUv;
          Duration bestDiff = const Duration(hours: 999);
          for (final entry in hourlyUv.entries) {
            final diff = hour.dateTime.difference(entry.key).abs();
            if (diff < bestDiff && diff.inMinutes <= 90) {
              bestDiff = diff;
              bestUv = entry.value;
            }
          }
          return bestUv != null ? hour.copyWithUvIndex(bestUv) : hour;
        }).toList();
        debugPrint('[Weather] UV merged into ${forecast.length} forecast hours');
      } catch (e) {
        debugPrint('[Weather] UV fetch failed for forecast: $e');
      }

      // Cache serialised list.
      await _cache.put(
        CacheKeys.hourlyForecast,
        forecast
            .map(
              (f) => {
                'dt': f.dateTime.millisecondsSinceEpoch ~/ 1000,
                'temp': f.temperature,
                'feels_like': f.feelsLike,
                'humidity': f.humidity,
                'wind_speed': f.windSpeed,
                'uvi': f.uvIndex,
                'clouds': f.cloudiness,
                'pop': f.precipitationProbability,
                'weather': [
                  {'description': f.description, 'icon': f.iconCode},
                ],
                'aqi': f.aqi,
              },
            )
            .toList(),
      );

      return forecast;
    } catch (e) {
      final stale = _cache.get(
        CacheKeys.hourlyForecast,
        maxAge: const Duration(hours: 24),
      );
      if (stale != null) {
        final list = (stale as List).cast<Map<String, dynamic>>();
        return list.map(ForecastHourModel.fromJson).toList();
      }
      rethrow;
    }
  }

  /// Searches cities via the OpenWeatherMap Geocoding API.
  Future<List<LocationModel>> searchCities(String query) {
    return _api.searchCities(query);
  }
}
