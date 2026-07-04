import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../analytics/activity_metrics.dart';
import '../analytics/eye_health_metrics.dart';
import '../analytics/focus_metrics.dart';
import '../models/activity_record.dart';
import '../models/focus_input.dart';
import '../models/focus_score_result.dart';
import '../models/focus_session.dart';
import '../services/activity_service.dart';
import '../services/settings_service.dart';
import '../theme/focusflow_theme.dart';
import '../utils/duration_formatter.dart';
import '../utils/responsive_utils.dart';
import '../widgets/analytics_insight_card.dart';
import '../widgets/animated_metric_bar.dart';
import '../widgets/focusflow_loading_page.dart';
import '../widgets/focusflow_state_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card_grid.dart';
import '../widgets/weekly_focus_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Future<_AnalyticsSnapshot> _future;

  @override
  void initState() {
    super.initState();

    _future = _loadAnalytics();
    SettingsService.platform.addListener(_reloadForPlatformChange);
  }

  @override
  void dispose() {
    SettingsService.platform.removeListener(_reloadForPlatformChange);
    super.dispose();
  }

  void _reloadForPlatformChange() {
    setState(() {
      _future = _loadAnalytics();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadAnalytics();
    });

    await _future;
  }

  Future<_AnalyticsSnapshot> _loadAnalytics() async {
    final service = ActivityService();
    final platform = SettingsService.platform.value;

    final activities = await service.getTodayActivities();
    final sortedActivities = ActivityMetrics.sortedByStartTime(activities);

    final result = await FocusMetrics.resultAsync(activityService: service);

    final input = await FocusMetrics.inputAsync(activityService: service);

    final sessions = await service.buildFocusSessions(sortedActivities);
    final weeklyTrend = await service.getWeeklyFocusTrend(platform);

    return _AnalyticsSnapshot(
      platform: platform,
      result: result,
      input: input,
      activities: sortedActivities,
      sessions: sessions,
      weeklyTrend: weeklyTrend,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_AnalyticsSnapshot>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const FocusFlowLoadingPage(
                  title: 'Analytics',
                  subtitle: 'Calculating your focus patterns...',
                );
              }

              if (snapshot.hasError) {
                return _AnalyticsStateList(
                  children: [
                    _AnalyticsHeader(
                      title: 'Analytics',
                      subtitle: "Unable to load today's analytics.",
                      platform: SettingsService.platform.value,
                      onRefresh: _refresh,
                    ),
                    const SizedBox(height: 24),
                    FocusFlowErrorStateCard(
                      title: 'Something went wrong',
                      message:
                          snapshot.error?.toString() ??
                          'Unknown analytics error.',
                      onRetry: _refresh,
                    ),
                  ],
                );
              }

              if (!snapshot.hasData) {
                return const _AnalyticsStateList(
                  children: [
                    FocusFlowEmptyStateCard(
                      title: 'No analytics yet',
                      message:
                          'FocusFlow needs some activity data before it can calculate trends.',
                      icon: Icons.analytics_outlined,
                    ),
                  ],
                );
              }

              final data = snapshot.data!;

              return _AnalyticsContent(data: data, onRefresh: _refresh);
            },
          ),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final _AnalyticsSnapshot data;
  final Future<void> Function() onRefresh;

  const _AnalyticsContent({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveUtils.pagePadding(context);
    final focusScore = data.result.focusScore.round();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        horizontalPadding,
        horizontalPadding,
        110,
      ),
      children: [
        _AnalyticsHeader(
          title: 'Analytics',
          subtitle:
              'Understand your focus patterns, recovery rhythm, and screen-time balance.',
          platform: data.platform,
          onRefresh: onRefresh,
        ),

        const SizedBox(height: 20),

        StatCardGrid(
          children: [
            AnalyticsInsightCard(
              title: 'Focus Score',
              value: '$focusScore%',
              subtitle: data.result.label,
              icon: Icons.psychology_alt_outlined,
              color: _scoreColor(focusScore),
            ),
            AnalyticsInsightCard(
              title: 'Productive Time',
              value: DurationFormatter.minutesToShortText(
                data.input.productiveMinutes,
              ),
              subtitle: 'Time spent in productive work',
              icon: Icons.bolt_outlined,
              color: FocusFlowTheme.success,
            ),
            AnalyticsInsightCard(
              title: 'Screen Time',
              value: DurationFormatter.minutesToShortText(
                data.totalScreenMinutes,
              ),
              subtitle: 'Total tracked screen time',
              icon: Icons.monitor_outlined,
              color: FocusFlowTheme.secondary,
            ),
            AnalyticsInsightCard(
              title: 'Focus Sessions',
              value: data.sessions.length.toString(),
              subtitle: 'Detected focus blocks today',
              icon: Icons.track_changes_outlined,
              color: FocusFlowTheme.warning,
            ),
          ],
        ),

        const SizedBox(height: 16),

        WeeklyFocusChart(
          values: data.safeWeeklyTrend,
          labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
        ),

        const SizedBox(height: 16),

        _ScoreBreakdownCard(result: data.result),

        const SizedBox(height: 20),

        _SectionLabel(
          icon: Icons.self_improvement_outlined,
          label: 'Recovery & Wellness',
        ),

        const SizedBox(height: 10),

        _RecoveryCard(data: data),

        const SizedBox(height: 16),

        _WellnessSnapshotCard(data: data),

        const SizedBox(height: 20),

        _SectionLabel(icon: Icons.apps_outlined, label: 'Top Apps Today'),

        const SizedBox(height: 10),

        _TopAppsCard(data: data),
      ],
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 75) return FocusFlowTheme.success;
    if (score >= 50) return FocusFlowTheme.warning;
    return FocusFlowTheme.danger;
  }
}

