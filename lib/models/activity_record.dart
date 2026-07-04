class ActivityRecord {
  final int? id;
  final String appName;
  final String category;
  final int durationMinutes;
  final DateTime startTime;

  const ActivityRecord({
    this.id,
    required this.appName,
    required this.category,
    required this.durationMinutes,
    required this.startTime,
  }) : assert(durationMinutes >= 0);

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  bool get isBreak => category.toLowerCase() == 'break';

  bool get isProductive {
    final normalized = category.toLowerCase();
    return normalized == 'work' ||
        normalized == 'research' ||
        normalized == 'productive' ||
        normalized == 'coding' ||
        normalized == 'study' ||
        normalized == 'learning';
  }

  bool get isDistracting {
    final normalized = category.toLowerCase();
    return normalized == 'leisure' ||
        normalized == 'entertainment' ||
        normalized == 'social' ||
        normalized == 'distracting';
  }

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
      'category': category.toLowerCase().trim(),
      'durationMinutes': durationMinutes,
      'startTime': startTime.toIso8601String(),
    };
  }

  factory ActivityRecord.fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      id: map['id'] as int?,
      appName: (map['appName'] as String?) ?? 'Unknown App',
      category: ((map['category'] as String?) ?? 'unknown')
          .toLowerCase()
          .trim(),
      durationMinutes: _readInt(map['durationMinutes']),
      startTime: _readDateTime(map['startTime']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord.fromMap(json);
  }

  ActivityRecord copyWith({
    int? id,
    String? appName,
    String? category,
    int? durationMinutes,
    DateTime? startTime,
  }) {
    return ActivityRecord(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
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
        other is ActivityRecord &&
            other.id == id &&
            other.appName == appName &&
            other.category == category &&
            other.durationMinutes == durationMinutes &&
            other.startTime == startTime;
  }

  @override
  int get hashCode {
    return Object.hash(id, appName, category, durationMinutes, startTime);
  }

  @override
  String toString() {
    return 'ActivityRecord(id: $id, appName: $appName, category: $category, '
        'durationMinutes: $durationMinutes, startTime: $startTime)';
  }
}
