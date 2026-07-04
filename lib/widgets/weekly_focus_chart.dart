import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/focusflow_theme.dart';
import 'glass_card.dart';

class WeeklyFocusChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String title;
  final String subtitle;

  const WeeklyFocusChart({
    super.key,
    required this.values,
    required this.labels,
    this.title = 'Weekly Focus Trend',
    this.subtitle = 'Focus score pattern across the last 7 days',
  });

  @override
  Widget build(BuildContext context) {
    final safeValues = values.isEmpty ? List<double>.filled(7, 0) : values;
    final safeLabels = labels.isEmpty
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : labels;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart_outlined,
                color: FocusFlowTheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 22),
          SizedBox(
            height: 180,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 950),
              curve: Curves.easeOutCubic,
              builder: (context, animationValue, _) {
                return CustomPaint(
                  painter: _WeeklyFocusChartPainter(
                    values: safeValues,
                    labels: safeLabels,
                    animationValue: animationValue,
                    textStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyFocusChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double animationValue;
  final TextStyle? textStyle;

  const _WeeklyFocusChartPainter({
    required this.values,
    required this.labels,
    required this.animationValue,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 28;
    final chartWidth = size.width;
    final barCount = values.length;
    final gap = 10.0;
    final barWidth = math.max(
      10.0,
      (chartWidth - gap * (barCount - 1)) / barCount,
    );

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    final barPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [FocusFlowTheme.primary, FocusFlowTheme.secondary],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));

    for (var index = 0; index < barCount; index++) {
      final value = values[index].clamp(0, 100);
      final left = index * (barWidth + gap);
      final fullHeight = chartHeight * (value / 100);
      final animatedHeight = fullHeight * animationValue;

      final backgroundRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, barWidth, chartHeight),
        const Radius.circular(999),
      );

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          chartHeight - animatedHeight,
          barWidth,
          animatedHeight,
        ),
        const Radius.circular(999),
      );

      canvas.drawRRect(backgroundRect, backgroundPaint);
      canvas.drawRRect(barRect, barPaint);

      final label = index < labels.length ? labels[index] : '';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: textStyle?.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(left + (barWidth - textPainter.width) / 2, chartHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyFocusChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.labels != labels;
  }
}
