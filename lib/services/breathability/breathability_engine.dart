import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:hava/core/utils/aqi_utils.dart';
import 'package:hava/data/models/models.dart';

// ──────────────────────────────────────────────
//  Breathability Index™ — composite 0-100 score
// ──────────────────────────────────────────────

/// Result of the Breathability Index calculation.
class BreathabilityResult {
  const BreathabilityResult({
    required this.score,
    required this.label,
    required this.color,
    required this.factors,
  });

  /// Overall 0–100 score (higher = better / safer).
  final int score;

  /// Human-readable label: Excellent / Good / Moderate / Poor / Dangerous.
  final String label;

  /// Color mapped to the score band.
  final Color color;

  /// Per-factor breakdown (each 0–100, higher = better).
  final Map<BreathabilityFactor, FactorScore> factors;
}

/// Individual factor that feeds into the composite score.
enum BreathabilityFactor { airQuality, humidity, temperature, uvIndex, wind }

/// A single factor's contribution.
class FactorScore {
  const FactorScore({
    required this.factor,
    required this.score,
    required this.label,
    required this.detail,
    required this.icon,
  });

  final BreathabilityFactor factor;

  /// 0-100 (higher = better).
  final int score;

  /// Short human-readable name, e.g. "Air Quality".
  final String label;

  /// Explanation, e.g. "AQI 42 — Good".
  final String detail;

  /// Icon representing this factor.
  final IconData icon;
}

/// Computes the Breathability Index™ from weather + AQI data.
///
/// The BI is a weighted average of five normalised sub-scores:
///   • Air Quality  – 50 %  (dominant factor — this is an air quality app)
///   • Temperature   – 15 %
///   • Humidity       – 12 %
///   • UV Index       – 11 %
///   • Wind Speed     – 12 %
///
/// Each sub-score is a 0-100 value where 100 = ideal conditions.
/// Scoring curves are designed to produce a wide distribution:
///   - Only truly pristine conditions score 90+
///   - Typical city conditions (AQI 40-80) land around 40-65
///   - Anything noticeably uncomfortable scores below 40
class BreathabilityEngine {
  const BreathabilityEngine();

  // ── Weights (must sum to 1.0) ──
  static const double _wAqi = 0.50;
  static const double _wTemp = 0.15;
  static const double _wHumidity = 0.12;
  static const double _wUv = 0.11;
  static const double _wWind = 0.12;

  /// Compute the Breathability Index for current conditions.
  BreathabilityResult compute({
    required int aqi,
    required double temperature,
    required int humidity,
    required double uvIndex,
    required double windSpeed,
    required HealthProfile profile,
  }) {
    final aqiScore = _scoreAqi(aqi, profile);
    final tempScore = _scoreTemperature(temperature);
    final humidityScore = _scoreHumidity(humidity);
    final uvScore = _scoreUv(uvIndex);
    final windScore = _scoreWind(windSpeed);

    final composite =
        (aqiScore.score * _wAqi +
                tempScore.score * _wTemp +
                humidityScore.score * _wHumidity +
                uvScore.score * _wUv +
                windScore.score * _wWind)
            .round()
            .clamp(0, 100);

    return BreathabilityResult(
      score: composite,
      label: _label(composite),
      color: _color(composite),
      factors: {
        BreathabilityFactor.airQuality: aqiScore,
        BreathabilityFactor.temperature: tempScore,
        BreathabilityFactor.humidity: humidityScore,
        BreathabilityFactor.uvIndex: uvScore,
        BreathabilityFactor.wind: windScore,
      },
    );
  }

  /// Compute BI from a single forecast hour (for the Activity Timeline).
  BreathabilityResult computeFromForecast({
    required ForecastHourModel hour,
    required int aqi,
    required HealthProfile profile,
  }) {
    return compute(
      aqi: aqi,
      temperature: hour.temperature,
      humidity: hour.humidity,
      uvIndex: hour.uvIndex,
      windSpeed: hour.windSpeed,
      profile: profile,
    );
  }

  // ──────────────────────────────────────────────
  //  Sub-score functions (each returns 0-100)
  // ──────────────────────────────────────────────

