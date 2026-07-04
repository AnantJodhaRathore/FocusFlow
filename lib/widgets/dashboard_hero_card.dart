import 'package:flutter/material.dart';

import '../theme/focusflow_theme.dart';
import 'animated_percent_ring.dart';
import 'glass_card.dart';

class DashboardHeroCard extends StatelessWidget {
  final double focusScore;
  final String focusLabel;
  final String message;
  final int productiveMinutes;
  final int totalScreenMinutes;

  const DashboardHeroCard({
    super.key,
    required this.focusScore,
    required this.focusLabel,
    required this.message,
    required this.productiveMinutes,
    required this.totalScreenMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final score = focusScore.clamp(0, 100).round();
    final percent = score / 100;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;

            final ring = AnimatedPercentRing(
              percent: percent,
              color: _scoreColor(score),
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toString(),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('Focus', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusPill(label: focusLabel, color: _scoreColor(score)),
                const SizedBox(height: 16),
                Text(
                  'Today’s Focus Flow',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MiniMetric(
                      icon: Icons.bolt_outlined,
                      label: 'Productive',
                      value: '${productiveMinutes}m',
                      color: FocusFlowTheme.success,
                    ),
                    _MiniMetric(
                      icon: Icons.monitor_outlined,
                      label: 'Screen time',
                      value: '${totalScreenMinutes}m',
                      color: FocusFlowTheme.secondary,
                    ),
                  ],
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [ring, const SizedBox(height: 22), content],
              );
            }

            return Row(
              children: [
                ring,
                const SizedBox(width: 28),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 75) return FocusFlowTheme.success;
    if (score >= 50) return FocusFlowTheme.warning;
    return FocusFlowTheme.danger;
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
