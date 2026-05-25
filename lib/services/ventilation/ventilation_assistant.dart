import 'package:flutter/material.dart';

import 'package:hava/core/utils/aqi_utils.dart';
import 'package:hava/data/models/models.dart';

// ──────────────────────────────────────────────
//  Ventilation Assistant — "Inside vs Outside" Bridge
// ──────────────────────────────────────────────

/// The recommended window action.
enum WindowAction { open, close, keep }

/// Result of the Ventilation Assistant analysis.
class VentilationAdvice {
  const VentilationAdvice({
    required this.action,
    required this.icon,
    required this.headline,
    required this.body,
    required this.accentColor,
    required this.aqiTrend,
  });

  /// What the user should do with their windows.
  final WindowAction action;

  /// Icon for the card.
  final IconData icon;

  /// Short directive, e.g. "Open Your Windows".
  final String headline;

  /// Detailed explanation.
  final String body;

  /// Accent color for the card.
  final Color accentColor;

  /// Describes the near-term AQI direction: improving / worsening / stable.
  final String aqiTrend;
}

/// Analyses AQI data + forecast to tell the user when to open or close windows.
///
/// Decision matrix:
///   AQI ≤ 50  → Open windows (excellent air, flush indoor CO₂)
///   AQI 51-100 → Open cautiously (acceptable, but monitor)
///   AQI > 100  → Close windows (unhealthy, seal indoors)
///
/// If AQI is currently high but forecast shows improvement, the advice
/// mentions when it will be safe to open windows again.
class VentilationAssistant {
  const VentilationAssistant();

  VentilationAdvice evaluate({
    required AqiModel currentAqi,
    required List<AqiModel> aqiForecast,
    required HealthProfile profile,
  }) {
    final aqi = currentAqi.aqi;
    final threshold = profile.safeAqiThreshold;
    final trend = _analyzeTrend(aqiForecast);

    // ── Excellent air (AQI ≤ 50) ──
    if (aqi <= 50) {
      return VentilationAdvice(
        action: WindowAction.open,
        icon: Icons.window_rounded,
        headline: 'Open Your Windows',
        body:
            'Outdoor AQI is $aqi (${AqiUtils.label(aqi)}). '
            'Open windows now to flush out indoor CO₂ and refresh your air. '
            '$trend',
        accentColor: const Color(0xFF4ADE80),
        aqiTrend: trend,
      );
    }

    // ── Acceptable air (AQI 51-100) — open cautiously ──
    if (aqi <= threshold) {
      return VentilationAdvice(
        action: WindowAction.open,
        icon: Icons.window_outlined,
        headline: 'Ventilate Briefly',
        body:
            'Outdoor AQI is $aqi (${AqiUtils.label(aqi)}). '
            'Open windows for 15-20 min to circulate fresh air, '
            'then close if you\'re sensitive. '
            '$trend',
        accentColor: const Color(0xFFFBBF24),
        aqiTrend: trend,
      );
    }

    // ── Unhealthy air (AQI > threshold) — close everything ──
    final safeTime = _nextSafeTime(aqiForecast, threshold);
    final safeMsg = safeTime != null
        ? 'AQI is expected to drop below $threshold around '
              '${_formatHour(safeTime)}. You can ventilate then.'
        : 'No improvement expected in the next 24 hours.';

    if (aqi <= 200) {
      return VentilationAdvice(
        action: WindowAction.close,
        icon: Icons.close_rounded,
        headline: 'Close Your Windows',

        body:
            'AQI is $aqi — ${AqiUtils.label(aqi)}. '
            'Keep windows sealed and run your air purifier if you have one. '
            '$safeMsg',
        accentColor: const Color(0xFFFB923C),
        aqiTrend: trend,
      );
    }

    return VentilationAdvice(
      action: WindowAction.close,
      icon: Icons.dangerous_rounded,
      headline: 'Seal All Windows',
      body:
          'AQI is $aqi \u2014 ${AqiUtils.label(aqi)}. '
          'Keep all windows and doors tightly closed. '
          'Use an air purifier on maximum setting. '
          '$safeMsg',
      accentColor: const Color(0xFFF87171),
      aqiTrend: trend,
    );
  }

  /// Analyzes the AQI forecast trend for the next few hours.
  String _analyzeTrend(List<AqiModel> forecast) {
    if (forecast.length < 3) return '';

    final now = DateTime.now();
    final upcoming = forecast
        .where((a) => a.dateTime.isAfter(now))
        .take(6)
        .toList();

    if (upcoming.length < 2) return '';

    final first = upcoming.first.aqi;
    final last = upcoming.last.aqi;
    final diff = last - first;

    if (diff < -20) return 'Air quality is improving.';
    if (diff > 20) return 'Air quality is worsening — act soon.';
    return 'Air quality is expected to remain stable.';
  }

  /// Finds the next hour when AQI drops below threshold.
  DateTime? _nextSafeTime(List<AqiModel> forecast, int threshold) {
    final now = DateTime.now();
    for (final hour in forecast) {
      if (hour.dateTime.isAfter(now) && hour.aqi <= threshold) {
        return hour.dateTime;
      }
    }
    return null;
  }

  static String _formatHour(DateTime dt) {
    final hour = dt.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$h:00 $amPm';
  }
}
