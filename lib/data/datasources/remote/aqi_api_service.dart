import 'package:dio/dio.dart';

import 'package:hava/core/constants/api_constants.dart';
import 'package:hava/data/models/models.dart';

/// Remote service for IQAir (AirVisual) endpoints.
///
/// The `/v2/nearest_city` endpoint returns current weather & pollution
/// **plus** hourly forecasts (≈76 h) with US AQI (`aqius`) in a single
/// response — much richer than the free OpenWeatherMap air-pollution API.
class AqiApiService {
  AqiApiService(this._dio);
  final Dio _dio;

  /// Fetches current AQI **and** hourly AQI forecast in one call.
  ///
  /// Returns an [IqAirFullData] containing both pieces so the caller
  /// doesn't need two network requests.
  Future<IqAirFullData> fetchFullAqiData({
    required double lat,
    required double lon,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.iqAirNearestCityPath,
      queryParameters: {'lat': lat, 'lon': lon},
    );
    final json = response.data!;

    // Current AQI
    final current = AqiModel.fromIqAirJson(json);

    // Hourly forecasts (up to 76 h)
    final forecastList = (json['data']?['forecasts'] as List<dynamic>?) ?? [];
    final forecast = forecastList
        .map((e) => AqiModel.fromIqAirForecastJson(e as Map<String, dynamic>))
        .toList();

    return IqAirFullData(current: current, forecast: forecast);
  }

  /// Convenience: fetches only the current AQI.
  Future<AqiModel> fetchNearestCityAqi({
    required double lat,
    required double lon,
  }) async {
    final data = await fetchFullAqiData(lat: lat, lon: lon);
    return data.current;
  }
}
