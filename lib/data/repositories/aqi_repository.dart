import 'package:hava/data/models/models.dart';

/// Contract for fetching air quality data.
///
/// Concrete implementations will call IQAir, OpenWeather AQ, or a local cache.
abstract class AqiRepository {
  /// Fetches the current AQI for the given coordinates.
  Future<AqiModel> getCurrentAqi({required double lat, required double lon});

  /// Fetches hourly AQI forecast if the provider supports it.
  /// Returns an empty list when unavailable.
  Future<List<AqiModel>> getHourlyAqiForecast({
    required double lat,
    required double lon,
  });
}
