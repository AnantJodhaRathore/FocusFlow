import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedPercentRing extends StatelessWidget {
  final double percent;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final Widget child;

  const AnimatedPercentRing({
    super.key,
    required this.percent,
    required this.child,
    this.size = 156,
    this.strokeWidth = 14,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clampedPercent),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _PercentRingPainter(
                  percent: value,
                  strokeWidth: strokeWidth,
                  color: color,
                  backgroundColor: backgroundColor,
                ),
              ),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _PercentRingPainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  const _PercentRingPainter({
    required this.percent,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final foregroundPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          color.withValues(alpha: 0.45),
          color,
          color.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * percent,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PercentRingPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
