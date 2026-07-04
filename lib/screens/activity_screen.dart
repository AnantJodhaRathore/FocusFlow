import 'package:flutter/material.dart';

import '../models/activity_record.dart';
import '../services/activity_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/activity_filter_chips.dart';
import '../widgets/activity_summary_card.dart';
import '../widgets/focusflow_loading_page.dart';
import '../widgets/focusflow_state_card.dart';
import '../widgets/recent_activity_timeline.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late Future<List<ActivityRecord>> _activitiesFuture;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    _activitiesFuture = ActivityService().getTodayActivities();
  }

  Future<void> _refresh() async {
    setState(_loadActivities);
    await _activitiesFuture;
  }

  void _changeFilter(String filter) {
    if (_selectedFilter == filter) return;

    setState(() {
      _selectedFilter = filter;
    });
  }

  List<ActivityRecord> _sortedActivities(List<ActivityRecord> activities) {
    final sorted = List<ActivityRecord>.from(activities)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return sorted;
  }

  List<ActivityRecord> _filterActivities(List<ActivityRecord> activities) {
    final sorted = _sortedActivities(activities);

    if (_selectedFilter == 'All') return sorted;

    return sorted.where((activity) {
      final type = _activityType(activity);

      switch (_selectedFilter) {
        case 'Productive':
          return type == _ActivityType.productive;
        case 'Distracting':
          return type == _ActivityType.distracting;
        case 'Neutral':
          return type == _ActivityType.neutral;
        case 'Break':
          return type == _ActivityType.breakTime;
        default:
          return true;
      }
    }).toList();
  }

  int _sumMinutes(List<ActivityRecord> activities, {_ActivityType? type}) {
    return activities
        .where((activity) {
          if (type == null) return true;
          return _activityType(activity) == type;
        })
        .fold<int>(0, (total, activity) => total + activity.durationMinutes);
  }

  _ActivityType _activityType(ActivityRecord activity) {
    final category = _normalize(activity.category);
    final appName = _normalize(activity.appName);

    final combined = '$category $appName';

    if (combined.contains('break') ||
        combined.contains('idle') ||
        combined.contains('recovery') ||
        combined.contains('rest')) {
      return _ActivityType.breakTime;
    }

    if (category.contains('distract') ||
        category.contains('distraction') ||
        category.contains('non productive') ||
        category.contains('nonproductive') ||
        category.contains('unproductive') ||
        category.contains('social') ||
        category.contains('entertainment')) {
      return _ActivityType.distracting;
    }

    if (category.contains('productive') ||
        category.contains('focus') ||
        category.contains('work') ||
        category.contains('coding') ||
        category.contains('study')) {
      return _ActivityType.productive;
    }

    if (category.contains('neutral')) {
      return _ActivityType.neutral;
    }

    return _ActivityType.neutral;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.pagePadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureBuilder<List<ActivityRecord>>(
          future: _activitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const FocusFlowLoadingPage(
                title: 'Activity',
                subtitle: 'Loading recent activity...',
              );
            }

            if (snapshot.hasError) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(padding, padding, padding, 110),
                  children: [
                    _ActivityHeader(onRefresh: _refresh),
                    const SizedBox(height: 20),
                    FocusFlowErrorStateCard(
                      title: 'Something went wrong',
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    ),
                  ],
                ),
              );
            }

            final activities = snapshot.data ?? <ActivityRecord>[];
            final filteredActivities = _filterActivities(activities);

            if (activities.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(padding, padding, padding, 110),
                  children: const [
                    FocusFlowEmptyStateCard(
                      title: 'No activity yet',
                      message:
                          'Keep FocusFlow running and your tracked app activity will appear here.',
                      icon: Icons.timeline_outlined,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(padding, padding, padding, 110),
                children: [
                  _ActivityHeader(onRefresh: _refresh),

                  const SizedBox(height: 20),

                  ActivitySummaryCard(
                    totalActivities: activities.length,
                    totalMinutes: _sumMinutes(activities),
                    productiveMinutes: _sumMinutes(
                      activities,
                      type: _ActivityType.productive,
                    ),
                    distractingMinutes: _sumMinutes(
                      activities,
                      type: _ActivityType.distracting,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ActivityFilterChips(
                    selectedFilter: _selectedFilter,
                    onChanged: _changeFilter,
                  ),

                  const SizedBox(height: 16),

                  if (filteredActivities.isEmpty)
                    FocusFlowEmptyStateCard(
                      title: 'No results found',
                      message:
                          'No activities match the "$_selectedFilter" filter right now.',
                      icon: Icons.filter_alt_off_outlined,
                    )
                  else
                    RecentActivityTimeline(
                      title: _selectedFilter == 'All'
                          ? 'Activity Timeline'
                          : '$_selectedFilter Activity',
                      activities: filteredActivities,
                      maxItems: 50,
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

class _ActivityHeader extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _ActivityHeader({required this.onRefresh});

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
                'Activity',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Review your recent app activity, focus categories, and time patterns.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: 'Refresh activity',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

enum _ActivityType { productive, distracting, neutral, breakTime }
