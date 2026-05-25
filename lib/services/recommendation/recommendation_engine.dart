import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hava/core/constants/app_constants.dart';
import 'package:hava/core/utils/aqi_utils.dart';
import 'package:hava/data/models/models.dart';

/// The recommendation engine analyses weather and AQI data to produce
/// actionable advice for the user.
///
/// Core algorithm: **Relative Minimum**
/// 1. Scan the 24-hour AQI forecast for a contiguous window where every
///    hourly value is at or below the user's health-profile threshold.
/// 2. Among all qualifying windows, pick the one with the lowest *average*
///    AQI (the "relative minimum").
/// 3. If no safe window exists, advise the user to stay indoors.
/// 4. Overlay precipitation probability to add umbrella reminders.
class RecommendationEngine {
  const RecommendationEngine();

  /// The minimum number of contiguous safe hours to count as a "window".
  static const int _minWindowHours = 2;

  /// Generates the primary recommendation from current conditions and
  /// forecast data.
  Recommendation generate({
    required AqiModel currentAqi,
    required List<AqiModel> aqiForecast,
    required List<ForecastHourModel> weatherForecast,
    required HealthProfile profile,
  }) {
    final threshold = profile.safeAqiThreshold;
    final now = DateTime.now();

    // ── Check precipitation first for umbrella overlay ──
    final umbrellaRec = _checkUmbrella(weatherForecast, currentAqi, now);

    // ── Is it safe *right now*? ──
    if (currentAqi.aqi <= threshold) {
      // Find how long it stays safe from now.
      final safeUntil = _safeDurationFromNow(aqiForecast, threshold, now);

      if (umbrellaRec != null) return umbrellaRec;

      return Recommendation(
        type: RecommendationType.safeNow,
        severity: RecommendationSeverity.good,
        icon: Icons.directions_run_rounded,
        title: 'Safe to Run',
        headline: safeUntil != null
            ? 'Good air until ${_formatTime(safeUntil)} (AQI ${currentAqi.aqi})'
            : 'AQI ${currentAqi.aqi} - ${AqiUtils.label(currentAqi.aqi)}',
        body: AqiUtils.advice(currentAqi.aqi, profile),
        aqi: currentAqi.aqi,
        bestWindowStart: now,
        bestWindowEnd: safeUntil,
        bestWindowAqi: currentAqi.aqi,
      );
    }

    // ── Not safe now — find the best future window ──
    final window = _findBestWindow(aqiForecast, threshold, now);

    if (window != null) {
      if (umbrellaRec != null) {
        // Combine: mention window in an umbrella context.
        return Recommendation(
          type: RecommendationType.bestWindow,
          severity: RecommendationSeverity.moderate,
          icon: Icons.schedule_rounded,
          title: 'Better Window Later',
          headline:
              'Best window: ${_formatTime(window.start)} - ${_formatTime(window.end)} '
              '(AQI ${window.avgAqi})',
          body:
              '${AqiUtils.advice(currentAqi.aqi, profile)} '
              'Also, bring an umbrella -- rain is expected.',
          aqi: currentAqi.aqi,
          bestWindowStart: window.start,
          bestWindowEnd: window.end,
          bestWindowAqi: window.avgAqi,
        );
      }

      return Recommendation(
        type: RecommendationType.bestWindow,
        severity: RecommendationSeverity.moderate,
        icon: Icons.schedule_rounded,
        title: 'Better Window Later',
        headline:
            'Best window: ${_formatTime(window.start)} - ${_formatTime(window.end)} '
            '(AQI ${window.avgAqi})',
        body: AqiUtils.advice(currentAqi.aqi, profile),
        aqi: currentAqi.aqi,
        bestWindowStart: window.start,
        bestWindowEnd: window.end,
        bestWindowAqi: window.avgAqi,
      );
    }

    // ── No safe window at all ──
    if (umbrellaRec != null) return umbrellaRec;

    return Recommendation(
      type: RecommendationType.stayIndoors,
      severity: currentAqi.aqi > 200
          ? RecommendationSeverity.danger
          : RecommendationSeverity.warning,
      icon: Icons.shield_outlined,
      title: 'Stay Indoors',
      headline: 'AQI ${currentAqi.aqi} - ${AqiUtils.label(currentAqi.aqi)}',
      body: AqiUtils.advice(currentAqi.aqi, profile),
      aqi: currentAqi.aqi,
    );
  }