class _AnalyticsSnapshot {
  final DevicePlatform platform;
  final FocusScoreResult result;
  final FocusInput input;
  final List<ActivityRecord> activities;
  final List<FocusSession> sessions;
  final List<double> weeklyTrend;

  const _AnalyticsSnapshot({
    required this.platform,
    required this.result,
    required this.input,
    required this.activities,
    required this.sessions,
    required this.weeklyTrend,
  });

  int get totalScreenMinutes => input.totalScreenMinutes;

  int get eyeHealthScore {
    return EyeHealthMetrics.calculateFromActivities(activities);
  }

  String get fatigueRisk {
    return EyeHealthMetrics.calculateFatigueRisk(activities);
  }

  int get recoveryEventCount => input.recoveryEventCount;

  double get averageRecoveryMinutes => input.averageRecoveryMinutes;

  int get totalRecoveryMinutes => input.totalRecoveryMinutes;

  int get longestRecoveryMinutes {
    if (input.recoveryDurations.isEmpty) return 0;

    return input.recoveryDurations.reduce(math.max);
  }

  List<double> get safeWeeklyTrend {
    if (weeklyTrend.isEmpty) {
      return List<double>.filled(7, 0);
    }

    if (weeklyTrend.length >= 7) {
      return weeklyTrend.take(7).toList();
    }

    return [...weeklyTrend, ...List<double>.filled(7 - weeklyTrend.length, 0)];
  }

  Map<String, int> get appMinutes {
    final minutes = ActivityMetrics.minutesByApp(activities);

    final entries = minutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map<String, int>.fromEntries(entries);
  }
}

class _AnalyticsStateList extends StatelessWidget {
  final List<Widget> children;

