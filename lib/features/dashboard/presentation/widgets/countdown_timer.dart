import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hava/core/core.dart';
import 'package:hava/shared/widgets/focus_block.dart';

/// Countdown to the next safe outdoor window — minimal, elegant display.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.safeWindowStart,
    required this.safeWindowEnd,
    required this.safeWindowAqi,
  });

  final DateTime safeWindowStart;
  final DateTime safeWindowEnd;
  final int safeWindowAqi;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final now = DateTime.now();
    final remaining = widget.safeWindowStart.difference(now);

    // Safe window is in the future — show countdown
    if (!remaining.isNegative) {
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      final countdownText = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

      return _buildCard(
        context: context,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        icon: Icons.schedule_rounded,
        accentColor: AppColors.accent,
        label: 'Safe window opens in',
        value: countdownText,
      );
    }

    // Safe window is currently active
    final endsAt = widget.safeWindowEnd;
    final timeLeft = endsAt.difference(now);
    if (!timeLeft.isNegative) {
      final hours = timeLeft.inHours;
      final minutes = timeLeft.inMinutes.remainder(60);
      final leftText = hours > 0
          ? '${hours}h ${minutes}m left'
          : '${minutes}m left';

      return _buildCard(
        context: context,
        isDark: isDark,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        icon: Icons.check_circle_rounded,
        accentColor: AppColors.goodPrimary,
        label: 'Safe window open now',
        value: leftText,
      );
    }

    // Window has passed
    return const SizedBox.shrink();
  }

  Widget _buildCard({
    required BuildContext context,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required IconData icon,
    required Color accentColor,
    required String label,
    required String value,
  }) {
    final startStr = DateFormat('h:mm a').format(widget.safeWindowStart);
    final endStr = DateFormat('h:mm a').format(widget.safeWindowEnd);

    return GestureDetector(
      onTap: () => _showDetail(context, isDark, textPrimary, textSecondary),
      child: FocusBlock(
        borderColor: accentColor.withValues(alpha: 0.2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: AppShapes.borderRadiusSM,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelMedium.copyWith(
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.headlineMedium.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startStr – $endStr  ·  AQI ${widget.safeWindowAqi}',
                    style: AppTypography.labelSmall.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final startStr = DateFormat('h:mm a').format(widget.safeWindowStart);
    final endStr = DateFormat('h:mm a').format(widget.safeWindowEnd);
    final windowDuration = widget.safeWindowEnd.difference(
      widget.safeWindowStart,
    );
    final durationStr = windowDuration.inHours > 0
        ? '${windowDuration.inHours}h ${windowDuration.inMinutes.remainder(60)}m'
        : '${windowDuration.inMinutes}m';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkGlass : AppColors.lightGlass,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkGlassBorder
                      : AppColors.lightGlassBorder,
                ),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                      borderRadius: AppShapes.borderRadiusFull,
                    ),
                  ),
                ),
                Text(
                  'Safe Window Details',
                  style: AppTypography.headlineMedium.copyWith(
                    color: textPrimary,
                  ),
                ),
                AppSpacing.verticalXL,
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: 'Window',
                  value: '$startStr – $endStr',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                AppSpacing.verticalMD,
                _DetailRow(
                  icon: Icons.timelapse_rounded,
                  label: 'Duration',
                  value: durationStr,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                AppSpacing.verticalMD,
                _DetailRow(
                  icon: Icons.air_rounded,
                  label: 'Avg AQI',
                  value: '${widget.safeWindowAqi}',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                AppSpacing.verticalXXL,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textSecondary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label  ',
          style: AppTypography.bodyMedium.copyWith(color: textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
