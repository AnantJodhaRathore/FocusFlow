import '../models/activity_record.dart';

enum AppCategory {
  work,
  research,
  productive,
  coding,
  study,
  learning,
  breakTime,
  wellness,
  entertainment,
  communication,
  social,
  leisure,
  neutral,
  unknown,
  other,
}

class ActivityMetrics {
  ActivityMetrics._();

  static AppCategory parseCategory(String? category) {
    final value = category?.toLowerCase().trim();

    return switch (value) {
      'work' => AppCategory.work,
      'research' => AppCategory.research,
      'productive' => AppCategory.productive,
      'coding' => AppCategory.coding,
      'study' => AppCategory.study,
      'learning' => AppCategory.learning,
      'break' || 'breaktime' || 'break_time' => AppCategory.breakTime,
      'wellness' || 'health' || 'recovery' => AppCategory.wellness,
      'entertainment' || 'distracting' => AppCategory.entertainment,
      'communication' => AppCategory.communication,
      'social' => AppCategory.social,
      'leisure' => AppCategory.leisure,
      'neutral' => AppCategory.neutral,
      'unknown' => AppCategory.unknown,
      _ => AppCategory.other,
    };
  }

  static bool isProductiveCategory(AppCategory category) {
    return category == AppCategory.work ||
        category == AppCategory.research ||
        category == AppCategory.productive ||
        category == AppCategory.coding ||
        category == AppCategory.study ||
        category == AppCategory.learning;
  }

  static bool isBreakCategory(AppCategory category) {
    return category == AppCategory.breakTime ||
        category == AppCategory.wellness;
  }

  static bool isDistractingCategory(AppCategory category) {
    return category == AppCategory.entertainment ||
        category == AppCategory.social ||
        category == AppCategory.leisure;
  }

  static List<ActivityRecord> sortedByStartTime(List<ActivityRecord> acts) {
    return [...acts]..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  static int totalScreenMinutes(List<ActivityRecord> acts) {
    return acts.fold<int>(0, (sum, activity) => sum + activity.durationMinutes);
  }

  static int productiveMinutes(List<ActivityRecord> acts) {
    return acts.fold<int>(0, (sum, activity) {
      final category = parseCategory(activity.category);
      return isProductiveCategory(category)
          ? sum + activity.durationMinutes
          : sum;
    });
  }

  static int nonProductiveMinutes(List<ActivityRecord> acts) {
    final total = totalScreenMinutes(acts);
    final productive = productiveMinutes(acts);
    return (total - productive).clamp(0, total);
  }

  static int distractingMinutes(List<ActivityRecord> acts) {
    return acts.fold<int>(0, (sum, activity) {
      final category = parseCategory(activity.category);
      return isDistractingCategory(category)
          ? sum + activity.durationMinutes
          : sum;
    });
  }

  static int breakMinutes(List<ActivityRecord> acts) {
    return acts.fold<int>(0, (sum, activity) {
      if (_isBreakActivity(activity)) {
        return sum + activity.durationMinutes;
      }

      return sum;
    });
  }

  static int breakCount(List<ActivityRecord> acts) {
    return acts.where(_isBreakActivity).length;
  }

  static int appSwitchCount(List<ActivityRecord> acts) {
    final sorted = sortedByStartTime(acts);
    String? lastAppName;
    var switches = 0;

    for (final activity in sorted) {
      final appName = activity.appName.trim().toLowerCase();
      if (appName.isEmpty) continue;

      if (lastAppName != null && lastAppName != appName) {
        switches++;
      }

      lastAppName = appName;
    }

    return switches;
  }

  static int countSwitches(List<ActivityRecord> acts) {
    return appSwitchCount(acts);
  }

  static int countAppSwitches(List<ActivityRecord> activities) {
    return appSwitchCount(activities);
  }

  static int longestProductiveBlockMinutes(List<ActivityRecord> acts) {
    final sorted = sortedByStartTime(acts);
    var longest = 0;
    var current = 0;

    for (final activity in sorted) {
      final category = parseCategory(activity.category);

      if (isProductiveCategory(category)) {
        current += activity.durationMinutes;
      } else {
        if (current > longest) longest = current;
        current = 0;
      }
    }

    return current > longest ? current : longest;
  }

  static Map<AppCategory, int> minutesByCategory(List<ActivityRecord> acts) {
    final result = <AppCategory, int>{};

    for (final activity in acts) {
      final category = parseCategory(activity.category);
      result[category] = (result[category] ?? 0) + activity.durationMinutes;
    }

    return result;
  }

  static Map<String, int> minutesByApp(List<ActivityRecord> acts) {
    final result = <String, int>{};

    for (final activity in acts) {
      final appName = activity.appName.trim().isEmpty
          ? 'Unknown App'
          : activity.appName.trim();
      result[appName] = (result[appName] ?? 0) + activity.durationMinutes;
    }

    return result;
  }

  static ActivityRecord? mostUsedActivity(List<ActivityRecord> acts) {
    if (acts.isEmpty) return null;

    return acts.reduce(
      (best, activity) =>
          activity.durationMinutes > best.durationMinutes ? activity : best,
    );
  }

  static bool _isBreakActivity(ActivityRecord activity) {
    final category = parseCategory(activity.category);
    final appName = activity.appName.toLowerCase().trim();

    return isBreakCategory(category) ||
        appName == 'break' ||
        appName == 'idle time' ||
        appName == 'idle';
  }

  static List<ActivityRecord> mergeConsecutiveActivities(
    List<ActivityRecord> activities, {
    int gapToleranceMinutes = 1,
  }) {
    if (activities.isEmpty) return [];

    final sorted = List<ActivityRecord>.from(activities)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final merged = <ActivityRecord>[];

    for (final activity in sorted) {
      if (merged.isEmpty) {
        merged.add(activity);
        continue;
      }

      final previous = merged.last;

      final previousEndTime = previous.startTime.add(
        Duration(minutes: previous.durationMinutes),
      );

      final gapMinutes = activity.startTime
          .difference(previousEndTime)
          .inMinutes;

      final sameApp =
          previous.appName.trim().toLowerCase() ==
          activity.appName.trim().toLowerCase();

      final sameCategory =
          previous.category.trim().toLowerCase() ==
          activity.category.trim().toLowerCase();

      final closeEnough = gapMinutes <= gapToleranceMinutes;

      if (sameApp && sameCategory && closeEnough) {
        merged[merged.length - 1] = ActivityRecord(
          id: previous.id,
          appName: previous.appName,
          category: previous.category,
          durationMinutes: previous.durationMinutes + activity.durationMinutes,
          startTime: previous.startTime,
        );
      } else {
        merged.add(activity);
      }
    }

    return merged;
  }
}
