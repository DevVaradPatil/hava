import 'package:hava/data/models/models.dart';

/// Contract for fetching weather data.
///
/// Concrete implementations will call OpenWeatherMap or a local cache.
abstract class WeatherRepository {
  /// Fetches current weather for the given coordinates.
  Future<WeatherModel> getCurrentWeather({
    required double lat,
    required double lon,
  });

  /// Fetches hourly forecast (up to 48 hours) for the given coordinates.
  Future<List<ForecastHourModel>> getHourlyForecast({
    required double lat,
    required double lon,
  });
}
