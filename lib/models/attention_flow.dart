import '../models/activity_record.dart';
import '../analytics/activity_metrics.dart';

/// Represents a flow of attention: productive → distraction → recovery.
class AttentionFlow {
  final String productiveApp;
  final String distractionApp;
  final DateTime productiveStart;
  final DateTime distractionStart;
  final DateTime recoveryStart;
  final int distractionMinutes;
  final int recoveryMinutes;

  AttentionFlow({
    required this.productiveApp,
    required this.distractionApp,
    required this.productiveStart,
    required this.distractionStart,
    required this.recoveryStart,
    required this.distractionMinutes,
    required this.recoveryMinutes,
  });

  Map<String, dynamic> toMap() => {
    'productive_app': productiveApp,
    'distraction_app': distractionApp,
    'productive_start': productiveStart.millisecondsSinceEpoch,
    'distraction_start': distractionStart.millisecondsSinceEpoch,
    'recovery_start': recoveryStart.millisecondsSinceEpoch,
    'distraction_duration': distractionMinutes,
    'recovery_duration': recoveryMinutes,
  };

  factory AttentionFlow.fromMap(Map<String, dynamic> map) => AttentionFlow(
    productiveApp: map['productive_app'],
    distractionApp: map['distraction_app'],
    productiveStart: DateTime.fromMillisecondsSinceEpoch(
      map['productive_start'],
    ),
    distractionStart: DateTime.fromMillisecondsSinceEpoch(
      map['distraction_start'],
    ),
    recoveryStart: DateTime.fromMillisecondsSinceEpoch(map['recovery_start']),
    distractionMinutes: map['distraction_duration'],
    recoveryMinutes: map['recovery_duration'],
  );
}

/// Computes recovery and attention flow metrics from [ActivityRecord] sequences.
class RecoveryEngine {
  RecoveryEngine._();

  /// Returns a list of distraction durations (in minutes) for each
  /// productive → distraction → productive occurrence found in [acts].
  ///
  /// [acts] must be ordered by `startTime` ascending.
  static List<int> computeRecoveryDurations(List<ActivityRecord> acts) {
    final productiveCats = {AppCategory.work, AppCategory.research};
    final results = <int>[];

    for (var i = 0; i < acts.length - 1; i++) {
      final cur = acts[i];
      final next = acts[i + 1];
      final curProd = productiveCats.contains(
        ActivityMetrics.parseCategory(cur.category),
      );
      final nextProd = productiveCats.contains(
        ActivityMetrics.parseCategory(next.category),
      );

      if (curProd && !nextProd) {
        var sum = 0;
        var j = i + 1;
        while (j < acts.length &&
            !productiveCats.contains(
              ActivityMetrics.parseCategory(acts[j].category),
            )) {
          sum += acts[j].durationMinutes;
          j += 1;
        }
        if (j < acts.length &&
            productiveCats.contains(
              ActivityMetrics.parseCategory(acts[j].category),
            )) {
          results.add(sum);
        }
      }
    }
    return results;
  }

  /// Computes recovery durations only when
  /// productive → distraction → productive happens in the SAME app.
  static List<int> computeSameAppRecoveryDurations(
    List<ActivityRecord> records,
  ) {
    final durations = <int>[];
    for (var i = 1; i < records.length - 1; i++) {
      final prev = records[i - 1];
      final current = records[i];
      final next = records[i + 1];

      if (_isProductive(prev) &&
          !_isProductive(current) &&
          _isProductive(next) &&
          next.appName == prev.appName) {
        final recovery = next.startTime.difference(current.startTime).inMinutes;
        durations.add(recovery);
      }
    }
    return durations;
  }

  /// Detects attention flows: productive → distraction → recovery.
  static List<AttentionFlow> computeAttentionFlows(
    List<ActivityRecord> records,
  ) {
    final flows = <AttentionFlow>[];
    for (var i = 1; i < records.length - 1; i++) {
      final prev = records[i - 1];
      final current = records[i];
      final next = records[i + 1];

      if (_isProductive(prev) &&
          !_isProductive(current) &&
          _isProductive(next) &&
          next.appName == prev.appName) {
        flows.add(
          AttentionFlow(
            productiveApp: prev.appName,
            distractionApp: current.appName,
            productiveStart: prev.startTime,
            distractionStart: current.startTime,
            recoveryStart: next.startTime,
            distractionMinutes: current.durationMinutes,
            recoveryMinutes: next.startTime
                .difference(current.startTime)
                .inMinutes,
          ),
        );
      }
    }
    return flows;
  }

  static bool _isProductive(ActivityRecord record) {
    const productive = {'Work', 'Research'};
    return productive.contains(record.category);
  }

  /// Returns the average recovery minutes, or 0.0 if none observed.
  static double averageRecoveryMinutes(List<ActivityRecord> acts) {
    final d = computeRecoveryDurations(acts);
    if (d.isEmpty) return 0.0;
    return d.reduce((a, b) => a + b) / d.length;
  }

  /// Total recovery minutes observed.
  static int totalRecoveryMinutes(List<ActivityRecord> acts) {
    final d = computeRecoveryDurations(acts);
    if (d.isEmpty) return 0;
    return d.reduce((a, b) => a + b);
  }

  /// Number of recovery events observed.
  static int recoveryEventCount(List<ActivityRecord> acts) =>
      computeRecoveryDurations(acts).length;
}
