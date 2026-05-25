import 'package:flutter/material.dart';

import 'package:hava/core/theme/app_colors.dart';
import 'package:hava/core/theme/app_shapes.dart';
import 'package:hava/core/theme/app_typography.dart';

/// A minimal error card with an optional retry button.
class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 14, color: textSecondary),
            const SizedBox(width: 6),
            Text(
              message,
              style: AppTypography.labelSmall.copyWith(color: textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Retry',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          borderRadius: AppShapes.borderRadiusMD,
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(color: textSecondary),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: AppShapes.borderRadiusSM,
                  ),
                  child: Text(
                    'Retry',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
