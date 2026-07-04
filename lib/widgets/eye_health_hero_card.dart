import 'package:flutter/material.dart';

import '../theme/focusflow_theme.dart';
import 'animated_percent_ring.dart';
import 'glass_card.dart';

class EyeHealthHeroCard extends StatelessWidget {
  final double healthScore;
  final String title;
  final String message;
  final int breaksTaken;
  final int breaksExpected;
  final int screenMinutes;

  const EyeHealthHeroCard({
    super.key,
    required this.healthScore,
    required this.title,
    required this.message,
    required this.breaksTaken,
    required this.breaksExpected,
    required this.screenMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final score = healthScore.clamp(0, 100).round();
    final color = _scoreColor(score);

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;

          final ring = AnimatedPercentRing(
            percent: score / 100,
            color: color,
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text('Eye score', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusPill(label: title, color: color),
              const SizedBox(height: 16),
              Text(
                'Eye Health',
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
                    icon: Icons.self_improvement_outlined,
                    label: 'Breaks',
                    value: '$breaksTaken/$breaksExpected',
                    color: FocusFlowTheme.warning,
                  ),
                  _MiniMetric(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Screen time',
                    value: '${screenMinutes}m',
                    color: FocusFlowTheme.secondary,
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
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
