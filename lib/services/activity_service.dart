import 'dart:math' as math;

import '../analytics/activity_metrics.dart';
import '../analytics/focus_metrics.dart';
import '../analytics/recovery_engine.dart';
import '../models/activity_record.dart';
import '../models/dashboard_data.dart';
import '../models/focus_input.dart';
import '../models/focus_score_result.dart';
import '../models/focus_session.dart';
import '../services/settings_service.dart';
import 'storage_service.dart';

class ActivityService {
  final StorageService storageService;

  ActivityService({StorageService? storageService})
    : storageService = storageService ?? StorageService();

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return _startOfDay(date).add(const Duration(days: 1));
  }

  List<ActivityRecord> _sortActivities(List<ActivityRecord> activities) {
    return [...activities]..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  bool _isProductiveActivity(ActivityRecord activity) {
    final category = activity.category.toLowerCase().trim();
    return category == 'work' ||
        category == 'research' ||
        category == 'productive' ||
        category == 'coding' ||
        category == 'study' ||
        category == 'learning';
  }

  Future<int> saveActivity(ActivityRecord activity) {
    return storageService.saveActivity(activity);
  }

  Future<int> insertActivity(ActivityRecord activity) {
    return storageService.insertActivity(activity);
  }

  Future<int> updateActivity(ActivityRecord activity) {
    return storageService.updateActivity(activity);
  }

  Future<int> deleteActivity(int id) {
    return storageService.deleteActivity(id);
  }

  Future<List<ActivityRecord>> getActivities() {
    return storageService.getActivities();
  }

  Future<List<ActivityRecord>> getTodayActivities() {
    return getActivitiesByDate(DateTime.now());
  }

  Future<List<ActivityRecord>> getActivitiesByDate(DateTime date) {
    return storageService.getActivitiesInRange(
      _startOfDay(date),
      _endOfDay(date),
    );
  }

  Future<List<ActivityRecord>> getActivitiesForRange(
    DateTime start,
    DateTime end,
  ) {
    if (!end.isAfter(start)) return Future.value([]);
    return storageService.getActivitiesInRange(start, end);
  }

  Future<List<ActivityRecord>> getYesterdayActivities() {
    return getActivitiesByDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  Future<List<ActivityRecord>> getLastNDaysActivities(int days) {
    if (days <= 0) return Future.value([]);

    final today = _startOfDay(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    final end = today.add(const Duration(days: 1));

    return getActivitiesForRange(start, end);
  }

  Future<List<ActivityRecord>> getLast7DaysActivities() {
    return getLastNDaysActivities(7);
  }

  Future<int> totalScreenTime({DateTime? date}) async {
    final activities = await getActivitiesByDate(date ?? DateTime.now());
    return ActivityMetrics.totalScreenMinutes(activities);
  }

  Future<int> productiveMinutes({DateTime? date}) async {
    final activities = await getActivitiesByDate(date ?? DateTime.now());
    return ActivityMetrics.productiveMinutes(activities);
  }

  Future<int> breakMinutes({DateTime? date}) async {
    final activities = await getActivitiesByDate(date ?? DateTime.now());
    return ActivityMetrics.breakMinutes(activities);
  }

  Future<int> distractionCount({DateTime? date}) async {
    final activities = await getActivitiesByDate(date ?? DateTime.now());
    return ActivityMetrics.countAppSwitches(activities);
  }

  Future<List<FocusSession>> buildFocusSessions(
    List<ActivityRecord> records,
  ) async {
    final activities = _sortActivities(records);
    if (activities.isEmpty) return [];

    final sessions = <FocusSession>[];

    var currentApp = activities.first.appName;
    var sessionStart = activities.first.startTime;
    var sessionEnd = activities.first.startTime.add(
      Duration(minutes: activities.first.durationMinutes),
    );
    var sessionDuration = activities.first.durationMinutes;

    for (var i = 1; i < activities.length; i++) {
      final activity = activities[i];
      final activityEnd = activity.startTime.add(
        Duration(minutes: activity.durationMinutes),
      );

      if (activity.appName == currentApp) {
        sessionDuration += activity.durationMinutes;
        if (activityEnd.isAfter(sessionEnd)) {
          sessionEnd = activityEnd;
        }
        continue;
      }

      sessions.add(
        FocusSession(
          appName: currentApp,
          startTime: sessionStart,
          endTime: sessionEnd,
          durationMinutes: math.max(0, sessionDuration),
        ),
      );

      currentApp = activity.appName;
      sessionStart = activity.startTime;
      sessionEnd = activityEnd;
      sessionDuration = activity.durationMinutes;
    }

    sessions.add(
      FocusSession(
        appName: currentApp,
        startTime: sessionStart,
        endTime: sessionEnd,
        durationMinutes: math.max(0, sessionDuration),
      ),
    );

    return sessions;
  }

  Future<void> generateAndSaveTodaySessions() async {
    final activities = await getTodayActivities();
    final sessions = await buildFocusSessions(activities);

    for (final session in sessions) {
      await storageService.saveSession(session);
    }
  }

  Future<List<FocusSession>> getSessions() {
    return storageService.getSessions();
  }

  Future<List<FocusSession>> getSessionsInRange(DateTime start, DateTime end) {
    return storageService.getSessionsInRange(start, end);
  }

  Future<FocusInput> buildFocusInputForDate(
    DateTime date, {
    List<ActivityRecord>? cachedActivities,
    DevicePlatform? platform,
  }) async {
    final activities = _sortActivities(
      cachedActivities ?? await getActivitiesByDate(date),
    );

    final totalScreen = ActivityMetrics.totalScreenMinutes(activities);
    final productive = ActivityMetrics.productiveMinutes(activities);
    final breakCount = ActivityMetrics.breakCount(activities);
    final recoveryDurations = RecoveryEngine.computeRecoveryDurations(
      activities,
    );

    var longestFocusBlock = 0;
    var currentFocusBlock = 0;

    for (final activity in activities) {
      if (_isProductiveActivity(activity)) {
        currentFocusBlock += activity.durationMinutes;
      } else {
        longestFocusBlock = math.max(longestFocusBlock, currentFocusBlock);
        currentFocusBlock = 0;
      }
    }

    longestFocusBlock = math.max(longestFocusBlock, currentFocusBlock);

    final totalRecoveryMinutes = recoveryDurations.fold<int>(
      0,
      (total, minutes) => total + minutes,
    );

    return FocusInput(
      platform: platform ?? SettingsService.platform.value,
      productiveMinutes: productive,
      nonProductiveMinutes: math.max(0, totalScreen - productive),
      appSwitchCount: ActivityMetrics.countAppSwitches(activities),
      totalScreenMinutes: totalScreen,
      breaksTaken: breakCount,
      breaksExpected: math.max(1, totalScreen ~/ 20),
      longestFocusBlockMinutes: longestFocusBlock,
      averageRecoveryMinutes: recoveryDurations.isEmpty
          ? 0
          : totalRecoveryMinutes / recoveryDurations.length,
      recoveryEventCount: recoveryDurations.length,
      totalRecoveryMinutes: totalRecoveryMinutes,
      recoveryDurations: recoveryDurations,
    );
  }

  Future<FocusScoreResult> getFocusResultForDate(
    DateTime date, {
    DevicePlatform? platform,
  }) async {
    final input = await buildFocusInputForDate(date, platform: platform);
    return FocusMetrics.calculate(input);
  }

  Future<List<double>> getWeeklyFocusTrend(DevicePlatform platform) async {
    final now = DateTime.now();
    final scores = <double>[];

    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final input = await buildFocusInputForDate(date, platform: platform);
      final result = FocusMetrics.calculate(input);
      scores.add(result.focusScore.toDouble());
    }

    return scores;
  }

  Future<DashboardData> getDashboardData(DevicePlatform platform) async {
    final todayActivities = await getTodayActivities();

    final todayInput = await buildFocusInputForDate(
      DateTime.now(),
      cachedActivities: todayActivities,
      platform: platform,
    );

    final focusResult = FocusMetrics.calculate(todayInput);
    final weeklyTrend = await getWeeklyFocusTrend(platform);

    return DashboardData(
      todayActivities: _sortActivities(todayActivities),
      focusResult: focusResult,
      focusInput: todayInput,
      weeklyFocusTrend: weeklyTrend,
      totalScreenMinutes: todayInput.totalScreenMinutes,
    );
  }
}
