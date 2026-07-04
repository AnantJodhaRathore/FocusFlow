class ReminderRules {
  ReminderRules._();

  static const int eyeBreakMinutes = 20;
  static const int blinkReminderMinutes = 30;
  static const int eyeStrainMinutes = 40;
  static const int stretchMinutes = 60;
  static const int hydrationMinutes = 90;
  static const int deepWorkRecoveryMinutes = 90;
  static const int missingRecoveryMinutes = 120;

  static const int focusDriftSwitchLimit = 10;
  static const int lowRecoveryScoreLimit = 40;
  static const int minimumBreakMinutes = 1;
  static const int minimumEyeStrainBreakMinutes = 2;

  static const Duration globalCooldown = Duration(minutes: 10);
  static const Duration blinkCooldown = Duration(minutes: 10);
  static const Duration eyeBreakCooldown = Duration(minutes: 20);
  static const Duration stretchCooldown = Duration(minutes: 45);
  static const Duration hydrationCooldown = Duration(minutes: 45);
  static const Duration fatigueCooldown = Duration(minutes: 30);
  static const Duration recoveryCooldown = Duration(minutes: 30);
  static const Duration distractionCooldown = Duration(minutes: 20);
  static const Duration deepWorkCooldown = Duration(minutes: 45);

  static bool isTwentyTwentyTwentyDue({
    required int screenMinutes,
    required int breakMinutes,
  }) {
    return screenMinutes >= eyeBreakMinutes &&
        breakMinutes < minimumBreakMinutes;
  }

  static bool isBlinkReminderDue(int screenMinutes) {
    return screenMinutes >= blinkReminderMinutes;
  }

  static bool isEyeStrainRisk({
    required int screenMinutes,
    required int breakMinutes,
  }) {
    return screenMinutes >= eyeStrainMinutes &&
        breakMinutes < minimumEyeStrainBreakMinutes;
  }

  static bool isStretchDue(int sittingMinutes) {
    return sittingMinutes >= stretchMinutes;
  }

  static bool isHydrationDue(int sittingMinutes) {
    return sittingMinutes >= hydrationMinutes;
  }

  static bool isDeepWorkRecoveryDue(int uninterruptedMinutes) {
    return uninterruptedMinutes >= deepWorkRecoveryMinutes;
  }

  static bool isMissingRecoveryWindow({
    required int screenMinutes,
    required int recoveryEvents,
  }) {
    return screenMinutes >= missingRecoveryMinutes && recoveryEvents == 0;
  }

  static bool isLowRecoveryQuality(int recoveryScore) {
    return recoveryScore < lowRecoveryScoreLimit;
  }

  static bool isFocusDriftDetected(int appSwitchCount) {
    return appSwitchCount >= focusDriftSwitchLimit;
  }

  static bool isHighFatigueRisk(String fatigueRisk) {
    return fatigueRisk.toLowerCase().trim() == 'high';
  }

  static int expectedBreaksForScreenMinutes(int screenMinutes) {
    if (screenMinutes <= 0) return 0;
    return screenMinutes ~/ eyeBreakMinutes;
  }

  static int nextEyeBreakMinutes(int screenMinutes) {
    if (screenMinutes <= 0) return eyeBreakMinutes;

    final remainder = screenMinutes % eyeBreakMinutes;
    if (remainder == 0) return 0;

    return eyeBreakMinutes - remainder;
  }

  static int estimateSittingMinutes({
    required int totalScreenMinutes,
    required int totalRecoveryMinutes,
  }) {
    return (totalScreenMinutes - totalRecoveryMinutes).clamp(
      0,
      totalScreenMinutes,
    );
  }

  static int estimateRecoveryScore({
    required int totalScreenMinutes,
    required int breaksTaken,
    required int breaksExpected,
    required int totalRecoveryMinutes,
  }) {
    if (totalScreenMinutes <= 0) return 100;

    final expectedBreaks = breaksExpected <= 0 ? 1 : breaksExpected;
    final breakRatio = (breaksTaken / expectedBreaks).clamp(0.0, 1.0);
    final recoveryRatio = (totalRecoveryMinutes / eyeBreakMinutes).clamp(
      0.0,
      1.0,
    );

    return ((breakRatio * 60) + (recoveryRatio * 40)).round().clamp(0, 100);
  }
}

class ReminderCopy {
  ReminderCopy._();

  static const String fatigueHighTitle = 'Fatigue Risk High';
  static const String fatigueHighMessage =
      'Your fatigue risk is high. Take a proper recovery break before continuing.';

  static const String missingRecoveryTitle = 'Missing Recovery Window';
  static const String missingRecoveryMessage =
      'No recovery breaks were detected in the last long work stretch. Step away for a few minutes.';

  static const String lowRecoveryTitle = 'Low Recovery Quality';
  static const String lowRecoveryMessage =
      'Your recovery pattern is weak today. A longer break can help reset your focus.';

  static const String focusDriftTitle = 'Focus Drift Detected';
  static const String focusDriftMessage =
      'Frequent app switching is showing up. Pause briefly and choose one task to continue.';

  static const String hydrationTitle = 'Hydration Break';
  static const String hydrationMessage =
      'You have been seated for a while. Grab water and move around for a minute.';

  static const String stretchTitle = 'Time to Stretch';
  static const String stretchMessage =
      'Stand up, roll your shoulders, and stretch for 30 seconds.';

  static const String eyeStrainTitle = 'Eye Strain Alert';
  static const String eyeStrainMessage =
      'Continuous screen time is building up. Look 20 feet away for 20 seconds.';

  static const String blinkTitle = 'Blink Reminder';
  static const String blinkMessage =
      'Blink slowly a few times to reduce dryness and reset visual focus.';

  static const String twentyTwentyTwentyTitle = '20-20-20 Rule';
  static const String twentyTwentyTwentyMessage =
      'Take a quick 20-second eye break and look away from the screen.';

  static const String deepWorkTitle = 'Deep Work Streak';
  static const String deepWorkMessage =
      'You have sustained a long focus block. Consider a recovery break before fatigue rises.';
}

class ReminderIds {
  ReminderIds._();

  static const String fatigueHigh = 'fatigue_high';
  static const String missingRecovery = 'missing_recovery';
  static const String lowRecoveryQuality = 'low_recovery_quality';
  static const String focusDrift = 'focus_drift';
  static const String hydration = 'hydration';
  static const String stretch = 'stretch';
  static const String eyeStrain = 'eye_strain';
  static const String blink = 'blink';
  static const String twentyTwentyTwenty = 'twenty_twenty_twenty';
  static const String deepWorkRecovery = 'deep_work_recovery';
}
