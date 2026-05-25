import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:hava/core/theme/app_colors.dart';

/// Ambient generative background that communicates air quality through color.
///
/// Accepts an optional [breathabilityColor] derived from the BreathabilityResult.
/// When provided, the flowing blobs take on that color — giving an intuitive
/// green-to-red ambient feel as conditions worsen.
/// Uses RepaintBoundary to isolate repaints from child widgets.
class AuraBackground extends StatefulWidget {
  const AuraBackground({
    super.key,
    required this.aqi,
    required this.child,
    this.breathabilityColor,
  });

  final int aqi;
  final Widget child;

  /// When non-null, the orbiting blobs use this color instead of the
  /// AQI-band gradient. This lets the background track the breathability
  /// index (green → yellow → red) for a more visceral ambient effect.
  final Color? breathabilityColor;

  @override
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationForAqi(widget.aqi),
    )..repeat();
  }

  @override
  void didUpdateWidget(AuraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aqi != widget.aqi) {
      _controller.duration = _durationForAqi(widget.aqi);
    }
  }

  Duration _durationForAqi(int aqi) {
    // Slower animation = fewer visual updates needed
    final t = (aqi.clamp(0, 300) / 300.0);
    final seconds = 20 + (t * 30).round();
    return Duration(seconds: seconds);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Isolate the animated background so it never forces child repaints
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _AuraPainter(
                    aqi: widget.aqi,
                    phase: _controller.value,
                    isDark: isDark,
                    overrideColor: widget.breathabilityColor,
                  ),
                  // Prevent the painter from sizing to children
                  isComplex: true,
                  willChange: true,
                );
              },
            ),
          ),
        ),
        // Isolate children from background repaints
        Positioned.fill(child: RepaintBoundary(child: widget.child)),
      ],
    );
  }
}

class _AuraPainter extends CustomPainter {
  _AuraPainter({
    required this.aqi,
    required this.phase,
    required this.isDark,
    this.overrideColor,
  });

  final int aqi;
  final double phase;
  final bool isDark;
  final Color? overrideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Use breathability color when available, otherwise fall back to AQI gradient.
    final List<Color> gradientColors;
    if (overrideColor != null) {
      // Create a complementary pair from the breathability color.
      final hsl = HSLColor.fromColor(overrideColor!);
      final companion = hsl.withHue((hsl.hue + 30) % 360).toColor();
      gradientColors = [overrideColor!, companion];
    } else {
      gradientColors = AppColors.aqiGradient(aqi);
    }

    // Base fill.
    canvas.drawRect(
      rect,
      Paint()
        ..color = isDark ? AppColors.darkBackground : AppColors.lightBackground,
    );

    // Draw 3 orbiting gradient blobs with very low opacity.
    for (var i = 0; i < 3; i++) {
      final blobPhase = (phase + i * 0.33) % 1.0;
      _drawBlob(
        canvas,
        size,
        blobPhase,
        gradientColors[i % gradientColors.length],
        i,
      );
    }
  }

  void _drawBlob(
    Canvas canvas,
    Size size,
    double blobPhase,
    Color color,
    int index,
  ) {
    final freqX = 1.0 + index * 0.7;
    final freqY = 0.8 + index * 0.5;
    final angle = blobPhase * 2 * math.pi;

    final cx = size.width * (0.3 + 0.4 * math.sin(angle * freqX));
    final cy = size.height * (0.15 + 0.25 * math.cos(angle * freqY));
    final radius = size.width * (0.55 + 0.15 * math.sin(angle + index));

    // Slightly visible opacity so glass cards can blur ambient color.
    final opacity = isDark ? 0.18 : 0.10;

    final gradient = RadialGradient(
      center: Alignment((cx / size.width) * 2 - 1, (cy / size.height) * 2 - 1),
      radius: radius / size.width,
      colors: [
        color.withValues(alpha: opacity),
        color.withValues(alpha: 0.0),
      ],
    );

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = gradient.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_AuraPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.aqi != aqi ||
      oldDelegate.isDark != isDark ||
      oldDelegate.overrideColor != overrideColor;
}
