import 'package:hava/core/constants/app_constants.dart';
import 'package:hava/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Health profile types used to adjust safe-exercise thresholds.
enum HealthProfile {
  standard('Standard', AppConstants.safeAqiStandard),
  sensitive('Sensitive / Asthma', AppConstants.safeAqiSensitive),
  athlete('Professional Athlete', AppConstants.safeAqiAthlete);

  const HealthProfile(this.label, this.safeAqiThreshold);
  final String label;
  final int safeAqiThreshold;
}

/// AQI-related utility functions.
abstract final class AqiUtils {
  /// Returns the foreground color for the given [aqi] value.
  static Color color(int aqi) => AppColors.aqiColor(aqi);

  /// Returns a human-readable label for the given [aqi] value.
  static String label(int aqi) => AppColors.aqiLabel(aqi);

  /// Whether outdoor exercise is safe for the given [profile] at [aqi].
  static bool isSafeToExercise(int aqi, HealthProfile profile) {
    return aqi <= profile.safeAqiThreshold;
  }

  /// Returns advice text based on AQI value and health profile.
  static String advice(int aqi, HealthProfile profile) {
    if (aqi <= 50) {
      return 'Air quality is excellent. Enjoy outdoor activities.';
    }
    if (aqi <= 100) {
      if (profile == HealthProfile.sensitive ||
          profile == HealthProfile.athlete) {
        return 'Air quality is acceptable, but sensitive individuals should limit prolonged outdoor exertion.';
      }
      return 'Air quality is acceptable for most activities.';
    }
    if (aqi <= 150) {
      return 'Sensitive groups should reduce prolonged outdoor exertion.';
    }
    if (aqi <= 200) {
      return 'Everyone may begin to experience health effects. Limit outdoor activity.';
    }
    if (aqi <= 300) {
      return 'Health alert: significant risk. Avoid outdoor exertion.';
    }
    return 'Hazardous conditions. Stay indoors and keep windows closed.';
  }
}
