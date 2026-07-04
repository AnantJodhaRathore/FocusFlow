import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FocusTrendChart extends StatelessWidget {
  final List<double> weeklyScores;

  const FocusTrendChart({super.key, required this.weeklyScores});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // --- Fix Issue 1: Ensure exactly 7 sequential positions leading up to "Today" ---
    // If we have fewer than 7 scores, we pad with 0.0 at the BEGINNING (older historical dates)
    // If we have more than 7 scores, we take the last 7 items.
    final List<double> scores = List.generate(7, (index) {
      final targetIndex = index - (7 - weeklyScores.length);
      if (targetIndex >= 0 && targetIndex < weeklyScores.length) {
        return weeklyScores[targetIndex].clamp(0.0, 100.0);
      }
      return 0.0;
    });

    // --- Fix Issue 3: Empty-state / Zero-state safety UX ---
    final bool hasNoData = scores.every((score) => score == 0.0);

    // Create the sequential layout coordinate matrix for fl_chart
    final List<FlSpot> spots = List.generate(scores.length, (index) {
      return FlSpot(index.toDouble(), scores[index]);
    });

    final List<String> dayLabels = [
      '6d ago',
      '5d ago',
      '4d ago',
      '3d ago',
      '2d ago',
      'Yesterday',
      'Today',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Focus & Wellness Trend',
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 12,
              left: 12,
              right: 20,
            ),
            child: SizedBox(
              height: 180,
              child: hasNoData
                  ? Center(
                      child: Text(
                        'No focus data recorded this week',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : LineChart(
                      // --- Fix Issue 5: Clean layout swap animations ---
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      LineChartData(
                        minY: 0,
                        maxY: 100,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 25,
                              reservedSize: 38,
                              getTitlesWidget: (val, meta) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '${val.toInt()}%',
                                  style: tt.labelSmall?.copyWith(
                                    // --- Fix Issue 2: Cross-version color safety ---
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: 24,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < dayLabels.length) {
                                  final isToday = idx == 6;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      dayLabels[idx],
                                      style: tt.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant.withValues(
                                          alpha: isToday ? 0.9 : 0.6,
                                        ),
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: cs.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, barData, index, percentage) {
                                final isToday =
                                    // ignore: unrelated_type_equality_checks
                                    index ==
                                    scores.length -
                                        1; // Double check this line!
                                return FlDotCirclePainter(
                                  radius: isToday ? 5 : 3.5,
                                  color: isToday ? cs.primary : cs.onPrimary,
                                  strokeWidth: isToday ? 2.5 : 2.0,
                                  strokeColor: isToday
                                      ? cs.primaryContainer
                                      : cs.primary,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: cs.primary.withValues(alpha: 0.12),
                            ),
                          ), // <-- Ensure this closing paren and comma are exactly here
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
