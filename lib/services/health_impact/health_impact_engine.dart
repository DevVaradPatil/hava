import 'dart:math' as math;

import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
//  Health Impact Engine — "Cigarette Equivalent"
// ──────────────────────────────────────────────

/// Result of the health-impact calculation.
class HealthImpactResult {
  const HealthImpactResult({
    required this.cigaretteEquivalent,
    required this.dailyLungBurden,
    required this.headline,
    required this.body,
    required this.severity,
  });

  /// Number of cigarettes-equivalent of PM2.5 inhaled per day at this
  /// concentration (based on the Berkeley Earth methodology).
  final double cigaretteEquivalent;

  /// Cumulative PM2.5 "lung burden" in µg for the assumed outdoor duration.
  final double dailyLungBurden;

  /// Short one-liner, e.g. "≈ 2.3 cigarettes today".
  final String headline;

  /// Detailed explanation.
  final String body;

  /// Visual severity: clean / low / moderate / high / extreme.
  final HealthImpactSeverity severity;
}

enum HealthImpactSeverity { clean, low, moderate, high, extreme }

/// Converts PM2.5 concentration into relatable health-impact metrics.
///
/// **Cigarette equivalence methodology (Berkeley Earth, 2015):**
///   • 1 cigarette ≈ 22 µg/m³ of PM2.5 inhaled over 24 hours
///   • At PM2.5 = 22 µg/m³ all day, you inhale ≈ 1 cigarette equivalent
///   • Formula: cigarettes = pm25 / 22.0 × (hoursOutdoor / 24.0)
///
/// We scale by actual outdoor hours (default 2h) so the number is
/// realistic for typical outdoor exposure, not a full 24h.
class HealthImpactEngine {
  const HealthImpactEngine();

  /// The PM2.5 concentration equivalent to one cigarette per day
  /// (Berkeley Earth methodology).
  static const double _pm25PerCigarettePerDay = 22.0;

  /// Average adult breathing rate in m³/hour (light activity).
  static const double _breathingRateM3PerHour = 0.84;

  /// Compute health impact from current PM2.5 and planned outdoor duration.
  HealthImpactResult compute({
    required double? pm25,
    required int aqi,
    double outdoorHours = 2.0,
  }) {
    // If PM2.5 is unavailable, estimate from AQI using inverse EPA table.
    final effectivePm25 = pm25 ?? _estimatePm25FromAqi(aqi);

    // Cigarette equivalent scaled to outdoor hours.
    final cigEquiv =
        (effectivePm25 / _pm25PerCigarettePerDay) * (outdoorHours / 24.0);

    // Lung burden: µg inhaled = concentration × breathing rate × hours.
    final lungBurden = effectivePm25 * _breathingRateM3PerHour * outdoorHours;

    final severity = _severity(cigEquiv);

    // Build human-readable strings.
    final cigStr = cigEquiv < 0.1 ? '< 0.1' : cigEquiv.toStringAsFixed(1);

    final headline = cigEquiv < 0.1
        ? 'Almost zero lung burden'
        : '≈ $cigStr cigarettes today';

    final hours = outdoorHours.round();
    final body = _buildBody(
      effectivePm25,
      cigEquiv,
      lungBurden,
      hours,
      severity,
    );

    return HealthImpactResult(
      cigaretteEquivalent: cigEquiv,
      dailyLungBurden: lungBurden,
      headline: headline,
      body: body,
      severity: severity,
    );
  }

  static HealthImpactSeverity _severity(double cigEquiv) {
    if (cigEquiv < 0.1) return HealthImpactSeverity.clean;
    if (cigEquiv < 0.5) return HealthImpactSeverity.low;
    if (cigEquiv < 2.0) return HealthImpactSeverity.moderate;
    if (cigEquiv < 5.0) return HealthImpactSeverity.high;
    return HealthImpactSeverity.extreme;
  }

  static String _buildBody(
    double pm25,
    double cigEquiv,
    double lungBurden,
    int hours,
    HealthImpactSeverity severity,
  ) {
    final pm25Str = pm25.toStringAsFixed(1);
    final burdenStr = lungBurden.toStringAsFixed(0);

    switch (severity) {
      case HealthImpactSeverity.clean:
        return 'PM2.5 is $pm25Str µg/m³ — the air is very clean. '
            'Spending $hours hours outside adds minimal particulate load '
            'to your lungs ($burdenStr µg).';
      case HealthImpactSeverity.low:
        return 'PM2.5 is $pm25Str µg/m³. '
            'Spending $hours hours outside today exposes your lungs to '
            '~$burdenStr µg of fine particles — a low but measurable amount.';
      case HealthImpactSeverity.moderate:
        return 'PM2.5 is $pm25Str µg/m³. '
            '$hours hours of outdoor exposure equals about '
            '${cigEquiv.toStringAsFixed(1)} cigarettes worth of fine particles '
            '($burdenStr µg total). Consider reducing time outdoors.';
      case HealthImpactSeverity.high:
        return 'PM2.5 is $pm25Str µg/m³ — poor air quality. '
            '$hours hours outside loads your lungs with ~$burdenStr µg of '
            'pollution, equivalent to ${cigEquiv.toStringAsFixed(1)} cigarettes. '
            'Wear an N95 mask or limit outdoor time.';
      case HealthImpactSeverity.extreme:
        return 'PM2.5 is $pm25Str µg/m³ — hazardous. '
            'Even $hours hours outside equals ${cigEquiv.toStringAsFixed(1)} '
            'cigarettes of particulate inhalation ($burdenStr µg). '
            'Stay indoors if possible.';
    }
  }

  /// Rough inverse EPA PM2.5 estimation from US AQI.
  static double _estimatePm25FromAqi(int aqi) {
    // Inverse of the EPA breakpoint table.
    if (aqi <= 50) return (aqi / 50.0) * 12.0;
    if (aqi <= 100) return 12.1 + ((aqi - 51) / 49.0) * 23.3;
    if (aqi <= 150) return 35.5 + ((aqi - 101) / 49.0) * 19.9;
    if (aqi <= 200) return 55.5 + ((aqi - 151) / 49.0) * 94.9;
    if (aqi <= 300) return 150.5 + ((aqi - 201) / 99.0) * 99.9;
    return math.min(500, 250.5 + ((aqi - 301) / 199.0) * 249.9);
  }

  /// Color for the severity badge.
  static Color severityColor(HealthImpactSeverity severity) {
    switch (severity) {
      case HealthImpactSeverity.clean:
        return const Color(0xFF4ADE80);
      case HealthImpactSeverity.low:
        return const Color(0xFF06B6D4);
      case HealthImpactSeverity.moderate:
        return const Color(0xFFFBBF24);
      case HealthImpactSeverity.high:
        return const Color(0xFFFB923C);
      case HealthImpactSeverity.extreme:
        return const Color(0xFFF87171);
    }
  }
}