  // ──────────────────────────────────────────────
  //  Relative Minimum Algorithm
  // ──────────────────────────────────────────────

  /// Finds the best contiguous window of >= [_minWindowHours] hours where
  /// every hourly AQI is at or below [threshold].
  ///
  /// Among all qualifying windows, returns the one with the lowest average AQI.
  _Window? _findBestWindow(
    List<AqiModel> forecast,
    int threshold,
    DateTime now,
  ) {
    // Filter to future hours only.
    final future = forecast.where((a) => a.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (future.length < _minWindowHours) return null;

    final windows = <_Window>[];
    int windowStart = 0;

    while (windowStart < future.length) {
      // Skip hours that exceed threshold.
      if (future[windowStart].aqi > threshold) {
        windowStart++;
        continue;
      }

      // Extend the window as far as it remains safe.
      int windowEnd = windowStart;
      int sum = future[windowStart].aqi;

      while (windowEnd + 1 < future.length &&
          future[windowEnd + 1].aqi <= threshold) {
        windowEnd++;
        sum += future[windowEnd].aqi;
      }

      final length = windowEnd - windowStart + 1;
      if (length >= _minWindowHours) {
        windows.add(
          _Window(
            start: future[windowStart].dateTime,
            end: future[windowEnd].dateTime.add(const Duration(hours: 1)),
            avgAqi: (sum / length).round(),
            length: length,
          ),
        );
      }

      windowStart = windowEnd + 1;
    }

    if (windows.isEmpty) return null;

    // Pick the window with the lowest average AQI (relative minimum).
    windows.sort((a, b) => a.avgAqi.compareTo(b.avgAqi));
    return windows.first;
  }

  /// Returns the time until which it remains safe from now, looking at
  /// the forecast. Returns null if forecast data is unavailable.
  DateTime? _safeDurationFromNow(
    List<AqiModel> forecast,
    int threshold,
    DateTime now,
  ) {
    final future = forecast.where((a) => a.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    for (final hour in future) {
      if (hour.aqi > threshold) return hour.dateTime;
    }

    // If all future hours are safe, return the last hour + 1.
    if (future.isNotEmpty) {
      return future.last.dateTime.add(const Duration(hours: 1));
    }
    return null;
  }

  // ──────────────────────────────────────────────
  //  Umbrella Check
  // ──────────────────────────────────────────────

  /// Checks if rain is expected within the next few hours.
  Recommendation? _checkUmbrella(
    List<ForecastHourModel> weatherForecast,
    AqiModel currentAqi,
    DateTime now,
  ) {
    const lookAheadHours = 6;
    final cutoff = now.add(const Duration(hours: lookAheadHours));
    final threshold = AppConstants.umbrellaThreshold / 100;

    for (final hour in weatherForecast) {
      if (hour.dateTime.isAfter(now) &&
          hour.dateTime.isBefore(cutoff) &&
          hour.precipitationProbability >= threshold) {
        final pct = (hour.precipitationProbability * 100).round();
        return Recommendation(
          type: RecommendationType.umbrella,
          severity: RecommendationSeverity.moderate,
          icon: Icons.umbrella_rounded,
          title: 'Bring an Umbrella',
          headline: '$pct% chance of rain at ${_formatTime(hour.dateTime)}',
          body:
              'Precipitation is expected soon. Carry rain protection if '
              'heading out.',
          aqi: currentAqi.aqi,
          precipitationProbability: hour.precipitationProbability,
        );
      }
    }
    return null;
  }

  // ──────────────────────────────────────────────
  //  Formatting
  // ──────────────────────────────────────────────

  static String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }
}

/// Internal representation of a contiguous safe window.
class _Window {
  const _Window({
    required this.start,
    required this.end,
    required this.avgAqi,
    required this.length,
  });

  final DateTime start;
  final DateTime end;
  final int avgAqi;
  final int length;
}
