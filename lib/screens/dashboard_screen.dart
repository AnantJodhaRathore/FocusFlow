import 'package:flutter/material.dart';

import '../analytics/eye_health_metrics.dart';
import '../models/dashboard_data.dart';
import '../models/focus_score_result.dart';
import '../services/activity_service.dart';
import '../services/settings_service.dart';
import '../theme/focusflow_theme.dart';
import '../utils/duration_formatter.dart';
import '../utils/responsive_utils.dart';
import '../widgets/animated_stat_card.dart';
import '../widgets/dashboard_hero_card.dart';
import '../widgets/focus_trend_chart.dart';
import '../widgets/focusflow_loading_page.dart';
import '../widgets/focusflow_state_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/recent_activity_timeline.dart';
import '../widgets/stat_card_grid.dart';
import '../models/focus_input.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardData> _dashboardDataFuture;
  DevicePlatform? _currentPlatform;

  @override
  void initState() {
    super.initState();

    _currentPlatform = SettingsService.platform.value;
    _dashboardDataFuture = ActivityService().getDashboardData(
      _currentPlatform!,
    );
  }

  void _reloadDashboard(DevicePlatform newPlatform) {
    if (_currentPlatform == newPlatform) return;

    setState(() {
      _currentPlatform = newPlatform;
      _dashboardDataFuture = ActivityService().getDashboardData(newPlatform);
    });
  }

  Future<void> _retryDashboardLoad() async {
    setState(() {
      _dashboardDataFuture = ActivityService().getDashboardData(
        _currentPlatform ?? SettingsService.platform.value,
      );
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';

    return 'Good Evening';
  }

  String _focusLabel(int score) {
    if (score >= 85) return 'Excellent Focus';
    if (score >= 70) return 'Strong Focus';
    if (score >= 50) return 'Room to Improve';

    return 'Needs Recovery';
  }

  Color _fatigueColor(String risk, ColorScheme colorScheme) {
    switch (risk.toLowerCase()) {
      case 'high':
        return colorScheme.error;
      case 'medium':
        return FocusFlowTheme.warning;
      default:
        return colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DevicePlatform>(
      valueListenable: SettingsService.platform,
      builder: (context, platform, _) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _reloadDashboard(platform),
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: FutureBuilder<DashboardData>(
              future: _dashboardDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const FocusFlowLoadingPage(
                    title: 'Dashboard',
                    subtitle: 'Preparing your focus summary...',
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: FocusFlowErrorStateCard(
                        title: 'Something went wrong',
                        message: snapshot.error.toString(),
                        onRetry: _retryDashboardLoad,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: FocusFlowEmptyStateCard(
                        title: 'No activity yet',
                        message:
                            'Keep FocusFlow running and your tracked app activity will appear here.',
                        icon: Icons.timeline_outlined,
                      ),
                    ),
                  );
                }

                final data = snapshot.data!;
                final activities = data.todayActivities;

                final fatigueRisk = EyeHealthMetrics.calculateFatigueRisk(
                  activities,
                );

                final nextBreakMinutes =
                    EyeHealthMetrics.calculateNextBreakMinutes(activities);

                final eyeHealthScore = EyeHealthMetrics.calculateFromActivities(
                  activities,
                );

                final focusScore = data.focusScore.round();
                final focusLabel = _focusLabel(focusScore);

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveUtils.pagePadding(context),
                          24,
                          ResponsiveUtils.pagePadding(context),
                          0,
                        ),
                        child: _Header(
                          greeting: _greeting(),
                          platform: platform,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.pagePadding(context),
                        ),
                        child: DashboardHeroCard(
                          focusScore: data.focusScore.toDouble(),
                          focusLabel: focusLabel,
                          message:
                              'Your focus summary for today is ready. Keep deep work blocks strong and take healthy breaks.',
                          productiveMinutes: data.productiveMinutes,
                          totalScreenMinutes: data.totalScreenMinutes,
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.pagePadding(context),
                        ),
                        child: StatCardGrid(
                          children: [
                            AnimatedStatCard(
                              title: 'Focus Score',
                              value: '$focusScore%',
                              subtitle: focusLabel,
                              icon: Icons.psychology_alt_outlined,
                              accentColor: FocusFlowTheme.primary,
                              delay: const Duration(milliseconds: 80),
                            ),
                            AnimatedStatCard(
                              title: 'Productive Time',
                              value: DurationFormatter.minutesToShortText(
                                data.productiveMinutes,
                              ),
                              subtitle: 'Time spent in productive flow',
                              icon: Icons.timer_outlined,
                              accentColor: FocusFlowTheme.success,
                              delay: const Duration(milliseconds: 160),
                            ),
                            AnimatedStatCard(
                              title: 'Screen Time',
                              value: DurationFormatter.minutesToShortText(
                                data.totalScreenMinutes,
                              ),
                              subtitle: 'Total tracked time today',
                              icon: Icons.desktop_windows_outlined,
                              accentColor: FocusFlowTheme.secondary,
                              delay: const Duration(milliseconds: 240),
                            ),
                            AnimatedStatCard(
                              title: 'Breaks',
                              value: '${data.focusInput.recoveryEventCount}/4',
                              subtitle: 'Healthy break rhythm',
                              icon: Icons.self_improvement_outlined,
                              accentColor: FocusFlowTheme.warning,
                              delay: const Duration(milliseconds: 320),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveUtils.pagePadding(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _NextBreakBanner(minutes: nextBreakMinutes),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _CompactMetricCard(
                                    title: 'Eye Health',
                                    value: '$eyeHealthScore%',
                                    icon: Icons.visibility_outlined,
                                    color: FocusFlowTheme.secondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CompactMetricCard(
                                    title: 'Fatigue Risk',
                                    value: fatigueRisk,
                                    icon: Icons.remove_red_eye_outlined,
                                    color: _fatigueColor(
                                      fatigueRisk,
                                      Theme.of(context).colorScheme,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            FocusTrendChart(
                              weeklyScores: data.weeklyFocusTrend,
                            ),

                            const SizedBox(height: 20),

                            _FocusBreakdown(result: data.focusResult),

                            const SizedBox(height: 20),

                            _RecoveryAnalyticsCard(
                              eventCount: data.focusInput.recoveryEventCount,
                              averageRecovery:
                                  data.focusInput.averageRecoveryMinutes,
                              longestRecovery:
                                  data.focusInput.recoveryDurations.isEmpty
                                  ? 0
                                  : data.focusInput.recoveryDurations.reduce(
                                      (a, b) => a > b ? a : b,
                                    ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveUtils.pagePadding(context),
                          0,
                          ResponsiveUtils.pagePadding(context),
                          110,
                        ),
                        child: RecentActivityTimeline(
                          activities: data.todayActivities,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String greeting;
  final DevicePlatform platform;

  const _Header({required this.greeting, required this.platform});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _PlatformBadge(platform: platform),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Here's your focus summary",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          backgroundColor: FocusFlowTheme.primary.withValues(alpha: 0.18),
          child: const Icon(
            Icons.person_outline,
            color: FocusFlowTheme.primary,
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
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

class _CompactMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _CompactMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextBreakBanner extends StatelessWidget {
  final int minutes;

  const _NextBreakBanner({required this.minutes});

  @override
  Widget build(BuildContext context) {
    final message = minutes <= 0
        ? 'Time for a 20-20-20 break'
        : '20-20-20 Break in $minutes min';

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              color: FocusFlowTheme.primary.withValues(alpha: 0.16),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: FocusFlowTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Look 20 feet away for 20 seconds.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusBreakdown extends StatelessWidget {
  final FocusScoreResult result;

  const _FocusBreakdown({required this.result});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Breakdown',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _BreakdownRow(
            label: 'Productive Time',
            score: result.productiveTimeScore,
            icon: Icons.work_outline,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: 'Focus Continuity',
            score: result.distractionScore,
            icon: Icons.stream,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: 'Break Compliance',
            score: result.breakComplianceScore,
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: 'Screen Time',
            score: result.screenTimeScore,
            icon: Icons.monitor_outlined,
          ),
          const SizedBox(height: 14),
          _BreakdownRow(
            label: 'Deep Work',
            score: result.deepWorkScore,
            icon: Icons.psychology_outlined,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final int score;
  final IconData icon;

  const _BreakdownRow({
    required this.label,
    required this.score,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = score >= 75
        ? FocusFlowTheme.success
        : score >= 50
        ? FocusFlowTheme.warning
        : FocusFlowTheme.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.62),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              '$score%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecoveryAnalyticsCard extends StatelessWidget {
  final int eventCount;
  final double averageRecovery;
  final int longestRecovery;

  const _RecoveryAnalyticsCard({
    required this.eventCount,
    required this.averageRecovery,
    required this.longestRecovery,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recovery Analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _RecoveryStat(
                  label: 'Events',
                  value: eventCount.toString(),
                  color: FocusFlowTheme.primary,
                ),
              ),
              Expanded(
                child: _RecoveryStat(
                  label: 'Avg Min',
                  value: averageRecovery.toStringAsFixed(1),
                  color: FocusFlowTheme.secondary,
                ),
              ),
              Expanded(
                child: _RecoveryStat(
                  label: 'Longest',
                  value: '${longestRecovery}m',
                  color: FocusFlowTheme.success,
                ),
              ),
            ],
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
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
