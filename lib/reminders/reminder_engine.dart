import '../models/focus_input.dart';
import '../services/notification_service.dart';

enum ReminderType {
  eyeBreak,
  blink,
  stretch,
  hydration,
  recovery,
  fatigue,
  distraction,
  deepWork,
}

enum ReminderPriority { low, medium, high, critical }

class Reminder {
  final String id;
  final ReminderType type;
  final ReminderPriority priority;
  final String title;
  final String message;
  final Duration cooldown;

  const Reminder({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.cooldown,
  });

  FocusNotificationType get notificationType => switch (type) {
    ReminderType.eyeBreak => FocusNotificationType.eyeBreak,
    ReminderType.blink => FocusNotificationType.blink,
    ReminderType.stretch => FocusNotificationType.stretch,
    ReminderType.hydration => FocusNotificationType.general,
    ReminderType.recovery => FocusNotificationType.focusRecovery,
    ReminderType.fatigue => FocusNotificationType.fatigue,
    ReminderType.distraction => FocusNotificationType.general,
    ReminderType.deepWork => FocusNotificationType.focusRecovery,
  };
}

class ReminderEngine {
  ReminderEngine._();

  static final Map<String, DateTime> _lastShownByReminderId = {};
  static DateTime? _lastGlobalReminderAt;

  static const Duration globalCooldown = Duration(minutes: 10);

  static Reminder? evaluate(
    FocusInput input, {
    String fatigueRisk = 'low',
    DateTime? now,
    bool deepWorkProtectionEnabled = true,
  }) {
    final currentTime = now ?? DateTime.now();

    final screenMinutes = input.totalScreenMinutes;
    final breakMinutes = input.totalRecoveryMinutes;
    final uninterruptedMinutes = input.longestFocusBlockMinutes;
    final recoveryEvents = input.recoveryEventCount;
    final distractionCount = input.appSwitchCount;
    final recoveryScore = _estimateRecoveryScore(input);
    final sittingMinutes = _estimateSittingMinutes(input);

    final candidates = <Reminder>[
      if (fatigueRisk.toLowerCase() == 'high')
        const Reminder(
          id: 'fatigue_high',
          type: ReminderType.fatigue,
          priority: ReminderPriority.critical,
          title: 'Fatigue Risk High',
          message:
              'Your fatigue risk is high. Take a proper recovery break before continuing.',
          cooldown: Duration(minutes: 30),
        ),
      if (screenMinutes >= 120 && recoveryEvents == 0)
        const Reminder(
          id: 'missing_recovery',
          type: ReminderType.recovery,
          priority: ReminderPriority.high,
          title: 'Missing Recovery Window',
          message:
              'No recovery breaks were detected in the last long work stretch. Step away for a few minutes.',
          cooldown: Duration(minutes: 30),
        ),
      if (recoveryScore < 40 && screenMinutes >= 60)
        const Reminder(
          id: 'low_recovery_quality',
          type: ReminderType.recovery,
          priority: ReminderPriority.high,
          title: 'Low Recovery Quality',
          message:
              'Your recovery pattern is weak today. A longer break can help reset your focus.',
          cooldown: Duration(minutes: 30),
        ),
      if (distractionCount >= 10)
        const Reminder(
          id: 'focus_drift',
          type: ReminderType.distraction,
          priority: ReminderPriority.medium,
          title: 'Focus Drift Detected',
          message:
              'Frequent app switching is showing up. Pause briefly and choose one task to continue.',
          cooldown: Duration(minutes: 20),
        ),
      if (sittingMinutes >= 90)
        const Reminder(
          id: 'hydration',
          type: ReminderType.hydration,
          priority: ReminderPriority.medium,
          title: 'Hydration Break',
          message:
              'You have been seated for a while. Grab water and move around for a minute.',
          cooldown: Duration(minutes: 45),
        ),
      if (sittingMinutes >= 60)
        const Reminder(
          id: 'stretch',
          type: ReminderType.stretch,
          priority: ReminderPriority.medium,
          title: 'Time to Stretch',
          message: 'Stand up, roll your shoulders, and stretch for 30 seconds.',
          cooldown: Duration(minutes: 45),
        ),
      if (screenMinutes >= 40 && breakMinutes < 2)
        const Reminder(
          id: 'eye_strain',
          type: ReminderType.eyeBreak,
          priority: ReminderPriority.medium,
          title: 'Eye Strain Alert',
          message:
              'Continuous screen time is building up. Look 20 feet away for 20 seconds.',
          cooldown: Duration(minutes: 20),
        ),
      if (screenMinutes >= 30)
        const Reminder(
          id: 'blink',
          type: ReminderType.blink,
          priority: ReminderPriority.low,
          title: 'Blink Reminder',
          message:
              'Blink slowly a few times to reduce dryness and reset visual focus.',
          cooldown: Duration(minutes: 10),
        ),
      if (screenMinutes >= 20 && breakMinutes < 1)
        const Reminder(
          id: 'twenty_twenty_twenty',
          type: ReminderType.eyeBreak,
          priority: ReminderPriority.medium,
          title: '20-20-20 Rule',
          message:
              'Take a quick 20-second eye break and look away from the screen.',
          cooldown: Duration(minutes: 20),
        ),
      if (deepWorkProtectionEnabled && uninterruptedMinutes >= 90)
        const Reminder(
          id: 'deep_work_recovery',
          type: ReminderType.deepWork,
          priority: ReminderPriority.medium,
          title: 'Deep Work Streak',
          message:
              'You have sustained a long focus block. Consider a recovery break before fatigue rises.',
          cooldown: Duration(minutes: 45),
        ),
    ];

    for (final reminder in candidates) {
      if (_canShow(reminder, currentTime)) {
        return reminder;
      }
    }

    return null;
  }

