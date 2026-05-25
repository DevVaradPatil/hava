import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:hava/core/core.dart';
import 'package:hava/data/models/models.dart';
import 'package:hava/shared/widgets/focus_block.dart';

/// 24-hour AQI trend line chart with gradient fill and glow.
class AqiTrendChart extends StatelessWidget {
  const AqiTrendChart({super.key, required this.data});

  final List<AqiModel> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final isDark = context.isDark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final gridColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].aqi.toDouble()));
    }

    final maxAqi = data.map((d) => d.aqi).reduce((a, b) => a > b ? a : b);
    final minAqi = data.map((d) => d.aqi).reduce((a, b) => a < b ? a : b);
    final avgAqi =
        (data.map((d) => d.aqi).reduce((a, b) => a + b) / data.length).round();
    final lineColor = AppColors.aqiColor(avgAqi);

    return FocusBlock(
      child: SizedBox(
        height: 200,
        child: Column(
          children: [
            // Mini stats row
            Row(
              children: [
                _MiniStat(
                  label: 'LOW',
                  value: '$minAqi',
                  color: AppColors.aqiColor(minAqi),
                ),
                const SizedBox(width: 16),
                _MiniStat(
                  label: 'AVG',
                  value: '$avgAqi',
                  color: AppColors.aqiColor(avgAqi),
                ),
                const SizedBox(width: 16),
                _MiniStat(
                  label: 'HIGH',
                  value: '$maxAqi',
                  color: AppColors.aqiColor(maxAqi),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (data.length / 4).ceilToDouble(),
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('HH:mm').format(data[index].dateTime),
                            style: AppTypography.labelSmall.copyWith(
                              color: textSecondary,
                              fontSize: 9,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: (maxAqi + 30).toDouble().clamp(100, 500),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: lineColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            lineColor.withValues(alpha: 0.2),
                            lineColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => isDark
                          ? AppColors.darkSurfaceTertiary
                          : AppColors.lightSurfaceTertiary,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          final time = index < data.length
                              ? DateFormat('HH:mm').format(data[index].dateTime)
                              : '';
                          return LineTooltipItem(
                            'AQI ${spot.y.toInt()}\n$time',
                            AppTypography.labelSmall.copyWith(
                              color: AppColors.aqiColor(spot.y.toInt()),
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: textSecondary,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
