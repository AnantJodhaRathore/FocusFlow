import 'dart:async';

import 'package:flutter/foundation.dart';

import '../analytics/activity_metrics.dart';
import '../analytics/eye_health_metrics.dart';
import '../models/activity_record.dart';
import 'activity_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

class FocusAlertService {
  FocusAlertService._internal();

  static final FocusAlertService instance = FocusAlertService._internal();

  final ActivityService _activityService = ActivityService();

  Timer? _timer;

  DateTime? _lastBreakReminderAt;
  DateTime? _lastFatigueAlertAt;

  bool _running = false;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;

    _running = true;

    await _checkAlerts();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkAlerts());

    debugPrint('[FocusFlow] FocusAlertService started');
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;

    debugPrint('[FocusFlow] FocusAlertService stopped');
  }

  Future<void> _checkAlerts() async {
    try {
      if (!SettingsService.notificationsEnabled.value) return;

      final activities = await _activityService.getTodayActivities();

      if (activities.isEmpty) return;

      await _maybeShowBreakReminder(activities);
      await _maybeShowEyeFatigueAlert(activities);
    } catch (error, stackTrace) {
      debugPrint('[FocusFlow] Alert check failed: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _maybeShowBreakReminder(List<ActivityRecord> activities) async {
    if (!SettingsService.breakRemindersEnabled.value) return;

    final totalScreenMinutes = ActivityMetrics.totalScreenMinutes(activities);

    if (totalScreenMinutes < 20) return;

    final minutesAfterBreakPoint = totalScreenMinutes % 20;
    final shouldRemindNow = minutesAfterBreakPoint <= 2;

    if (!shouldRemindNow) return;

    if (!_canNotifyAgain(_lastBreakReminderAt, const Duration(minutes: 18))) {
      return;
    }

    _lastBreakReminderAt = DateTime.now();

    // FIXED: Passed arguments directly instead of nesting inside FocusNotification()
    await NotificationService.instance.show(
      id: 'break-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Time for a 20-20-20 break',
      message: 'Look 20 feet away for 20 seconds to reduce eye strain.',
      type: FocusNotificationType.breakReminder,
      payload: {
        'source': 'focus_alert_service',
        'totalScreenMinutes': totalScreenMinutes,
      },
    );

    debugPrint('[FocusFlow] Break reminder triggered');
  }

  Future<void> _maybeShowEyeFatigueAlert(
    List<ActivityRecord> activities,
  ) async {
    final fatigueRisk = EyeHealthMetrics.calculateFatigueRisk(activities);

    if (fatigueRisk.toLowerCase() != 'high') return;

    if (!_canNotifyAgain(_lastFatigueAlertAt, const Duration(minutes: 45))) {
      return;
    }

    _lastFatigueAlertAt = DateTime.now();

    // FIXED: Passed arguments directly instead of nesting inside FocusNotification()
    await NotificationService.instance.show(
      id: 'fatigue-${DateTime.now().millisecondsSinceEpoch}',
      title: 'High eye fatigue risk',
      message: 'Your screen strain risk is high. Take a short recovery break.',
      type: FocusNotificationType.eyeFatigue,
      payload: {'source': 'focus_alert_service', 'fatigueRisk': fatigueRisk},
    );

    debugPrint('[FocusFlow] Eye fatigue alert triggered');
  }

  bool _canNotifyAgain(DateTime? lastTime, Duration cooldown) {
    if (lastTime == null) return true;

    return DateTime.now().difference(lastTime) >= cooldown;
  }
}