  FactorScore _scoreAqi(int aqi, HealthProfile profile) {
    // Piecewise linear mapping — steeper drops give better score spread.
    // AQI 0     → 100 (pristine)
    // AQI 25    →  85
    // AQI 50    →  65 (typical "good" city)
    // AQI 100   →  35 (moderate — clearly degraded)
    // AQI 150   →  15
    // AQI 200   →   5
    // AQI 300+  →   0
    //
    // Sensitive/athlete profiles shift the curve down earlier via a penalty.
    double raw;
    if (aqi <= 0) {
      raw = 100;
    } else if (aqi <= 25) {
      raw = 100 - (aqi / 25) * 15; // 100→85
    } else if (aqi <= 50) {
      raw = 85 - ((aqi - 25) / 25) * 20; // 85→65
    } else if (aqi <= 100) {
      raw = 65 - ((aqi - 50) / 50) * 30; // 65→35
    } else if (aqi <= 150) {
      raw = 35 - ((aqi - 100) / 50) * 20; // 35→15
    } else if (aqi <= 200) {
      raw = 15 - ((aqi - 150) / 50) * 10; // 15→5
    } else if (aqi <= 300) {
      raw = 5 - ((aqi - 200) / 100) * 5; // 5→0
    } else {
      raw = 0;
    }

    // Sensitive/athlete penalty: reduce score when AQI exceeds their threshold.
    final threshold = profile.safeAqiThreshold.toDouble();
    if (aqi > threshold && raw > 0) {
      final penalty = ((aqi - threshold) / threshold * 10).clamp(0.0, 15.0);
      raw = (raw - penalty).clamp(0.0, 100.0);
    }

    return FactorScore(
      factor: BreathabilityFactor.airQuality,
      score: raw.round().clamp(0, 100),
      label: 'Air Quality',
      detail: 'AQI $aqi — ${AqiUtils.label(aqi)}',
      icon: Icons.air_rounded,
    );
  }

  FactorScore _scoreTemperature(double temp) {
    // Tight comfort zone: 20–25 °C → 95 (not 100 — perfection is rare).
    // 15–20 and 25–30 → gentle ramp down.
    // <5 or >38 → near 0.
    double raw;
    if (temp >= 20 && temp <= 25) {
      raw = 95;
    } else if (temp >= 15 && temp < 20) {
      raw = 95 - ((20 - temp) / 5) * 25; // 95→70
    } else if (temp > 25 && temp <= 30) {
      raw = 95 - ((temp - 25) / 5) * 25; // 95→70
    } else if (temp >= 5 && temp < 15) {
      raw = 70 - ((15 - temp) / 10) * 50; // 70→20
    } else if (temp > 30 && temp <= 38) {
      raw = 70 - ((temp - 30) / 8) * 55; // 70→15
    } else if (temp < 5) {
      raw = math.max(0, 20 - ((5 - temp) / 10) * 20); // 20→0
    } else {
      raw = math.max(0, 15 - ((temp - 38) / 7) * 15); // 15→0
    }

    return FactorScore(
      factor: BreathabilityFactor.temperature,
      score: raw.round().clamp(0, 100),
      label: 'Temperature',
      detail: '${temp.round()}°C — ${_tempLabel(temp)}',
      icon: Icons.thermostat_outlined,
    );
  }

  FactorScore _scoreHumidity(int humidity) {
    // Ideal zone: 40–55 % → 90.
    // Near-ideal: 30–40 and 55–65 → 70-80.
    // Uncomfortable: <20 or >80 → drops sharply to 0.
    double raw;
    if (humidity >= 40 && humidity <= 55) {
      raw = 90;
    } else if (humidity >= 30 && humidity < 40) {
      raw = 90 - ((40 - humidity) / 10) * 20; // 90→70
    } else if (humidity > 55 && humidity <= 65) {
      raw = 90 - ((humidity - 55) / 10) * 20; // 90→70
    } else if (humidity >= 20 && humidity < 30) {
      raw = 70 - ((30 - humidity) / 10) * 35; // 70→35
    } else if (humidity > 65 && humidity <= 80) {
      raw = 70 - ((humidity - 65) / 15) * 40; // 70→30
    } else if (humidity < 20) {
      raw = math.max(0, 35 - ((20 - humidity) / 20) * 35); // 35→0
    } else {
      raw = math.max(0, 30 - ((humidity - 80) / 20) * 30); // 30→0
    }

    return FactorScore(
      factor: BreathabilityFactor.humidity,
      score: raw.round().clamp(0, 100),
      label: 'Humidity',
      detail: '$humidity% — ${_humidityLabel(humidity)}',
      icon: Icons.water_drop_outlined,
    );
  }

