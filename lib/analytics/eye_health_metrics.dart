import 'dart:math' as math;

import '../models/activity_record.dart';
import 'activity_metrics.dart';

class EyeHealthMetrics {
  EyeHealthMetrics._();

  static const int breakIntervalMinutes = 20;
  static const int mediumFatigueMinutes = 40;
  static const int highFatigueMinutes = 80;
  static const int healthyDailyScreenMinutes = 360;
  static const int excessiveDailyScreenMinutes = 600;

  static int calculateFromActivities(List<ActivityRecord> activities) {
    final screenMinutes = ActivityMetrics.totalScreenMinutes(activities);
    final breaksTaken = ActivityMetrics.breakCount(activities);
    final breaksExpected = expectedBreaks(screenMinutes);

    final screenScore = calculateScreenTimeScore(screenMinutes);
    final breakScore = calculateBreakComplianceScore(
      breaksTaken: breaksTaken,
      breaksExpected: breaksExpected,
    );
    final streakScore = calculateStreakScore(
      longestContinuousWorkMinutes(activities),
    );

    final score =
        (screenScore * 0.45) + (breakScore * 0.35) + (streakScore * 0.20);

    return score.round().clamp(0, 100);
  }

  static int calculateScreenTimeScore(int screenMinutes) {
    if (screenMinutes <= healthyDailyScreenMinutes) return 100;
    if (screenMinutes >= excessiveDailyScreenMinutes) return 0;

    final range = excessiveDailyScreenMinutes - healthyDailyScreenMinutes;
    final excess = screenMinutes - healthyDailyScreenMinutes;

    return (100 - ((excess / range) * 100)).round().clamp(0, 100);
  }

  static int calculateBreakComplianceScore({
    required int breaksTaken,
    required int breaksExpected,
  }) {
    if (breaksExpected <= 0) return 100;

    final ratio = breaksTaken / breaksExpected;
    return (math.min(ratio, 1.0) * 100).round().clamp(0, 100);
  }

  static int calculateStreakScore(int longestStreakMinutes) {
    if (longestStreakMinutes <= breakIntervalMinutes) return 100;
    if (longestStreakMinutes >= highFatigueMinutes) return 0;

    final range = highFatigueMinutes - breakIntervalMinutes;
    final excess = longestStreakMinutes - breakIntervalMinutes;

    return (100 - ((excess / range) * 100)).round().clamp(0, 100);
  }

  static String calculateFatigueRisk(List<ActivityRecord> activities) {
    final streak = longestContinuousWorkMinutes(activities);

    if (streak >= highFatigueMinutes) return 'High';
    if (streak >= mediumFatigueMinutes) return 'Medium';
    return 'Low';
  }

  static int calculateNextBreakMinutes(List<ActivityRecord> activities) {
    if (activities.isEmpty) return breakIntervalMinutes;

    final currentStreak = currentUnbrokenWorkMinutes(activities);
    return math.max(0, breakIntervalMinutes - currentStreak);
  }

  static int longestContinuousWorkMinutes(List<ActivityRecord> activities) {
    final sorted = ActivityMetrics.sortedByStartTime(activities);
    var longest = 0;
    var current = 0;

    for (final activity in sorted) {
      if (_isWellnessBreak(activity)) {
        longest = math.max(longest, current);
        current = 0;
      } else {
        current += activity.durationMinutes;
      }
    }

    return math.max(longest, current);
  }

  static int currentUnbrokenWorkMinutes(List<ActivityRecord> activities) {
    final sorted = ActivityMetrics.sortedByStartTime(activities);
    var current = 0;

    for (final activity in sorted) {
      if (_isWellnessBreak(activity)) {
        current = 0;
      } else {
        current += activity.durationMinutes;
      }
    }

    return current;
  }

  static int expectedBreaks(int screenMinutes) {
    if (screenMinutes <= 0) return 0;
    return screenMinutes ~/ breakIntervalMinutes;
  }

  static bool isBreakDue(List<ActivityRecord> activities) {
    return calculateNextBreakMinutes(activities) == 0;
  }

  static bool _isWellnessBreak(ActivityRecord activity) {
    final category = ActivityMetrics.parseCategory(activity.category);
    final appName = activity.appName.toLowerCase().trim();

    return ActivityMetrics.isBreakCategory(category) ||
        appName == 'break' ||
        appName == 'idle' ||
        appName == 'idle time' ||
        appName == 'away' ||
        appName == 'rest';
  }

  @Deprecated(
    'Use calculateFromActivities(activities) with real activity data instead.',
  )
  static int calculateEyeHealthScore() => 88;

  @Deprecated(
    'Use calculateFatigueRisk(activities) with real activity data instead.',
  )
  static String fatigueRisk() => 'Low';

  @Deprecated(
    'Use ActivityMetrics.totalScreenMinutes(activities) with real activity data instead.',
  )
  static int screenTimeMinutes() => 275;

  @Deprecated(
    'Use calculateNextBreakMinutes(activities) with real activity data instead.',
  )
  static int nextBreakMinutes() => 8;
}
