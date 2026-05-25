/// API configuration constants.
///
/// Replace placeholder keys with your actual API keys before running.
/// In production, use --dart-define or .env-based injection.
abstract final class ApiConstants {
  // ──────────────────────────────────────────────
  //  OpenWeatherMap
  // ──────────────────────────────────────────────

  static const String openWeatherBaseUrl = 'https://api.openweathermap.org';

  /// One Call API 3.0 path.
  static const String openWeatherOneCallPath = '/data/3.0/onecall';

  /// Geocoding API path.
  static const String openWeatherGeoPath = '/geo/1.0/direct';

  /// **Replace with your key** (or inject via --dart-define).
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPENWEATHER_API_KEY',
    defaultValue: '9fbade2bcb327417ee0021579061c359',
  );

  // ──────────────────────────────────────────────
  //  IQAir (AirVisual)
  // ──────────────────────────────────────────────

  static const String iqAirBaseUrl = 'https://api.airvisual.com';

  /// Nearest city endpoint.
  static const String iqAirNearestCityPath = '/v2/nearest_city';

  /// **Replace with your key** (or inject via --dart-define).
  static const String iqAirApiKey = String.fromEnvironment(
    'IQAIR_API_KEY',
    defaultValue: '6e3a5672-d817-4388-b894-3e1a6f73f76f',
  );

  // ──────────────────────────────────────────────
  //  Shared
  // ──────────────────────────────────────────────

  /// Default request timeout.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Units preference for OpenWeatherMap (metric / imperial).
  static const String defaultUnits = 'metric';
}
