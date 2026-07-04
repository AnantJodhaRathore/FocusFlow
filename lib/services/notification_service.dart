import 'dart:async';

import 'package:flutter/foundation.dart';

enum FocusNotificationType {
  eyeBreak,
  blink,
  stretch,
  fatigue,
  focusRecovery,
  general,
  eyeFatigue,
  breakReminder, // Added new value
}

class FocusNotification {
  final String id;
  final String title;
  final String message;
  final FocusNotificationType type;
  final DateTime createdAt;
  final Map<String, Object?> payload;

  const FocusNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.payload = const {},
  });

  FocusNotification copyWith({
    String? id,
    String? title,
    String? message,
    FocusNotificationType? type,
    DateTime? createdAt,
    Map<String, Object?>? payload,
  }) {
    return FocusNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'payload': payload,
    };
  }

  @override
  String toString() {
    return 'FocusNotification(id: $id, title: $title, message: $message, '
        'type: $type, createdAt: $createdAt, payload: $payload)';
  }
}

abstract class NotificationBridge {
  Future<void> initialize();

  Future<void> show(FocusNotification notification);

  Future<void> cancelAll();

  Future<void> dispose();
}

class DebugNotificationBridge implements NotificationBridge {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> show(FocusNotification notification) async {
    debugPrint(
      '[NotificationService] ${notification.title}: ${notification.message}',
    );
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> dispose() async {}
}

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final ValueNotifier<FocusNotification?> lastNotification =
      ValueNotifier<FocusNotification?>(null);

  final ValueNotifier<int> notificationVersion = ValueNotifier<int>(0);

  final List<FocusNotification> _history = [];
  final Map<String, DateTime> _lastShownById = {};

  NotificationBridge _bridge = DebugNotificationBridge();
  bool _isInitialized = false;

  static const Duration defaultCooldown = Duration(minutes: 5);
  static const int maxHistoryItems = 50;

  bool get isInitialized => _isInitialized;

  List<FocusNotification> get history => List.unmodifiable(_history);

  Future<void> initialize({NotificationBridge? bridge}) async {
    if (bridge != null) {
      if (_isInitialized) {
        await _bridge.dispose();
      }
      _bridge = bridge;
      _isInitialized = false;
    }

    if (_isInitialized) return;

    await _bridge.initialize();
    _isInitialized = true;
  }

  // FIXED: Removed the unused positional FocusNotification argument
  Future<bool> show({
    required String id,
    required String title,
    required String message,
    FocusNotificationType type = FocusNotificationType.general,
    Duration cooldown = defaultCooldown,
    Map<String, Object?> payload = const {},
    bool force = false,
  }) async {
    await initialize();

    if (!force && !canShow(id: id, cooldown: cooldown)) {
      return false;
    }

    final notification = FocusNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      payload: payload,
    );

    await _bridge.show(notification);
    _recordShown(notification);

    return true;
  }

  Future<bool> showEyeBreakReminder({
    int? nextBreakMinutes,
    bool force = false,
  }) {
    final message = nextBreakMinutes == null || nextBreakMinutes <= 0
        ? 'Look 20 feet away for 20 seconds to relax your eyes.'
        : 'Your next eye break is due in $nextBreakMinutes minutes.';

    return show(
      id: 'eye_break',
      title: 'Eye Break',
      message: message,
      type: FocusNotificationType.eyeBreak,
      cooldown: const Duration(minutes: 20),
      force: force,
    );
  }

  Future<bool> showBlinkReminder({bool force = false}) {
    return show(
      id: 'blink',
      title: 'Blink Reminder',
      message: 'Blink slowly a few times to reduce eye dryness.',
      type: FocusNotificationType.blink,
      cooldown: const Duration(minutes: 10),
      force: force,
    );
  }

  Future<bool> showStretchReminder({
    int sittingMinutes = 60,
    bool force = false,
  }) {
    return show(
      id: 'stretch',
      title: 'Stretch Break',
      message:
          'You have been sitting for about $sittingMinutes minutes. Stand up and stretch.',
      type: FocusNotificationType.stretch,
      cooldown: const Duration(minutes: 45),
      payload: {'sittingMinutes': sittingMinutes},
      force: force,
    );
  }

  Future<bool> showFatigueWarning({String risk = 'high', bool force = false}) {
    return show(
      id: 'fatigue_$risk',
      title: 'Fatigue Risk',
      message:
          'Your current fatigue risk is $risk. A short recovery break may help.',
      type: FocusNotificationType.fatigue,
      cooldown: const Duration(minutes: 30),
      payload: {'risk': risk},
      force: force,
    );
  }

  Future<bool> showFocusRecoveryReminder({
    int focusMinutes = 90,
    bool force = false,
  }) {
    return show(
      id: 'focus_recovery',
      title: 'Recovery Break',
      message:
          'You have focused for about $focusMinutes minutes. Take a proper recovery break.',
      type: FocusNotificationType.focusRecovery,
      cooldown: const Duration(minutes: 45),
      payload: {'focusMinutes': focusMinutes},
      force: force,
    );
  }

  bool canShow({required String id, Duration cooldown = defaultCooldown}) {
    final lastShownAt = _lastShownById[id];
    if (lastShownAt == null) return true;

    return DateTime.now().difference(lastShownAt) >= cooldown;
  }

  void markShown(String id) {
    _lastShownById[id] = DateTime.now();
  }

  Future<void> cancelAll() async {
    await initialize();
    await _bridge.cancelAll();
  }

  void clearHistory() {
    _history.clear();
    lastNotification.value = null;
    notificationVersion.value++;
  }

  void resetCooldowns() {
    _lastShownById.clear();
  }

  Future<void> dispose() async {
    await _bridge.dispose();
    lastNotification.dispose();
    notificationVersion.dispose();
    _isInitialized = false;
  }

  void _recordShown(FocusNotification notification) {
    _lastShownById[notification.id] = notification.createdAt;
    _history.insert(0, notification);

    if (_history.length > maxHistoryItems) {
      _history.removeRange(maxHistoryItems, _history.length);
    }

    lastNotification.value = notification;
    notificationVersion.value++;
  }
}
