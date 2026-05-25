import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:hava/core/core.dart';
import 'package:hava/services/gear/gear_advisor.dart';

/// Horizontal scrollable gear suggestion chips.
class GearAdvisorRow extends StatelessWidget {
  const GearAdvisorRow({super.key, required this.items});

  final List<GearItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDark;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return _GearChip(item: item, isDark: isDark);
        },
      ),
    );
  }
}

class _GearChip extends StatelessWidget {
  const _GearChip({required this.item, required this.isDark});

  final GearItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final iconColor = _priorityColor(item.priority);
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Material(
      color: isDark ? AppColors.darkGlass : AppColors.lightGlass,
      borderRadius: AppShapes.borderRadiusFull,
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: AppShapes.borderRadiusFull,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppShapes.borderRadiusFull,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: AppTypography.labelMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

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
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _priorityColor(
                          item.priority,
                        ).withValues(alpha: 0.1),
                        borderRadius: AppShapes.borderRadiusSM,
                      ),
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: _priorityColor(item.priority),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTypography.titleLarge.copyWith(
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalLG,
                Text(
                  item.reason,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textSecondary,
                    height: 1.6,
                  ),
                ),
                AppSpacing.verticalXXL,
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _priorityColor(int priority) {
    if (priority >= 80) return AppColors.error;
    if (priority >= 50) return AppColors.warning;
    return AppColors.accent;
  }
}
