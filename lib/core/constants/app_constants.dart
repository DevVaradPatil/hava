/// Application-wide constants.
abstract final class AppConstants {
  /// App display name.
  static const String appName = 'Hava';

  /// Default horizontal margin for "Focus Block" containers (dp).
  static const double focusBlockMargin = 24.0;

  /// Background fetch interval in hours.
  static const int backgroundFetchIntervalHours = 3;

  /// Daily digest notification hour (24h format).
  static const int dailyDigestHour = 7;

  /// Daily digest notification minute.
  static const int dailyDigestMinute = 30;

  /// Precipitation probability threshold for umbrella reminders (0-100).
  static const int umbrellaThreshold = 40;

  /// Default AQI threshold for "safe to exercise" (Standard profile).
  static const int safeAqiStandard = 100;

  /// AQI threshold for sensitive/asthma users.
  static const int safeAqiSensitive = 50;

  /// AQI threshold for athletes.
  static const int safeAqiAthlete = 50;

  /// Maximum hours of forecast data to display.
  static const int forecastHours = 24;

  /// Animation durations.
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animEntrance = Duration(milliseconds: 400);
}
