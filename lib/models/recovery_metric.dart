enum RecoveryMetricType {
  microBreak,
  shortBreak,
  longBreak,
  idleBreak,
  screenBreak,
  unknown,
}

enum RecoveryQuality { poor, fair, good, excellent }

class RecoveryMetric {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final int recoveryScore;
  final RecoveryMetricType type;
  final RecoveryQuality quality;
  final String? source;
  final String? note;

  const RecoveryMetric({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.recoveryScore,
    required this.type,
    required this.quality,
    this.source,
    this.note,
  }) : assert(durationMinutes >= 0),
       assert(recoveryScore >= 0 && recoveryScore <= 100);

  factory RecoveryMetric.fromDuration({
    int? id,
    required DateTime startTime,
    required DateTime endTime,
    String? source,
    String? note,
  }) {
    final minutes = endTime.difference(startTime).inMinutes.clamp(0, 1000000);
    final score = scoreForDuration(minutes);

    return RecoveryMetric(
      id: id,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: minutes,
      recoveryScore: score,
      type: typeForDuration(minutes),
      quality: qualityForScore(score),
      source: source,
      note: note,
    );
  }

  bool get isValidRecovery => durationMinutes >= 1;

  bool get isMicroBreak => type == RecoveryMetricType.microBreak;

  bool get isDeepRecovery =>
      type == RecoveryMetricType.longBreak ||
      quality == RecoveryQuality.excellent;

  String get durationLabel {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours <= 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  String get qualityLabel => switch (quality) {
    RecoveryQuality.poor => 'Poor',
    RecoveryQuality.fair => 'Fair',
    RecoveryQuality.good => 'Good',
    RecoveryQuality.excellent => 'Excellent',
  };

  String get typeLabel => switch (type) {
    RecoveryMetricType.microBreak => 'Micro Break',
    RecoveryMetricType.shortBreak => 'Short Break',
    RecoveryMetricType.longBreak => 'Long Break',
    RecoveryMetricType.idleBreak => 'Idle Break',
    RecoveryMetricType.screenBreak => 'Screen Break',
    RecoveryMetricType.unknown => 'Unknown',
  };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'recoveryScore': recoveryScore,
      'type': type.name,
      'quality': quality.name,
      'source': source,
      'note': note,
    };
  }

  factory RecoveryMetric.fromMap(Map<String, dynamic> map) {
    final duration = _readInt(map['durationMinutes']);
    final score = _readInt(map['recoveryScore']).clamp(0, 100);

    return RecoveryMetric(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      durationMinutes: duration < 0 ? 0 : duration,
      recoveryScore: score,
      type: _parseType(map['type'] as String?),
      quality: _parseQuality(map['quality'] as String?),
      source: map['source'] as String?,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory RecoveryMetric.fromJson(Map<String, dynamic> json) =>
      RecoveryMetric.fromMap(json);

  RecoveryMetric copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? recoveryScore,
    RecoveryMetricType? type,
    RecoveryQuality? quality,
    String? source,
    String? note,
  }) {
    return RecoveryMetric(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      recoveryScore: recoveryScore ?? this.recoveryScore,
      type: type ?? this.type,
      quality: quality ?? this.quality,
      source: source ?? this.source,
      note: note ?? this.note,
    );
  }

  static int scoreForDuration(int durationMinutes) {
    if (durationMinutes <= 0) return 0;
    if (durationMinutes < 2) return 25;
    if (durationMinutes < 5) return 50;
    if (durationMinutes < 15) return 75;
    return 100;
  }

  static RecoveryMetricType typeForDuration(int durationMinutes) {
    if (durationMinutes <= 0) return RecoveryMetricType.unknown;
    if (durationMinutes < 2) return RecoveryMetricType.microBreak;
    if (durationMinutes < 15) return RecoveryMetricType.shortBreak;
    return RecoveryMetricType.longBreak;
  }

  static RecoveryQuality qualityForScore(int score) {
    if (score >= 85) return RecoveryQuality.excellent;
    if (score >= 65) return RecoveryQuality.good;
    if (score >= 40) return RecoveryQuality.fair;
    return RecoveryQuality.poor;
  }

  static RecoveryMetricType _parseType(String? value) {
    return RecoveryMetricType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => RecoveryMetricType.unknown,
    );
  }

  static RecoveryQuality _parseQuality(String? value) {
    return RecoveryQuality.values.firstWhere(
      (item) => item.name == value,
      orElse: () => RecoveryQuality.fair,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RecoveryMetric &&
            other.id == id &&
            other.startTime == startTime &&
            other.endTime == endTime &&
            other.durationMinutes == durationMinutes &&
            other.recoveryScore == recoveryScore &&
            other.type == type &&
            other.quality == quality &&
            other.source == source &&
            other.note == note;
  }

  @override
  int get hashCode => Object.hash(
    id,
    startTime,
    endTime,
    durationMinutes,
    recoveryScore,
    type,
    quality,
    source,
    note,
  );

  @override
  String toString() {
    return 'RecoveryMetric(id: $id, startTime: $startTime, endTime: $endTime, '
        'durationMinutes: $durationMinutes, recoveryScore: $recoveryScore, '
        'type: $type, quality: $quality, source: $source, note: $note)';
  }
}
