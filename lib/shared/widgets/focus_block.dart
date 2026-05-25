import 'package:flutter/material.dart';
import 'package:hava/core/theme/app_colors.dart';
import 'package:hava/core/theme/app_shapes.dart';
import 'package:hava/core/theme/app_spacing.dart';

/// Glass-morphism card container — the primary layout block.
///
/// Uses a solid translucent background instead of BackdropFilter for
/// performance. The color is opaque enough to read content but still lets
/// the AuraBackground tint bleed through at the edges.
class FocusBlock extends StatelessWidget {
  const FocusBlock({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.glowColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final Color? glowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassBg =
        color ?? (isDark ? AppColors.darkGlass : AppColors.lightGlass);
    final border =
        borderColor ??
        (isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder);
    final highlight = isDark
        ? AppColors.darkGlassHighlight
        : AppColors.lightGlassHighlight;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppShapes.borderRadiusLG,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppShapes.borderRadiusLG,
          child: Container(
            padding: padding ?? AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: glassBg,
              borderRadius: AppShapes.borderRadiusLG,
              border: Border.all(color: border, width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [highlight, Colors.transparent],
              ),
              boxShadow: [
                if (glowColor != null)
                  ...AppShapes.glowShadow(glowColor!, intensity: 0.15),
                ...AppShapes.shadowSM(
                  isDark ? Brightness.dark : Brightness.light,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
