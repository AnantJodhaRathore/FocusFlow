import 'activity_record.dart';
import 'focus_input.dart';
import 'focus_score_result.dart';

class DashboardData {
  final List<ActivityRecord> todayActivities;
  final FocusScoreResult focusResult;
  final FocusInput focusInput;
  final List<double> weeklyFocusTrend;
  final int totalScreenMinutes;

  const DashboardData({
    required this.todayActivities,
    required this.focusResult,
    required this.focusInput,
    required this.weeklyFocusTrend,
    required this.totalScreenMinutes,
  }) : assert(totalScreenMinutes >= 0);

  factory DashboardData.empty({
    DevicePlatform platform = DevicePlatform.windows,
  }) {
    return DashboardData(
      todayActivities: const [],
      focusResult: FocusScoreResult.empty(platform: platform),
      focusInput: FocusInput.empty(platform: platform),
      weeklyFocusTrend: const [],
      totalScreenMinutes: 0,
    );
  }

  bool get hasActivities => todayActivities.isNotEmpty;

  bool get hasWeeklyTrend => weeklyFocusTrend.isNotEmpty;

  bool get hasData => hasActivities || focusResult.hasData;

  int get focusScore => focusResult.focusScore;

  int get recoveryScore => focusResult.recoveryScore;

  int get productiveMinutes => focusInput.productiveMinutes;

  int get nonProductiveMinutes => focusInput.nonProductiveMinutes;

  int get appSwitchCount => focusInput.appSwitchCount;

  int get recoveryEvents => focusInput.recoveryEventCount;

  int get totalRecoveryMinutes => focusInput.totalRecoveryMinutes;

  double get averageRecoveryMinutes => focusInput.averageRecoveryMinutes;

  double get averageWeeklyFocus {
    if (weeklyFocusTrend.isEmpty) return 0;

    final total = weeklyFocusTrend.fold<double>(0, (sum, score) => sum + score);

    return total / weeklyFocusTrend.length;
  }

  ActivityRecord? get latestActivity {
    if (todayActivities.isEmpty) return null;

    return todayActivities.reduce(
      (latest, activity) =>
          activity.startTime.isAfter(latest.startTime) ? activity : latest,
    );
  }

  DashboardData copyWith({
    List<ActivityRecord>? todayActivities,
    FocusScoreResult? focusResult,
    FocusInput? focusInput,
    List<double>? weeklyFocusTrend,
    int? totalScreenMinutes,
  }) {
    return DashboardData(
      todayActivities: todayActivities ?? this.todayActivities,
      focusResult: focusResult ?? this.focusResult,
      focusInput: focusInput ?? this.focusInput,
      weeklyFocusTrend: weeklyFocusTrend ?? this.weeklyFocusTrend,
      totalScreenMinutes: totalScreenMinutes ?? this.totalScreenMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'todayActivities': todayActivities
          .map((activity) => activity.toMap())
          .toList(),
      'focusResult': focusResult.toMap(),
      'focusInput': focusInput.toMap(),
      'weeklyFocusTrend': weeklyFocusTrend,
      'totalScreenMinutes': totalScreenMinutes,
    };
  }

  factory DashboardData.fromMap(Map<String, dynamic> map) {
    return DashboardData(
      todayActivities: _readActivityList(map['todayActivities']),
      focusResult: FocusScoreResult.fromMap(_readMap(map['focusResult'])),
      focusInput: FocusInput.fromMap(_readMap(map['focusInput'])),
      weeklyFocusTrend: _readDoubleList(map['weeklyFocusTrend']),
      totalScreenMinutes: _readInt(map['totalScreenMinutes']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData.fromMap(json);
  }

  static List<ActivityRecord> _readActivityList(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => ActivityRecord.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<double> _readDoubleList(dynamic value) {
    if (value is List<double>) return value;
    if (value is List) return value.map(_readDouble).toList();
    return const [];
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() {
    return 'DashboardData(todayActivities: ${todayActivities.length}, '
        'focusScore: $focusScore, totalScreenMinutes: $totalScreenMinutes, '
        'weeklyFocusTrend: $weeklyFocusTrend)';
  }
}
