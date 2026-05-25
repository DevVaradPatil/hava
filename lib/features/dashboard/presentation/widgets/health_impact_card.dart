import 'package:flutter/material.dart';

import 'package:hava/core/core.dart';
import 'package:hava/services/health_impact/health_impact_engine.dart';
import 'package:hava/shared/widgets/focus_block.dart';

/// Cigarette-equivalent health impact card — visceral PM2.5 translation.
class HealthImpactCard extends StatelessWidget {
  const HealthImpactCard({super.key, required this.result});

  final HealthImpactResult result;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final color = HealthImpactEngine.severityColor(result.severity);

    return FocusBlock(
      glowColor: color,
      borderColor: color.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ImpactVisual(count: result.cigaretteEquivalent, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.headline,
                      style: AppTypography.titleMedium.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SeverityBadge(severity: result.severity, color: color),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            result.body,
            style: AppTypography.bodySmall.copyWith(
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.science_outlined, size: 12, color: textSecondary),
              const SizedBox(width: 4),
              Text(
                'Lung burden: ${result.dailyLungBurden.toStringAsFixed(0)} µg',
                style: AppTypography.labelSmall.copyWith(color: textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactVisual extends StatelessWidget {
  const _ImpactVisual({required this.count, required this.color});

  final double count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = count < 0.1 ? Icons.eco_rounded : Icons.smoking_rooms_rounded;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppShapes.borderRadiusSM,
      ),
      child: count < 0.1
          ? Icon(icon, color: color, size: 22)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 18),
                if (count >= 0.5)
                  Text(
                    '×${count.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity, required this.color});

  final HealthImpactSeverity severity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (severity) {
      HealthImpactSeverity.clean => 'CLEAN',
      HealthImpactSeverity.low => 'LOW',
      HealthImpactSeverity.moderate => 'MODERATE',
      HealthImpactSeverity.high => 'HIGH',
      HealthImpactSeverity.extreme => 'EXTREME',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppShapes.borderRadiusFull,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
