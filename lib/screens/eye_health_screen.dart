import 'package:flutter/material.dart';

import '../analytics/activity_metrics.dart';
import '../analytics/eye_health_metrics.dart';
import '../models/activity_record.dart';
import '../services/activity_service.dart';
import '../theme/focusflow_theme.dart';
import '../utils/duration_formatter.dart';
import '../utils/responsive_utils.dart';
import '../widgets/eye_health_hero_card.dart';
import '../widgets/eye_health_tip_card.dart';
import '../widgets/focusflow_loading_page.dart';
import '../widgets/focusflow_state_card.dart';
import '../widgets/glass_card.dart';

class EyeHealthScreen extends StatefulWidget {
  const EyeHealthScreen({super.key});

  @override
  State<EyeHealthScreen> createState() => _EyeHealthScreenState();
}

class _EyeHealthScreenState extends State<EyeHealthScreen> {
  late Future<List<ActivityRecord>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadEyeHealthData();
  }

  void _loadEyeHealthData() {
    _activitiesFuture = ActivityService().getTodayActivities();
  }

  Future<void> _refresh() async {
    setState(_loadEyeHealthData);
    await _activitiesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureBuilder<List<ActivityRecord>>(
          future: _activitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const FocusFlowLoadingPage(
                title: 'Eye Health',
                subtitle: 'Checking screen-time balance and recovery rhythm...',
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.pagePadding(context),
                  ResponsiveUtils.pagePadding(context),
                  ResponsiveUtils.pagePadding(context),
                  110,
                ),
                children: [
                  _EyeHealthHeader(onRefresh: _refresh),
                  const SizedBox(height: 20),
                  FocusFlowErrorStateCard(
                    title: 'Something went wrong',
                    message:
                        snapshot.error?.toString() ??
                        'Failed to load health metrics.',
                    onRetry: _refresh,
                  ),
                ],
              );
            }

            final activities = snapshot.data ?? <ActivityRecord>[];
            final uiData = _EyeHealthDisplayData.fromActivities(activities);

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.pagePadding(context),
                  ResponsiveUtils.pagePadding(context),
                  ResponsiveUtils.pagePadding(context),
                  110,
                ),
                children: [
                  _EyeHealthHeader(onRefresh: _refresh),

                  const SizedBox(height: 20),

                  EyeHealthHeroCard(
                    healthScore: uiData.score,
                    title: uiData.label,
                    message: uiData.message,
                    breaksTaken: uiData.breaksTaken,
                    breaksExpected: uiData.breaksExpected,
                    screenMinutes: uiData.totalScreenMinutes,
                  ),

                  const SizedBox(height: 16),

                  _BreakHealthSummaryCard(data: uiData),

                  const SizedBox(height: 16),

                  const EyeHealthTipCard(
                    title: '20-20-20 Rule',
                    message:
                        'Every 20 minutes, look at something 20 feet away for about 20 seconds.',
                    icon: Icons.visibility_outlined,
                    color: FocusFlowTheme.secondary,
                  ),

                  const SizedBox(height: 12),

                  const EyeHealthTipCard(
                    title: 'Recovery matters',
                    message:
                        'Short breaks help reduce visual fatigue and improve long focus sessions.',
                    icon: Icons.self_improvement_outlined,
                    color: FocusFlowTheme.success,
                  ),

                  const SizedBox(height: 12),

                  const EyeHealthTipCard(
                    title: 'Reduce strain',
                    message:
                        'If your screen time is high, take a longer recovery break before your next deep work block.',
                    icon: Icons.monitor_heart_outlined,
                    color: FocusFlowTheme.warning,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EyeHealthHeader extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EyeHealthHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eye Health',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Track screen-time balance, breaks, and recovery habits.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: 'Refresh eye health',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _BreakHealthSummaryCard extends StatelessWidget {
  final _EyeHealthDisplayData data;

  const _BreakHealthSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final breakPercent = data.breaksExpected <= 0
        ? 0.0
        : (data.breaksTaken / data.breaksExpected).clamp(0.0, 1.0);

    final statusColor = breakPercent >= 0.8
        ? FocusFlowTheme.success
        : breakPercent >= 0.45
        ? FocusFlowTheme.warning
        : FocusFlowTheme.danger;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.self_improvement_outlined,
                color: FocusFlowTheme.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Break Health',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetricPillRow(
            children: [
              _MetricPill(
                label: 'Screen Time',
                value: DurationFormatter.minutesToShortText(
                  data.totalScreenMinutes,
                ),
                icon: Icons.monitor_heart_outlined,
                color: FocusFlowTheme.secondary,
              ),
              _MetricPill(
                label: 'Breaks',
                value: '${data.breaksTaken}/${data.breaksExpected}',
                icon: Icons.timer_outlined,
                color: statusColor,
              ),
              _MetricPill(
                label: 'Next Goal',
                value: data.nextGoalText,
                icon: Icons.flag_outlined,
                color: FocusFlowTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: breakPercent),
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(data.breakSummary, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MetricPillRow extends StatelessWidget {
  final List<Widget> children;

  const _MetricPillRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: children);
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class _EyeHealthDisplayData {
  final double score;
  final String label;
  final String message;
  final int totalScreenMinutes;
  final int breaksTaken;
  final int breaksExpected;

  const _EyeHealthDisplayData({
    required this.score,
    required this.label,
    required this.message,
    required this.totalScreenMinutes,
    required this.breaksTaken,
    required this.breaksExpected,
  });

  factory _EyeHealthDisplayData.fromActivities(
    List<ActivityRecord> activities,
  ) {
    final rawScore = EyeHealthMetrics.calculateFromActivities(activities);
    final minutes = ActivityMetrics.totalScreenMinutes(activities);

    final expectedBreaks = _expectedBreaksForMinutes(minutes);
    final takenBreaks = _estimatedBreaksTaken(
      activities: activities,
      expectedBreaks: expectedBreaks,
    );

    final label = _labelForScore(rawScore);
    final message = _messageForScore(rawScore, minutes);

    return _EyeHealthDisplayData(
      score: rawScore.toDouble(),
      label: label,
      message: message,
      totalScreenMinutes: minutes,
      breaksTaken: takenBreaks,
      breaksExpected: expectedBreaks,
    );
  }

  String get breakSummary {
    if (totalScreenMinutes <= 0) {
      return 'No screen-time activity has been tracked yet today.';
    }

    if (breaksTaken >= breaksExpected) {
      return 'Your break rhythm is on track for today.';
    }

    final missingBreaks = breaksExpected - breaksTaken;

    return 'Try to take $missingBreaks more short break${missingBreaks == 1 ? '' : 's'} to improve recovery balance.';
  }

  String get nextGoalText {
    if (totalScreenMinutes <= 0) return 'Start tracking';

    if (breaksTaken >= breaksExpected) return 'On track';

    final remaining = breaksExpected - breaksTaken;
    return '$remaining break${remaining == 1 ? '' : 's'}';
  }

  static int _expectedBreaksForMinutes(int minutes) {
    if (minutes <= 0) return 1;

    return (minutes / 20).ceil();
  }

  static int _estimatedBreaksTaken({
    required List<ActivityRecord> activities,
    required int expectedBreaks,
  }) {
    final breakActivities = activities.where((activity) {
      final category = activity.category.trim().toLowerCase();
      final appName = activity.appName.trim().toLowerCase();

      return category.contains('break') ||
          appName.contains('break') ||
          appName.contains('idle');
    }).length;

    if (breakActivities > 0) {
      return breakActivities.clamp(0, expectedBreaks);
    }

    final minutes = ActivityMetrics.totalScreenMinutes(activities);

    if (minutes <= 0) return 0;

    return (minutes ~/ 60).clamp(0, expectedBreaks);
  }

  static String _labelForScore(int score) {
    if (score >= 75) return 'Low Fatigue Risk';
    if (score >= 50) return 'Medium Fatigue Risk';

    return 'High Fatigue Risk';
  }

  static String _messageForScore(int score, int minutes) {
    if (minutes <= 0) {
      return 'Start tracking your screen time to see eye health guidance.';
    }

    if (score >= 75) {
      return 'Great job keeping up with healthy eye habits today.';
    }

    if (score >= 50) {
      return 'Consider stepping away for a brief eye recovery break.';
    }

    return 'Screen strain detected. Take a 20-second resting break now.';
  }
}