  FactorScore _scoreUv(double uv) {
    // UV 0–1 → 95, UV 2–3 → 80-70, UV 4–6 → 55-30, UV 7–10 → 20-5, 11+ → 0.
    double raw;
    if (uv <= 1) {
      raw = 95;
    } else if (uv <= 3) {
      raw = 95 - ((uv - 1) / 2) * 25; // 95→70
    } else if (uv <= 6) {
      raw = 70 - ((uv - 3) / 3) * 40; // 70→30
    } else if (uv <= 10) {
      raw = 30 - ((uv - 6) / 4) * 25; // 30→5
    } else {
      raw = math.max(0, 5 - ((uv - 10) / 3) * 5);
    }

    return FactorScore(
      factor: BreathabilityFactor.uvIndex,
      score: raw.round().clamp(0, 100),
      label: 'UV Index',
      detail: '${uv.toStringAsFixed(1)} — ${_uvLabel(uv)}',
      icon: Icons.wb_sunny_outlined,
    );
  }

  FactorScore _scoreWind(double windSpeed) {
    // Light breeze is ideal, not calm. 2–4 m/s → 90 (light breeze aids ventilation).
    // 0–2 → 75-90 (very calm — less ventilation).
    // 4–8 → 70-45, 8–15 → 40-10, 15+ → near 0.
    double raw;
    if (windSpeed >= 2 && windSpeed <= 4) {
      raw = 90; // ideal light breeze
    } else if (windSpeed < 2) {
      raw = 75 + (windSpeed / 2) * 15; // 75→90
    } else if (windSpeed <= 8) {
      raw = 90 - ((windSpeed - 4) / 4) * 45; // 90→45
    } else if (windSpeed <= 15) {
      raw = 45 - ((windSpeed - 8) / 7) * 35; // 45→10
    } else {
      raw = math.max(0, 10 - ((windSpeed - 15) / 10) * 10); // 10→0
    }

    return FactorScore(
      factor: BreathabilityFactor.wind,
      score: raw.round().clamp(0, 100),
      label: 'Wind',
      detail: '${windSpeed.toStringAsFixed(1)} m/s — ${_windLabel(windSpeed)}',
      icon: Icons.air_rounded,
    );
  }

  // ──────────────────────────────────────────────
  //  Labels & colors
  // ──────────────────────────────────────────────

  static String _label(int score) {
    if (score >= 85) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 40) return 'Moderate';
    if (score >= 20) return 'Poor';
    return 'Dangerous';
  }

  static Color _color(int score) {
    if (score >= 85) return const Color(0xFF4ADE80); // green
    if (score >= 65) return const Color(0xFF06B6D4); // teal
    if (score >= 40) return const Color(0xFFFBBF24); // yellow
    if (score >= 20) return const Color(0xFFFB923C); // orange
    return const Color(0xFFF87171); // red
  }

  static String _tempLabel(double temp) {
    if (temp >= 18 && temp <= 24) return 'Comfortable';
    if (temp < 0) return 'Freezing';
    if (temp < 10) return 'Cold';
    if (temp < 18) return 'Cool';
    if (temp <= 30) return 'Warm';
    if (temp <= 35) return 'Hot';
    return 'Extreme heat';
  }

  static String _humidityLabel(int h) {
    if (h < 30) return 'Dry';
    if (h <= 60) return 'Comfortable';
    if (h <= 80) return 'Humid';
    return 'Very humid';
  }

  static String _uvLabel(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very high';
    return 'Extreme';
  }

  static String _windLabel(double ws) {
    if (ws <= 3) return 'Calm';
    if (ws <= 8) return 'Breezy';
    if (ws <= 15) return 'Windy';
    return 'Very windy';
  }
}