  static Future<bool> evaluateAndNotify(
    FocusInput input, {
    String fatigueRisk = 'low',
    DateTime? now,
    bool deepWorkProtectionEnabled = true,
    NotificationService? notificationService,
  }) async {
    final reminder = evaluate(
      input,
      fatigueRisk: fatigueRisk,
      now: now,
      deepWorkProtectionEnabled: deepWorkProtectionEnabled,
    );

    if (reminder == null) return false;

    final shown = await (notificationService ?? NotificationService.instance)
        .show(
          id: reminder.id,
          title: reminder.title,
          message: reminder.message,
          type: reminder.notificationType,
          cooldown: reminder.cooldown,
        );

    if (shown) {
      markReminderShown(reminder, now: now);
    }

    return shown;
  }

  static void markReminderShown(Reminder reminder, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    _lastGlobalReminderAt = currentTime;
    _lastShownByReminderId[reminder.id] = currentTime;
  }

  static void resetCooldowns() {
    _lastGlobalReminderAt = null;
    _lastShownByReminderId.clear();
  }

  static bool _canShow(Reminder reminder, DateTime now) {
    final lastGlobal = _lastGlobalReminderAt;
    if (lastGlobal != null && now.difference(lastGlobal) < globalCooldown) {
      return false;
    }

    final lastSpecific = _lastShownByReminderId[reminder.id];
    if (lastSpecific == null) return true;

    return now.difference(lastSpecific) >= reminder.cooldown;
  }

  static int _estimateRecoveryScore(FocusInput input) {
    if (input.totalScreenMinutes <= 0) return 100;

    final expectedBreaks = input.breaksExpected <= 0 ? 1 : input.breaksExpected;
    final breakRatio = (input.breaksTaken / expectedBreaks).clamp(0.0, 1.0);
    final recoveryRatio = (input.totalRecoveryMinutes / 20).clamp(0.0, 1.0);

    return ((breakRatio * 60) + (recoveryRatio * 40)).round().clamp(0, 100);
  }

  static int _estimateSittingMinutes(FocusInput input) {
    return (input.totalScreenMinutes - input.totalRecoveryMinutes).clamp(
      0,
      input.totalScreenMinutes,
    );
  }
}
