import 'package:flutter/material.dart';

import 'package:hava/core/theme/app_colors.dart';
import 'package:hava/core/theme/app_shapes.dart';

/// Shimmer placeholder for loading states — pulses with a subtle glow.
class ShimmerBlock extends StatefulWidget {
  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkSurfaceVariant
        : AppColors.lightSurfaceVariant;
    final highlightColor = isDark
        ? AppColors.darkSurfaceTertiary
        : AppColors.lightSurfaceTertiary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppShapes.borderRadiusLG,
            color: Color.lerp(baseColor, highlightColor, _controller.value),
          ),
        );
      },
    );
  }
}

/// Full-width shimmer card matching FocusBlock dimensions.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ShimmerBlock(width: double.infinity, height: height),
    );
  }
}
