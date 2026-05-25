import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hava/core/core.dart';
import 'package:hava/services/breathability/breathability_engine.dart';

/// A single timeline entry — hour + BI result.
class TimelineEntry {
  const TimelineEntry({required this.dateTime, required this.result});

  final DateTime dateTime;
  final BreathabilityResult result;
}

/// Horizontal scrollable activity timeline — shows hourly BI as colored blocks.
class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key, required this.hourlyResults});

  final List<TimelineEntry> hourlyResults;

  @override
  Widget build(BuildContext context) {
    if (hourlyResults.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyResults.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final entry = hourlyResults[index];
          final color = entry.result.color;
          final isNow = index == 0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // BI bar
              Container(
                width: 28,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.25 : 0.15),
                  borderRadius: AppShapes.borderRadiusXS,
                  border: isNow
                      ? Border.all(
                          color: color.withValues(alpha: 0.6),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: (entry.result.score / 100).clamp(0.1, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.6 : 0.4),
                        borderRadius: AppShapes.borderRadiusXS,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Time label
              Text(
                isNow ? 'Now' : DateFormat('HH').format(entry.dateTime),
                style: AppTypography.labelSmall.copyWith(
                  color: isNow ? color : textSecondary,
                  fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 9,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
