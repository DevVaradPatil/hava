import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hava/core/core.dart';
import 'package:hava/data/models/models.dart';
import 'package:hava/providers/app_providers.dart';
import 'package:hava/shared/widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _openLocationPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (_) => const CitySearchSheet(),
    ).then((location) {
      if (location != null) {
        ref.read(locationProvider.notifier).state = location;
        ref
            .read(cacheServiceProvider)
            .setSavedLocation(jsonEncode(location.toJson()));
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final themeMode = ref.watch(themeModeProvider);
    final healthProfile = ref.watch(healthProfileProvider);
    final location = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTypography.titleMedium.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ── Theme ──
          _SectionLabel(label: 'APPEARANCE', color: textSecondary),
          const SizedBox(height: 8),
          FocusBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: AppTypography.titleSmall.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _ThemeSelector(
                  current: themeMode,
                  onChanged: (mode) {
                    ref.read(themeModeProvider.notifier).state = mode;
                    final index = switch (mode) {
                      ThemeMode.system => 0,
                      ThemeMode.light => 1,
                      ThemeMode.dark => 2,
                    };
                    ref.read(cacheServiceProvider).setThemeModeIndex(index);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Health Profile ──
          _SectionLabel(label: 'HEALTH', color: textSecondary),
          const SizedBox(height: 8),
          FocusBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Profile',
                  style: AppTypography.titleSmall.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Adjusts AQI sensitivity thresholds.',
                  style: AppTypography.bodySmall.copyWith(color: textSecondary),
                ),
                const SizedBox(height: 12),
                ...HealthProfile.values.map(
                  (profile) => _RadioRow(
                    label: profile.label,
                    isSelected: healthProfile == profile,
                    onTap: () {
                      ref.read(healthProfileProvider.notifier).state = profile;
                      ref
                          .read(cacheServiceProvider)
                          .setHealthProfileIndex(profile.index);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Location ──
          _SectionLabel(label: 'LOCATION', color: textSecondary),
          const SizedBox(height: 8),
          FocusBlock(
            onTap: () => _openLocationPicker(context, ref),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: AppShapes.borderRadiusSM,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location?.city ?? 'Not set',
                        style: AppTypography.bodyMedium.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (location != null)
                        Text(
                          location.displayName,
                          style: AppTypography.labelSmall.copyWith(
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── About ──
          _SectionLabel(label: 'ABOUT', color: textSecondary),
          const SizedBox(height: 8),
          FocusBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppConstants.appName,
                      style: AppTypography.titleSmall.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'v1.0.0',
                      style: AppTypography.labelSmall.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart AQI + health companion.\nBuilt with Flutter.',
                  style: AppTypography.bodySmall.copyWith(
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChanged});

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Row(
      children: [
        for (final mode in ThemeMode.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: mode != ThemeMode.dark ? 8 : 0),
              child: _ThemeChip(
                label: switch (mode) {
                  ThemeMode.system => 'System',
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                },
                icon: switch (mode) {
                  ThemeMode.system => Icons.brightness_auto_rounded,
                  ThemeMode.light => Icons.light_mode_rounded,
                  ThemeMode.dark => Icons.dark_mode_rounded,
                },
                isSelected: current == mode,
                onTap: () => onChanged(mode),
                isDark: isDark,
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AppShapes.borderRadiusSM,
          border: Border.all(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.4)
                : isDark
                ? AppColors.darkGlassBorder
                : AppColors.lightGlassBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accent : textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.accent : textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppConstants.animFast,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.lightTextTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
