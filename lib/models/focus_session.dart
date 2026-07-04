class FocusSession {
  final int? id;
  final String appName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  const FocusSession({
    this.id,
    required this.appName,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  }) : assert(durationMinutes >= 0);

  Duration get duration => endTime.difference(startTime);

  int get durationSeconds => duration.inSeconds;

  bool get isOngoing => endTime.isAfter(DateTime.now());

  bool get isValid => !endTime.isBefore(startTime);

  String get durationLabel {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours <= 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'appName': appName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as int?,
      appName: (map['appName'] as String?) ?? 'Unknown App',
      startTime: _readDateTime(map['startTime']),
      endTime: _readDateTime(map['endTime']),
      durationMinutes: _readInt(map['durationMinutes']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession.fromMap(json);
  }

  FocusSession copyWith({
    int? id,
    String? appName,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
  }) {
    return FocusSession(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
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
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FocusSession &&
            other.id == id &&
            other.appName == appName &&
            other.startTime == startTime &&
            other.endTime == endTime &&
            other.durationMinutes == durationMinutes;
  }

  @override
  int get hashCode {
    return Object.hash(id, appName, startTime, endTime, durationMinutes);
  }

  @override
  String toString() {
    return 'FocusSession(id: $id, appName: $appName, startTime: $startTime, '
        'endTime: $endTime, durationMinutes: $durationMinutes)';
  }
}
