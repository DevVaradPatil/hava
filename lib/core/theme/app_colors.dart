import 'package:flutter/material.dart';

/// Hava color system — Neo-Minimal Ambient Health UI.
///
/// Dark-first design with luminous accent gradients that respond to
/// air quality state. The palette creates a sense of calm intelligence.
abstract final class AppColors {
  // ──────────────────────────────────────────────
  //  NEUTRALS – Dark mode (Primary)
  // ──────────────────────────────────────────────

  static const Color darkBackground = Color(0xFF08090C);
  static const Color darkSurface = Color(0xFF111318);
  static const Color darkSurfaceVariant = Color(0xFF1A1D24);
  static const Color darkSurfaceTertiary = Color(0xFF22262E);
  static const Color darkTextPrimary = Color(0xFFF0F2F5);
  static const Color darkTextSecondary = Color(0xFF8A919E);
  static const Color darkTextTertiary = Color(0xFF565C68);
  static const Color darkDivider = Color(0xFF1E2128);
  static const Color darkGlassBorder = Color(0x28FFFFFF);
  static const Color darkGlass = Color(0xCC111318);
  static const Color darkGlassHighlight = Color(0x0DFFFFFF);

  // ──────────────────────────────────────────────
  //  NEUTRALS – Light mode
  // ──────────────────────────────────────────────

  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F3F6);
  static const Color lightSurfaceTertiary = Color(0xFFE8EBF0);
  static const Color lightTextPrimary = Color(0xFF0F1419);
  static const Color lightTextSecondary = Color(0xFF5B6170);
  static const Color lightTextTertiary = Color(0xFF9199A5);
  static const Color lightDivider = Color(0xFFE4E7EC);
  static const Color lightGlassBorder = Color(0x18000000);
  static const Color lightGlass = Color(0xDDFFFFFF);
  static const Color lightGlassHighlight = Color(0x0DFFFFFF);

  // ──────────────────────────────────────────────
  //  AQI STATE COLORS & GRADIENTS
  // ──────────────────────────────────────────────

  // Good (0–50)
  static const Color goodPrimary = Color(0xFF34D399);
  static const Color goodSecondary = Color(0xFF22D3EE);

  // Moderate (51–100)
  static const Color moderatePrimary = Color(0xFFFBBF24);
  static const Color moderateSecondary = Color(0xFFF59E0B);

  // Unhealthy Sensitive (101–150)
  static const Color usgPrimary = Color(0xFFFB923C);
  static const Color usgSecondary = Color(0xFFF97316);

  // Unhealthy (151–200)
  static const Color unhealthyPrimary = Color(0xFFFB7185);
  static const Color unhealthySecondary = Color(0xFFF43F5E);

  // Very Unhealthy (201–300)
  static const Color veryUnhealthyPrimary = Color(0xFFA78BFA);
  static const Color veryUnhealthySecondary = Color(0xFF8B5CF6);

  // Hazardous (301+)
  static const Color hazardousPrimary = Color(0xFFE11D48);
  static const Color hazardousSecondary = Color(0xFFBE123C);

  // AQI tinted backgrounds
  static const Color aqiGoodBg = Color(0xFFECFDF5);
  static const Color aqiGoodBgDark = Color(0xFF0D2018);
  static const Color aqiModerateBg = Color(0xFFFFFBEB);
  static const Color aqiModerateBgDark = Color(0xFF1A1708);
  static const Color aqiUnhealthySensitiveBg = Color(0xFFFFF7ED);
  static const Color aqiUnhealthySensitiveBgDark = Color(0xFF1A140A);
  static const Color aqiUnhealthyBg = Color(0xFFFFF1F2);
  static const Color aqiUnhealthyBgDark = Color(0xFF1A0D10);
  static const Color aqiVeryUnhealthyBg = Color(0xFFF5F3FF);
  static const Color aqiVeryUnhealthyBgDark = Color(0xFF150F1F);
  static const Color aqiHazardousBg = Color(0xFFFFF1F3);
  static const Color aqiHazardousBgDark = Color(0xFF1A0A0D);

  // ──────────────────────────────────────────────
  //  SEMANTIC ACCENTS
  // ──────────────────────────────────────────────

  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFFDBEAFE);
  static const Color accentDark = Color(0xFF2563EB);

  static const Color uvHigh = Color(0xFFF59E0B);
  static const Color rain = Color(0xFF60A5FA);
  static const Color wind = Color(0xFF94A3B8);
  static const Color tempWarm = Color(0xFFFB923C);
  static const Color tempCool = Color(0xFF22D3EE);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF43F5E);

  // ──────────────────────────────────────────────
  //  HELPERS
  // ──────────────────────────────────────────────

  static Color aqiColor(int aqi) {
    if (aqi <= 50) return goodPrimary;
    if (aqi <= 100) return moderatePrimary;
    if (aqi <= 150) return usgPrimary;
    if (aqi <= 200) return unhealthyPrimary;
    if (aqi <= 300) return veryUnhealthyPrimary;
    return hazardousPrimary;
  }

  static List<Color> aqiGradient(int aqi) {
    if (aqi <= 50) return [goodPrimary, goodSecondary];
    if (aqi <= 100) return [moderatePrimary, moderateSecondary];
    if (aqi <= 150) return [usgPrimary, usgSecondary];
    if (aqi <= 200) return [unhealthyPrimary, unhealthySecondary];
    if (aqi <= 300) return [veryUnhealthyPrimary, veryUnhealthySecondary];
    return [hazardousPrimary, hazardousSecondary];
  }

  static Color aqiBgColor(int aqi, {bool isDark = false}) {
    if (aqi <= 50) return isDark ? aqiGoodBgDark : aqiGoodBg;
    if (aqi <= 100) return isDark ? aqiModerateBgDark : aqiModerateBg;
    if (aqi <= 150) {
      return isDark ? aqiUnhealthySensitiveBgDark : aqiUnhealthySensitiveBg;
    }
    if (aqi <= 200) return isDark ? aqiUnhealthyBgDark : aqiUnhealthyBg;
    if (aqi <= 300) {
      return isDark ? aqiVeryUnhealthyBgDark : aqiVeryUnhealthyBg;
    }
    return isDark ? aqiHazardousBgDark : aqiHazardousBg;
  }

  static String aqiLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}