  const _AnalyticsStateList({required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.pagePadding(context),
        ResponsiveUtils.pagePadding(context),
        ResponsiveUtils.pagePadding(context),
        110,
      ),
      children: children,
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final DevicePlatform platform;
  final Future<void> Function() onRefresh;

  const _AnalyticsHeader({
    required this.title,
    required this.subtitle,
    required this.platform,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(subtitle, style: textTheme.bodyMedium),
              const SizedBox(height: 10),
              _PlatformBadge(platform: platform),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: 'Refresh analytics',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final DevicePlatform platform;

  const _PlatformBadge({required this.platform});

  @override
  Widget build(BuildContext context) {
    final icon = switch (platform) {
      DevicePlatform.windows => Icons.desktop_windows_outlined,
      DevicePlatform.android => Icons.phone_android_outlined,
      DevicePlatform.tablet => Icons.tablet_outlined,
      DevicePlatform.web => Icons.language_outlined,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              platform.name.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBreakdownCard extends StatelessWidget {
  final FocusScoreResult result;

  const _ScoreBreakdownCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          AnimatedMetricBar(
            label: 'Productive time',
            value: result.productiveTimeScore.toDouble(),
            maxValue: 100,
            color: FocusFlowTheme.success,
            trailing: '${result.productiveTimeScore.round()}%',
          ),
          const SizedBox(height: 14),
          AnimatedMetricBar(
            label: 'Distraction control',
            value: result.distractionScore.toDouble(),
            maxValue: 100,
            color: FocusFlowTheme.primary,
            trailing: '${result.distractionScore.round()}%',
          ),
          const SizedBox(height: 14),
          AnimatedMetricBar(
            label: 'Break compliance',
            value: result.breakComplianceScore.toDouble(),
            maxValue: 100,
            color: FocusFlowTheme.warning,
            trailing: '${result.breakComplianceScore.round()}%',
          ),
          const SizedBox(height: 14),
          AnimatedMetricBar(
            label: 'Screen-time balance',
            value: result.screenTimeScore.toDouble(),
            maxValue: 100,
            color: FocusFlowTheme.secondary,
            trailing: '${result.screenTimeScore.round()}%',
          ),
          const SizedBox(height: 14),
          AnimatedMetricBar(
            label: 'Deep work',
            value: result.deepWorkScore.toDouble(),
            maxValue: 100,
            color: FocusFlowTheme.success,
            trailing: '${result.deepWorkScore.round()}%',
          ),
        ],
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  final _AnalyticsSnapshot data;

  const _RecoveryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.recoveryEventCount == 0) {
      return GlassCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: FocusFlowTheme.warning.withValues(alpha: 0.16),
              ),
              child: const Icon(
                Icons.self_improvement_outlined,
                color: FocusFlowTheme.warning,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'No recovery events logged today yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _RecoveryStat(
            label: 'Events',
            value: data.recoveryEventCount.toString(),
            color: FocusFlowTheme.primary,
          ),
          _RecoveryStat(
            label: 'Avg Duration',
            value: '${data.averageRecoveryMinutes.toStringAsFixed(1)}m',
            color: FocusFlowTheme.secondary,
          ),
          _RecoveryStat(
            label: 'Longest',
            value: '${data.longestRecoveryMinutes}m',
            color: FocusFlowTheme.success,
          ),
          _RecoveryStat(
            label: 'Total Recovery',
            value: DurationFormatter.minutesToShortText(
              data.totalRecoveryMinutes,
            ),
            color: FocusFlowTheme.warning,
          ),
        ],
      ),
    );
  }
}

class _RecoveryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RecoveryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 130),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WellnessSnapshotCard extends StatelessWidget {
  final _AnalyticsSnapshot data;

  const _WellnessSnapshotCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _SecondaryMetricRow(
            title: 'Eye Health Score',
            value: '${data.eyeHealthScore}%',
            icon: Icons.visibility_outlined,
            color: FocusFlowTheme.secondary,
          ),
          const SizedBox(height: 14),
          _DividerLine(),
          const SizedBox(height: 14),
          _SecondaryMetricRow(
            title: 'Fatigue Risk',
            value: data.fatigueRisk,
            icon: Icons.remove_red_eye_outlined,
            color: _fatigueColor(data.fatigueRisk),
          ),
        ],
      ),
    );
  }

  static Color _fatigueColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return FocusFlowTheme.danger;
      case 'medium':
        return FocusFlowTheme.warning;
      default:
        return FocusFlowTheme.success;
    }
  }
}

class _TopAppsCard extends StatelessWidget {
  final _AnalyticsSnapshot data;

  const _TopAppsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.appMinutes.entries.take(5).toList();

    if (entries.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: FocusFlowTheme.secondary.withValues(alpha: 0.16),
              ),
              child: const Icon(
                Icons.apps_outlined,
                color: FocusFlowTheme.secondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'No tracked app usage yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _TopAppRow(
              rank: index + 1,
              appName: entries[index].key,
              minutes: entries[index].value,
            ),
            if (index != entries.length - 1) const _DividerLine(),
          ],
        ],
      ),
    );
  }
}

class _TopAppRow extends StatelessWidget {
  final int rank;
  final String appName;
  final int minutes;

  const _TopAppRow({
    required this.rank,
    required this.appName,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: FocusFlowTheme.primary.withValues(alpha: 0.16),
            child: Text(
              rank.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: FocusFlowTheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.computer_outlined,
            size: 20,
            color: FocusFlowTheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            DurationFormatter.minutesToShortText(minutes),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SecondaryMetricRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SecondaryMetricRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: color.withValues(alpha: 0.14),
          ),
          child: Icon(icon, size: 21, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FocusFlowTheme.secondary),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
    );
  }
}
