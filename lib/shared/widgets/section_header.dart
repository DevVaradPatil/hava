import 'package:flutter/material.dart';

import 'package:hava/core/theme/app_colors.dart';
import 'package:hava/core/theme/app_typography.dart';

/// Section header label for dashboard content groups.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onHelp,
  });

  final String title;
  final Widget? trailing;

  /// When non-null, a small ⓘ icon is shown after the title that triggers
  /// a help bottom sheet explaining the section.
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: textSecondary,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onHelp != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onHelp,
              child: Icon(
                Icons.help_outline_rounded,
                size: 14,
                color: textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}
