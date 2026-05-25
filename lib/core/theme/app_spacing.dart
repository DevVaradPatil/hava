import 'package:flutter/material.dart';

/// Consistent spacing scale — generous whitespace for a premium feel.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 28.0;
  static const double xxxl = 40.0;
  static const double huge = 56.0;

  /// Standard screen horizontal padding.
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: xl);

  /// Card content padding — generous.
  static const EdgeInsets cardPadding = EdgeInsets.all(xl);

  /// Compact card padding.
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(lg);

  /// Section gap between dashboard blocks.
  static const double sectionGap = xxl;

  /// Gap between inline elements (chips, stats).
  static const double chipGap = sm;

  // ── Convenience gap widgets ──

  static const SizedBox verticalXS = SizedBox(height: xs);
  static const SizedBox verticalSM = SizedBox(height: sm);
  static const SizedBox verticalMD = SizedBox(height: md);
  static const SizedBox verticalLG = SizedBox(height: lg);
  static const SizedBox verticalXL = SizedBox(height: xl);
  static const SizedBox verticalXXL = SizedBox(height: xxl);

  static const SizedBox horizontalXS = SizedBox(width: xs);
  static const SizedBox horizontalSM = SizedBox(width: sm);
  static const SizedBox horizontalMD = SizedBox(width: md);
  static const SizedBox horizontalLG = SizedBox(width: lg);
  static const SizedBox horizontalXL = SizedBox(width: xl);
}
