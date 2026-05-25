import 'package:flutter/material.dart';
import 'package:hava/core/theme/app_colors.dart';
import 'package:hava/core/theme/app_shapes.dart';
import 'package:hava/core/theme/app_typography.dart';

/// Minimalist stat chip — icon, value, and label in a compact glass container.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
    this.backgroundColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ??
        (isDark ? AppColors.darkGlass : AppColors.lightGlass);
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final effectiveIconColor = iconColor ?? textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppShapes.borderRadiusMD,
        border: Border.all(
          color: isDark
              ? AppColors.darkGlassBorder
              : AppColors.lightGlassBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: effectiveIconColor),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}
