import 'package:flutter/material.dart';

class AnimatedMetricBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String trailing;

  const AnimatedMetricBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final percent = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              trailing,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: percent),
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            builder: (context, animatedPercent, _) {
              return LinearProgressIndicator(
                value: animatedPercent,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
      ],
    );
  }
}
