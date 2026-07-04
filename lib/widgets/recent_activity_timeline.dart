import 'package:flutter/material.dart';

import '../models/activity_record.dart';
import '../theme/focusflow_theme.dart';
import '../utils/duration_formatter.dart';
import 'glass_card.dart';

class RecentActivityTimeline extends StatelessWidget {
  final List<ActivityRecord> activities;
  final String title;
  final int maxItems;

  const RecentActivityTimeline({
    super.key,
    required this.activities,
    this.title = 'Recent Activity',
    this.maxItems = 8,
  });

  @override
  Widget build(BuildContext context) {
    final visibleActivities = activities.take(maxItems).toList();

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
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (visibleActivities.isEmpty)
            const _EmptyTimeline()
          else
            ...List.generate(visibleActivities.length, (index) {
              final activity = visibleActivities[index];
              final isLast = index == visibleActivities.length - 1;

              return _TimelineItem(activity: activity, isLast: isLast);
            }),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final ActivityRecord activity;
  final bool isLast;

  const _TimelineItem({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(activity.category);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: categoryColor,
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.6),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 58,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.white.withValues(alpha: 0.10),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: categoryColor.withValues(alpha: 0.16),
                      ),
                      child: Icon(
                        _categoryIcon(activity.category),
                        color: categoryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activity.category} • ${_formatTime(activity.startTime)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DurationFormatter.minutesToShortText(
                        activity.durationMinutes,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Color _categoryColor(String category) {
    final normalized = category.trim().toLowerCase();

    if (normalized.contains('productive')) return FocusFlowTheme.success;
    if (normalized.contains('distract')) return FocusFlowTheme.danger;
    if (normalized.contains('neutral')) return FocusFlowTheme.secondary;
    if (normalized.contains('break')) return FocusFlowTheme.warning;

    return FocusFlowTheme.primary;
  }

  static IconData _categoryIcon(String category) {
    final normalized = category.trim().toLowerCase();

    if (normalized.contains('productive')) {
      return Icons.bolt_outlined;
    }

    if (normalized.contains('distract')) {
      return Icons.warning_amber_outlined;
    }

    if (normalized.contains('neutral')) {
      return Icons.radio_button_unchecked;
    }

    if (normalized.contains('break')) {
      return Icons.self_improvement_outlined;
    }

    return Icons.apps_outlined;
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_outlined,
            size: 42,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 10),
          Text(
            'No activity yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Keep FocusFlow running and recent activity will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
