import '../models/activity_record.dart';
import 'activity_metrics.dart';

class AttentionFlow {
  final int? id;
  final String productiveApp;
  final String distractionApp;
  final DateTime productiveStart;
  final DateTime distractionStart;
  final DateTime recoveryStart;
  final int distractionMinutes;
  final int recoveryMinutes;

  const AttentionFlow({
    this.id,
    required this.productiveApp,
    required this.distractionApp,
    required this.productiveStart,
    required this.distractionStart,
    required this.recoveryStart,
    required this.distractionMinutes,
    required this.recoveryMinutes,
  }) : assert(distractionMinutes >= 0),
       assert(recoveryMinutes >= 0);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productive_app': productiveApp,
      'distraction_app': distractionApp,
      'productive_start': productiveStart.toIso8601String(),
      'distraction_start': distractionStart.toIso8601String(),
      'recovery_start': recoveryStart.toIso8601String(),
      'distraction_duration': distractionMinutes,
      'recovery_duration': recoveryMinutes,
    };
  }

  factory AttentionFlow.fromMap(Map<String, dynamic> map) {
    return AttentionFlow(
      id: map['id'] as int?,
      productiveApp: (map['productive_app'] as String?) ?? 'Unknown App',
      distractionApp: (map['distraction_app'] as String?) ?? 'Unknown App',
      productiveStart: _readDateTime(map['productive_start']),
      distractionStart: _readDateTime(map['distraction_start']),
      recoveryStart: _readDateTime(map['recovery_start']),
      distractionMinutes: _readInt(map['distraction_duration']),
      recoveryMinutes: _readInt(map['recovery_duration']),
    );
  }

  AttentionFlow copyWith({
    int? id,
    String? productiveApp,
    String? distractionApp,
    DateTime? productiveStart,
    DateTime? distractionStart,
    DateTime? recoveryStart,
    int? distractionMinutes,
    int? recoveryMinutes,
  }) {
    return AttentionFlow(
      id: id ?? this.id,
      productiveApp: productiveApp ?? this.productiveApp,
      distractionApp: distractionApp ?? this.distractionApp,
      productiveStart: productiveStart ?? this.productiveStart,
      distractionStart: distractionStart ?? this.distractionStart,
      recoveryStart: recoveryStart ?? this.recoveryStart,
      distractionMinutes: distractionMinutes ?? this.distractionMinutes,
      recoveryMinutes: recoveryMinutes ?? this.recoveryMinutes,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  String toString() {
    return 'AttentionFlow(id: $id, productiveApp: $productiveApp, '
        'distractionApp: $distractionApp, distractionMinutes: $distractionMinutes, '
        'recoveryMinutes: $recoveryMinutes)';
  }
}

class RecoveryEngine {
  RecoveryEngine._();

  static List<int> computeRecoveryDurations(List<ActivityRecord> records) {
    return computeAttentionFlows(
      records,
    ).map((flow) => flow.recoveryMinutes).toList();
  }

  static List<int> computeDistractionDurations(List<ActivityRecord> records) {
    return computeAttentionFlows(
      records,
    ).map((flow) => flow.distractionMinutes).toList();
  }

  static List<int> computeSameAppRecoveryDurations(
    List<ActivityRecord> records,
  ) {
    return computeAttentionFlows(records)
        .where((flow) => flow.productiveApp == flow.distractionApp)
        .map((flow) => flow.recoveryMinutes)
        .toList();
  }

  static List<AttentionFlow> computeAttentionFlows(
    List<ActivityRecord> records,
  ) {
    final activities = ActivityMetrics.sortedByStartTime(records);
    final flows = <AttentionFlow>[];

    var i = 0;

    while (i < activities.length - 2) {
      final productive = activities[i];

      if (!_isProductive(productive)) {
        i++;
        continue;
      }

      final firstDistractionIndex = i + 1;
      if (firstDistractionIndex >= activities.length ||
          _isProductive(activities[firstDistractionIndex])) {
        i++;
        continue;
      }

      var distractionMinutes = 0;
      var recoveryIndex = firstDistractionIndex;

      while (recoveryIndex < activities.length &&
          !_isProductive(activities[recoveryIndex])) {
        distractionMinutes += activities[recoveryIndex].durationMinutes;
        recoveryIndex++;
      }

      if (recoveryIndex >= activities.length) {
        break;
      }

      final firstDistraction = activities[firstDistractionIndex];
      final recovery = activities[recoveryIndex];
      final recoveryMinutes = recovery.startTime
          .difference(firstDistraction.startTime)
          .inMinutes
          .clamp(0, 1000000);

      flows.add(
        AttentionFlow(
          productiveApp: productive.appName,
          distractionApp: firstDistraction.appName,
          productiveStart: productive.startTime,
          distractionStart: firstDistraction.startTime,
          recoveryStart: recovery.startTime,
          distractionMinutes: distractionMinutes,
          recoveryMinutes: recoveryMinutes,
        ),
      );

      i = recoveryIndex;
    }

    return flows;
  }

  static double averageRecoveryMinutes(List<ActivityRecord> records) {
    final durations = computeRecoveryDurations(records);
    if (durations.isEmpty) return 0;

    return durations.reduce((a, b) => a + b) / durations.length;
  }

  static int totalRecoveryMinutes(List<ActivityRecord> records) {
    final durations = computeRecoveryDurations(records);
    if (durations.isEmpty) return 0;

    return durations.reduce((a, b) => a + b);
  }

  static int recoveryEventCount(List<ActivityRecord> records) {
    return computeRecoveryDurations(records).length;
  }

  static int longestRecoveryMinutes(List<ActivityRecord> records) {
    final durations = computeRecoveryDurations(records);
    if (durations.isEmpty) return 0;

    return durations.reduce((a, b) => a > b ? a : b);
  }

  static bool hasRecoveryEvents(List<ActivityRecord> records) {
    return recoveryEventCount(records) > 0;
  }

  static bool _isProductive(ActivityRecord record) {
    return ActivityMetrics.isProductiveCategory(
      ActivityMetrics.parseCategory(record.category),
    );
  }
}
