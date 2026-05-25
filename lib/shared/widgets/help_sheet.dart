import 'package:flutter/material.dart';

import 'package:hava/core/core.dart';

/// A reusable help bottom sheet that explains what a dashboard card means.
///
/// Use [showHelpSheet] to display it.
void showHelpSheet(
  BuildContext context, {
  required String title,
  required String description,
  List<HelpItem> items = const [],
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    builder: (_) => _HelpSheetContent(
      title: title,
      description: description,
      items: items,
      isDark: isDark,
    ),
  );
}

/// A single explainer entry for the help sheet.
class HelpItem {
  const HelpItem({required this.label, required this.explanation, this.icon});

  final String label;
  final String explanation;
  final IconData? icon;
}

class _HelpSheetContent extends StatelessWidget {
  const _HelpSheetContent({
    required this.title,
    required this.description,
    required this.items,
    required this.isDark,
  });

  final String title;
  final String description;
  final List<HelpItem> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 20,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.headlineSmall.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: textSecondary,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: divider, height: 1),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textSecondary,
                      height: 1.6,
                    ),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ...items.map(
                      (item) => _HelpItemTile(item: item, isDark: isDark),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpItemTile extends StatelessWidget {
  const _HelpItemTile({required this.item, required this.isDark});

  final HelpItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final surfaceVariant = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: AppShapes.borderRadiusMD,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: AppTypography.titleSmall.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.explanation,
                    style: AppTypography.bodySmall.copyWith(
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
