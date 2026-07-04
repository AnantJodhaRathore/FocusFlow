import 'package:flutter/foundation.dart';

import '../models/focus_input.dart';

class SettingsService {
  SettingsService._();

  static final ValueNotifier<DevicePlatform> platform =
      ValueNotifier<DevicePlatform>(DevicePlatform.windows);

  static final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(
    true,
  );

  static final ValueNotifier<bool> breakRemindersEnabled = ValueNotifier<bool>(
    true,
  );

  static final ValueNotifier<bool> eyeBreakRemindersEnabled =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> blinkRemindersEnabled = ValueNotifier<bool>(
    true,
  );

  static final ValueNotifier<bool> stretchRemindersEnabled =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> fatigueWarningsEnabled = ValueNotifier<bool>(
    true,
  );

  static final ValueNotifier<bool> deepWorkProtectionEnabled =
      ValueNotifier<bool>(true);

  static final ValueNotifier<bool> syncEnabled = ValueNotifier<bool>(false);

  static final ValueNotifier<int> eyeBreakIntervalMinutes = ValueNotifier<int>(
    20,
  );

  static final ValueNotifier<int> stretchIntervalMinutes = ValueNotifier<int>(
    60,
  );

  static DevicePlatform get currentPlatform => platform.value;

  static bool get canShowAnyReminder {
    return notificationsEnabled.value && breakRemindersEnabled.value;
  }

  static void setPlatform(DevicePlatform value) {
    platform.value = value;
  }

  static void setNotifications(bool value) {
    notificationsEnabled.value = value;
  }

  static void setBreakReminders(bool value) {
    breakRemindersEnabled.value = value;
  }

  static void setEyeBreakReminders(bool value) {
    eyeBreakRemindersEnabled.value = value;
  }

  static void setBlinkReminders(bool value) {
    blinkRemindersEnabled.value = value;
  }

  static void setStretchReminders(bool value) {
    stretchRemindersEnabled.value = value;
  }

  static void setFatigueWarnings(bool value) {
    fatigueWarningsEnabled.value = value;
  }

  static void setDeepWorkProtection(bool value) {
    deepWorkProtectionEnabled.value = value;
  }

  static void setSync(bool value) {
    syncEnabled.value = value;
  }

  static void setEyeBreakIntervalMinutes(int value) {
    eyeBreakIntervalMinutes.value = value.clamp(5, 120);
  }

  static void setStretchIntervalMinutes(int value) {
    stretchIntervalMinutes.value = value.clamp(15, 240);
  }

  static void resetDefaults() {
    platform.value = DevicePlatform.windows;
    notificationsEnabled.value = true;
    breakRemindersEnabled.value = true;
    eyeBreakRemindersEnabled.value = true;
    blinkRemindersEnabled.value = true;
    stretchRemindersEnabled.value = true;
    fatigueWarningsEnabled.value = true;
    deepWorkProtectionEnabled.value = true;
    syncEnabled.value = false;
    eyeBreakIntervalMinutes.value = 20;
    stretchIntervalMinutes.value = 60;
  }

  static Map<String, dynamic> toMap() {
    return {
      'platform': platform.value.name,
      'notificationsEnabled': notificationsEnabled.value,
      'breakRemindersEnabled': breakRemindersEnabled.value,
      'eyeBreakRemindersEnabled': eyeBreakRemindersEnabled.value,
      'blinkRemindersEnabled': blinkRemindersEnabled.value,
      'stretchRemindersEnabled': stretchRemindersEnabled.value,
      'fatigueWarningsEnabled': fatigueWarningsEnabled.value,
      'deepWorkProtectionEnabled': deepWorkProtectionEnabled.value,
      'syncEnabled': syncEnabled.value,
      'eyeBreakIntervalMinutes': eyeBreakIntervalMinutes.value,
      'stretchIntervalMinutes': stretchIntervalMinutes.value,
    };
  }

  static void applyMap(Map<String, dynamic> map) {
    platform.value = _parsePlatform(map['platform'] as String?);
    notificationsEnabled.value = _readBool(
      map['notificationsEnabled'],
      fallback: true,
    );
    breakRemindersEnabled.value = _readBool(
      map['breakRemindersEnabled'],
      fallback: true,
    );
    eyeBreakRemindersEnabled.value = _readBool(
      map['eyeBreakRemindersEnabled'],
      fallback: true,
    );
    blinkRemindersEnabled.value = _readBool(
      map['blinkRemindersEnabled'],
      fallback: true,
    );
    stretchRemindersEnabled.value = _readBool(
      map['stretchRemindersEnabled'],
      fallback: true,
    );
    fatigueWarningsEnabled.value = _readBool(
      map['fatigueWarningsEnabled'],
      fallback: true,
    );
    deepWorkProtectionEnabled.value = _readBool(
      map['deepWorkProtectionEnabled'],
      fallback: true,
    );
    syncEnabled.value = _readBool(map['syncEnabled']);
    eyeBreakIntervalMinutes.value = _readInt(
      map['eyeBreakIntervalMinutes'],
      fallback: 20,
    ).clamp(5, 120);
    stretchIntervalMinutes.value = _readInt(
      map['stretchIntervalMinutes'],
      fallback: 60,
    ).clamp(15, 240);
  }

  static DevicePlatform _parsePlatform(String? value) {
    return DevicePlatform.values.firstWhere(
      (platform) => platform.name == value,
      orElse: () => DevicePlatform.windows,
    );
  }

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static void dispose() {
    platform.dispose();
    notificationsEnabled.dispose();
    breakRemindersEnabled.dispose();
    eyeBreakRemindersEnabled.dispose();
    blinkRemindersEnabled.dispose();
    stretchRemindersEnabled.dispose();
    fatigueWarningsEnabled.dispose();
    deepWorkProtectionEnabled.dispose();
    syncEnabled.dispose();
    eyeBreakIntervalMinutes.dispose();
    stretchIntervalMinutes.dispose();
  }
}
