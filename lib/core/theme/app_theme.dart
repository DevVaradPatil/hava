import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_typography.dart';

/// Builds Material 3 themes for Hava — dark-first ambient design.
abstract final class AppTheme {
  // ──────────────────────────────────────────────
  //  LIGHT THEME
  // ──────────────────────────────────────────────

  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: AppColors.accentLight,
      onPrimaryContainer: AppColors.accent,
      secondary: AppColors.lightTextSecondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.lightSurfaceVariant,
      onSecondaryContainer: AppColors.lightTextPrimary,
      tertiary: AppColors.goodPrimary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.aqiGoodBg,
      onTertiaryContainer: AppColors.lightTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightDivider,
      outlineVariant: AppColors.lightDivider.withValues(alpha: 0.5),
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final textTheme = AppTypography.textTheme(
      primaryColor: AppColors.lightTextPrimary,
      secondaryColor: AppColors.lightTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: 'Inter',

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.lightTextPrimary,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        shape: AppShapes.shapeLG,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: AppShapes.shapeMD,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: AppShapes.shapeMD,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: AppShapes.shapeSM,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.lightTextTertiary,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppShapes.radiusXL),
          ),
        ),
        showDragHandle: true,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        shape: AppShapes.shapeXS,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.lightTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.lightDivider;
        }),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 22,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.accentLight,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.labelSmall.copyWith(
            color: AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  DARK THEME
  // ──────────────────────────────────────────────

  static ThemeData get dark {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1E3A5F),
      onPrimaryContainer: AppColors.accentLight,
      secondary: AppColors.darkTextSecondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.darkSurfaceVariant,
      onSecondaryContainer: AppColors.darkTextPrimary,
      tertiary: AppColors.goodPrimary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.aqiGoodBgDark,
      onTertiaryContainer: AppColors.darkTextPrimary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFF3B1116),
      onErrorContainer: const Color(0xFFFFB9B6),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkDivider,
      outlineVariant: AppColors.darkDivider.withValues(alpha: 0.5),
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final textTheme = AppTypography.textTheme(
      primaryColor: AppColors.darkTextPrimary,
      secondaryColor: AppColors.darkTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Inter',

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.darkTextPrimary,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        shape: AppShapes.shapeLG,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: AppShapes.shapeMD,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: AppShapes.shapeMD,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: AppShapes.shapeSM,
          textStyle: AppTypography.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.borderRadiusMD,
          borderSide: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.darkTextTertiary,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppShapes.radiusXL),
          ),
        ),
        showDragHandle: true,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        shape: AppShapes.shapeXS,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.darkDivider;
        }),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: 22,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: const Color(0xFF1E3A5F),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.labelSmall.copyWith(color: AppColors.darkTextSecondary),
        ),
      ),
    );
  }
}
