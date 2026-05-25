import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:hava/core/core.dart';
import 'package:hava/services/breathability/breathability_engine.dart';
import 'package:hava/shared/widgets/widgets.dart' as shared;

/// Hero widget: animated circular arc displaying the Breathability Index™
/// with a gradient stroke and luminous glow effect.
class BreathabilityRing extends StatelessWidget {
  const BreathabilityRing({super.key, required this.result});

  final BreathabilityResult result;

  void _showHelp(BuildContext context) {
    shared.showHelpSheet(
      context,
      title: 'Breathability Index',
      description:
          'A 0–100 score combining air quality, temperature, humidity, UV, and wind conditions into a single number indicating how comfortable it is to breathe outdoors.',
      items: const [
        shared.HelpItem(
          label: 'Air Quality (50%)',
          explanation:
              'The dominant factor. Based on the AQI — lower AQI means higher score. Sensitive profiles receive an additional penalty.',
          icon: Icons.air_rounded,
        ),
        shared.HelpItem(
          label: 'Temperature (15%)',
          explanation:
              'Comfort zone is 20–25 °C. Scores drop as temperature moves away from this range.',
          icon: Icons.thermostat_rounded,
        ),
        shared.HelpItem(
          label: 'Humidity (12%)',
          explanation:
              'Ideal range is 40–55%. Very dry or very humid air reduces breathing comfort.',
          icon: Icons.water_drop_outlined,
        ),
        shared.HelpItem(
          label: 'UV Index (11%)',
          explanation:
              'High UV makes outdoor exposure uncomfortable and risky. Scores penalise UV above 1.',
          icon: Icons.wb_sunny_outlined,
        ),
        shared.HelpItem(
          label: 'Wind (12%)',
          explanation:
              'Light breeze (2–4 m/s) is ideal for ventilation. Calm air traps pollutants; strong wind is uncomfortable.',
          icon: Icons.air_outlined,
        ),
        shared.HelpItem(
          label: 'Score Ranges',
          explanation:
              '85–100 Excellent · 65–84 Good · 45–64 Moderate · 25–44 Poor · 0–24 Hazardous',
          icon: Icons.bar_chart_rounded,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return shared.FocusBlock(
      glowColor: result.color,
      child: Column(
        children: [
          // Help icon — top right
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => _showHelp(context),
              child: Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Ring + Score
          SizedBox(
            width: 200,
            height: 200,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: result.score / 100),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return CustomPaint(
                  painter: _RingPainter(
                    progress: value,
                    color: result.color,
                    trackColor: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.lightSurfaceVariant,
                    isDark: isDark,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${result.score}',
                      style: AppTypography.displayLarge.copyWith(
                        color: result.color,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.label.toUpperCase(),
                      style: AppTypography.labelMedium.copyWith(
                        color: result.color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Breathability Index',
            style: AppTypography.titleSmall.copyWith(
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),

          AppSpacing.verticalXL,

          // Factor breakdown — horizontal chips
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: result.factors.values.map((f) {
              return _FactorChip(factor: f, isDark: isDark);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.isDark,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc with glow
    if (progress > 0) {
      // Subtle glow behind the arc
      final glowPaint = Paint()
        ..color = color.withValues(alpha: isDark ? 0.2 : 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );

      // Main arc
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _FactorChip extends StatelessWidget {
  const _FactorChip({required this.factor, required this.isDark});

  final FactorScore factor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chipColor = _chipColor(factor.score);

    return Tooltip(
      message: factor.detail,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: AppShapes.borderRadiusXS,
          border: Border.all(
            color: chipColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(factor.icon, size: 12, color: chipColor),
            const SizedBox(width: 4),
            Text(
              '${factor.label} ${factor.score}',
              style: AppTypography.labelSmall.copyWith(
                color: chipColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _chipColor(int score) {
    if (score >= 80) return AppColors.goodPrimary;
    if (score >= 60) return AppColors.tempCool;
    if (score >= 40) return AppColors.moderatePrimary;
    if (score >= 20) return AppColors.usgPrimary;
    return AppColors.unhealthyPrimary;
  }
}
