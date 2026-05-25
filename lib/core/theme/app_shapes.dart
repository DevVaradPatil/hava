import 'package:flutter/material.dart';

/// Hava shape system — refined rounded containers with subtle depth.
abstract final class AppShapes {
  // ── Border radii ──

  static const double radiusXS = 8.0;
  static const double radiusSM = 12.0;
  static const double radiusMD = 16.0;
  static const double radiusLG = 20.0;
  static const double radiusXL = 28.0;
  static const double radiusFull = 999.0;

  static const BorderRadius borderRadiusXS = BorderRadius.all(
    Radius.circular(radiusXS),
  );
  static const BorderRadius borderRadiusSM = BorderRadius.all(
    Radius.circular(radiusSM),
  );
  static const BorderRadius borderRadiusMD = BorderRadius.all(
    Radius.circular(radiusMD),
  );
  static const BorderRadius borderRadiusLG = BorderRadius.all(
    Radius.circular(radiusLG),
  );
  static const BorderRadius borderRadiusXL = BorderRadius.all(
    Radius.circular(radiusXL),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // ── Shape borders ──

  static const RoundedRectangleBorder shapeXS = RoundedRectangleBorder(
    borderRadius: borderRadiusXS,
  );
  static const RoundedRectangleBorder shapeSM = RoundedRectangleBorder(
    borderRadius: borderRadiusSM,
  );
  static const RoundedRectangleBorder shapeMD = RoundedRectangleBorder(
    borderRadius: borderRadiusMD,
  );
  static const RoundedRectangleBorder shapeLG = RoundedRectangleBorder(
    borderRadius: borderRadiusLG,
  );
  static const RoundedRectangleBorder shapeXL = RoundedRectangleBorder(
    borderRadius: borderRadiusXL,
  );

  // ── Shadows — minimal, ambient ──

  static List<BoxShadow> shadowSM(Brightness brightness) {
    return brightness == Brightness.dark
        ? [
            BoxShadow(
              color: const Color(0x40000000),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0x08000000),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];
  }

  static List<BoxShadow> shadowMD(Brightness brightness) {
    return brightness == Brightness.dark
        ? [
            BoxShadow(
              color: const Color(0x50000000),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0x0C000000),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ];
  }

  static List<BoxShadow> shadowLG(Brightness brightness) {
    return brightness == Brightness.dark
        ? [
            BoxShadow(
              color: const Color(0x60000000),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ]
        : [
            BoxShadow(
              color: const Color(0x14000000),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ];
  }

  /// Colored glow shadow — used for AQI-tinted hero elements.
  static List<BoxShadow> glowShadow(Color color, {double intensity = 0.3}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: intensity),
        blurRadius: 32,
        spreadRadius: -4,
      ),
    ];
  }
}
