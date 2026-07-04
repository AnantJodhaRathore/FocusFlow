import 'package:flutter/material.dart';

import '../theme/focusflow_theme.dart';
import '../utils/duration_formatter.dart';
import 'glass_card.dart';

class ActivitySummaryCard extends StatelessWidget {
  final int totalActivities;
  final int totalMinutes;
  final int productiveMinutes;
  final int distractingMinutes;

  const ActivitySummaryCard({
    super.key,
    required this.totalActivities,
    required this.totalMinutes,
    required this.productiveMinutes,
    required this.distractingMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline_outlined,
                color: FocusFlowTheme.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Activity Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryPill(
                label: 'Activities',
                value: totalActivities.toString(),
                icon: Icons.apps_outlined,
                color: FocusFlowTheme.primary,
              ),
              _SummaryPill(
                label: 'Tracked',
                value: DurationFormatter.minutesToShortText(totalMinutes),
                icon: Icons.schedule_outlined,
                color: FocusFlowTheme.secondary,
              ),
              _SummaryPill(
                label: 'Productive',
                value: DurationFormatter.minutesToShortText(productiveMinutes),
                icon: Icons.bolt_outlined,
                color: FocusFlowTheme.success,
              ),
              _SummaryPill(
                label: 'Distracting',
                value: DurationFormatter.minutesToShortText(distractingMinutes),
                icon: Icons.warning_amber_outlined,
                color: FocusFlowTheme.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
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
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
