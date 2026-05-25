import 'package:flutter/material.dart';

import 'package:hava/core/core.dart';
import 'package:hava/services/ventilation/ventilation_assistant.dart';
import 'package:hava/shared/widgets/focus_block.dart';

/// Ventilation advice card — open/close windows guidance.
class VentilationCard extends StatelessWidget {
  const VentilationCard({super.key, required this.advice});

  final VentilationAdvice advice;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final accent = advice.accentColor;

    return FocusBlock(
      glowColor: accent,
      borderColor: accent.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ActionIcon(
                icon: advice.icon,
                color: accent,
                action: advice.action,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advice.headline,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _ActionBadge(action: advice.action, color: accent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            advice.body,
            style: AppTypography.bodySmall.copyWith(
              color: textSecondary,
              height: 1.5,
            ),
          ),
          if (advice.aqiTrend.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  advice.aqiTrend == 'improving'
                      ? Icons.trending_down_rounded
                      : advice.aqiTrend == 'worsening'
                      ? Icons.trending_up_rounded
                      : Icons.trending_flat_rounded,
                  size: 14,
                  color: textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'AQI ${advice.aqiTrend}',
                  style: AppTypography.labelSmall.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.action,
  });

  final IconData icon;
  final Color color;
  final WindowAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppShapes.borderRadiusSM,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action, required this.color});

  final WindowAction action;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (action) {
      WindowAction.open => 'OPEN',
      WindowAction.close => 'CLOSE',
      WindowAction.keep => 'KEEP',
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
