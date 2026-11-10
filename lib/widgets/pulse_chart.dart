import 'dart:math' as math;

import 'package:built_collection/built_collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_typography.dart';

/// The live pulse, one point per second, against the user's usual pulse
/// (dashed). The line is coloured by temperature: ember high above usual,
/// ice at or below it, so the viewer watches it cool.
class PulseChart extends StatelessWidget {
  final BuiltList<double> series;
  final double? usual;
  final double height;

  const PulseChart({
    super.key,
    required this.series,
    required this.usual,
    this.height = 150,
  });

  /// Seconds the x axis always shows, so the line grows into the space.
  static const int _window = 80;

  @override
  Widget build(BuildContext context) {
    final usual = this.usual;
    final values = [...series, ?usual];
    final low = values.isEmpty ? 60.0 : values.reduce(math.min) - 6;
    final high = values.isEmpty ? 100.0 : values.reduce(math.max) + 6;
    final latest = series.isEmpty ? null : series.last;
    final lineColor = latest == null || usual == null
        ? AppColors.primary
        : AppColors.heatAt(((latest - usual) / (usual * 0.2)).clamp(0, 1));

    final first = series.isEmpty ? null : series.first.round();
    final now = latest?.round();
    return Semantics(
      label: now == null
          ? 'Pulse graph. Waiting for your pulse.'
          : 'Pulse graph. Started at $first, now $now beats per minute'
                '${usual == null ? '' : ', your usual is ${usual.round()}'}.',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: series.length < 2
              ? const Center(
                  child: Text(
                    'Your pulse appears here in a few seconds…',
                    style: AppTypography.regular14,
                  ),
                )
              : LineChart(
                  duration: const Duration(milliseconds: 250),
                  LineChartData(
                    minX: 0,
                    maxX: math.max(_window, series.length - 1).toDouble(),
                    minY: low,
                    maxY: high,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        if (usual != null)
                          HorizontalLine(
                            y: usual,
                            color: AppColors.calm.withValues(alpha: 0.6),
                            strokeWidth: 1.5,
                            dashArray: [6, 6],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: AppTypography.regular12.copyWith(
                                color: AppColors.calm,
                              ),
                              labelResolver: (_) =>
                                  'your usual ${usual.round()}',
                            ),
                          ),
                      ],
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < series.length; i++)
                            FlSpot(i.toDouble(), series[i]),
                        ],
                        isCurved: true,
                        preventCurveOverShooting: true,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        color: lineColor,
                        dotData: FlDotData(
                          checkToShowDot: (spot, bar) =>
                              spot.x == bar.spots.last.x,
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: 5,
                                color: lineColor,
                                strokeWidth: 3,
                                strokeColor: AppColors.textPrimary,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              lineColor.withValues(alpha: 0.35),
                              lineColor.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
