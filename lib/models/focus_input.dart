enum DevicePlatform { windows, android, tablet, web }

class FocusInput {
  final DevicePlatform platform;
  final int productiveMinutes;
  final int nonProductiveMinutes;
  final int appSwitchCount;
  final int totalScreenMinutes;
  final int breaksTaken;
  final int breaksExpected;
  final int longestFocusBlockMinutes;
  final double averageRecoveryMinutes;
  final int recoveryEventCount;
  final int totalRecoveryMinutes;
  final List<int> recoveryDurations;

  const FocusInput({
    required this.platform,
    required this.productiveMinutes,
    required this.nonProductiveMinutes,
    required this.appSwitchCount,
    required this.totalScreenMinutes,
    required this.breaksTaken,
    required this.breaksExpected,
    required this.longestFocusBlockMinutes,
    this.averageRecoveryMinutes = 0,
    this.recoveryEventCount = 0,
    this.totalRecoveryMinutes = 0,
    this.recoveryDurations = const [],
  }) : assert(productiveMinutes >= 0),
       assert(nonProductiveMinutes >= 0),
       assert(appSwitchCount >= 0),
       assert(totalScreenMinutes >= 0),
       assert(breaksTaken >= 0),
       assert(breaksExpected >= 0),
       assert(longestFocusBlockMinutes >= 0),
       assert(averageRecoveryMinutes >= 0),
       assert(recoveryEventCount >= 0),
       assert(totalRecoveryMinutes >= 0);

  factory FocusInput.empty({DevicePlatform platform = DevicePlatform.windows}) {
    return FocusInput(
      platform: platform,
      productiveMinutes: 0,
      nonProductiveMinutes: 0,
      appSwitchCount: 0,
      totalScreenMinutes: 0,
      breaksTaken: 0,
      breaksExpected: 0,
      longestFocusBlockMinutes: 0,
    );
  }

  int get totalTrackedMinutes => productiveMinutes + nonProductiveMinutes;

  int get distractionMinutes => nonProductiveMinutes;

  int get sittingMinutes {
    return (totalScreenMinutes - totalRecoveryMinutes).clamp(
      0,
      totalScreenMinutes,
    );
  }

  double get productiveRatio {
    if (totalScreenMinutes <= 0) return 0;
    return productiveMinutes / totalScreenMinutes;
  }

  double get breakCompletionRatio {
    if (breaksExpected <= 0) return 1;
    return (breaksTaken / breaksExpected).clamp(0.0, 1.0);
  }

  bool get hasActivity => totalScreenMinutes > 0;

  FocusInput copyWith({
    DevicePlatform? platform,
    int? productiveMinutes,
    int? nonProductiveMinutes,
    int? appSwitchCount,
    int? totalScreenMinutes,
    int? breaksTaken,
    int? breaksExpected,
    int? longestFocusBlockMinutes,
    double? averageRecoveryMinutes,
    int? recoveryEventCount,
    int? totalRecoveryMinutes,
    List<int>? recoveryDurations,
  }) {
    return FocusInput(
      platform: platform ?? this.platform,
      productiveMinutes: productiveMinutes ?? this.productiveMinutes,
      nonProductiveMinutes: nonProductiveMinutes ?? this.nonProductiveMinutes,
      appSwitchCount: appSwitchCount ?? this.appSwitchCount,
      totalScreenMinutes: totalScreenMinutes ?? this.totalScreenMinutes,
      breaksTaken: breaksTaken ?? this.breaksTaken,
      breaksExpected: breaksExpected ?? this.breaksExpected,
      longestFocusBlockMinutes:
          longestFocusBlockMinutes ?? this.longestFocusBlockMinutes,
      averageRecoveryMinutes:
          averageRecoveryMinutes ?? this.averageRecoveryMinutes,
      recoveryEventCount: recoveryEventCount ?? this.recoveryEventCount,
      totalRecoveryMinutes: totalRecoveryMinutes ?? this.totalRecoveryMinutes,
      recoveryDurations: recoveryDurations ?? this.recoveryDurations,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'platform': platform.name,
      'productiveMinutes': productiveMinutes,
      'nonProductiveMinutes': nonProductiveMinutes,
      'appSwitchCount': appSwitchCount,
      'totalScreenMinutes': totalScreenMinutes,
      'breaksTaken': breaksTaken,
      'breaksExpected': breaksExpected,
      'longestFocusBlockMinutes': longestFocusBlockMinutes,
      'averageRecoveryMinutes': averageRecoveryMinutes,
      'recoveryEventCount': recoveryEventCount,
      'totalRecoveryMinutes': totalRecoveryMinutes,
      'recoveryDurations': recoveryDurations,
    };
  }

  factory FocusInput.fromMap(Map<String, dynamic> map) {
    return FocusInput(
      platform: _parsePlatform(map['platform'] as String?),
      productiveMinutes: _readInt(map['productiveMinutes']),
      nonProductiveMinutes: _readInt(map['nonProductiveMinutes']),
      appSwitchCount: _readInt(map['appSwitchCount']),
      totalScreenMinutes: _readInt(map['totalScreenMinutes']),
      breaksTaken: _readInt(map['breaksTaken']),
      breaksExpected: _readInt(map['breaksExpected']),
      longestFocusBlockMinutes: _readInt(map['longestFocusBlockMinutes']),
      averageRecoveryMinutes: _readDouble(map['averageRecoveryMinutes']),
      recoveryEventCount: _readInt(map['recoveryEventCount']),
      totalRecoveryMinutes: _readInt(map['totalRecoveryMinutes']),
      recoveryDurations: _readIntList(map['recoveryDurations']),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory FocusInput.fromJson(Map<String, dynamic> json) =>
      FocusInput.fromMap(json);

  static DevicePlatform _parsePlatform(String? value) {
    return DevicePlatform.values.firstWhere(
      (platform) => platform.name == value,
      orElse: () => DevicePlatform.windows,
    );
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

  static List<int> _readIntList(dynamic value) {
    if (value is List<int>) return value;
    if (value is List) return value.map(_readInt).toList();
    return const [];
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FocusInput &&
            other.platform == platform &&
            other.productiveMinutes == productiveMinutes &&
            other.nonProductiveMinutes == nonProductiveMinutes &&
            other.appSwitchCount == appSwitchCount &&
            other.totalScreenMinutes == totalScreenMinutes &&
            other.breaksTaken == breaksTaken &&
            other.breaksExpected == breaksExpected &&
            other.longestFocusBlockMinutes == longestFocusBlockMinutes &&
            other.averageRecoveryMinutes == averageRecoveryMinutes &&
            other.recoveryEventCount == recoveryEventCount &&
            other.totalRecoveryMinutes == totalRecoveryMinutes &&
            _listEquals(other.recoveryDurations, recoveryDurations);
  }

  @override
  int get hashCode => Object.hash(
    platform,
    productiveMinutes,
    nonProductiveMinutes,
    appSwitchCount,
    totalScreenMinutes,
    breaksTaken,
    breaksExpected,
    longestFocusBlockMinutes,
    averageRecoveryMinutes,
    recoveryEventCount,
    totalRecoveryMinutes,
    Object.hashAll(recoveryDurations),
  );

  @override
  String toString() {
    return 'FocusInput(platform: $platform, productiveMinutes: $productiveMinutes, '
        'nonProductiveMinutes: $nonProductiveMinutes, appSwitchCount: $appSwitchCount, '
        'totalScreenMinutes: $totalScreenMinutes, breaksTaken: $breaksTaken, '
        'breaksExpected: $breaksExpected, longestFocusBlockMinutes: $longestFocusBlockMinutes, '
        'averageRecoveryMinutes: $averageRecoveryMinutes, recoveryEventCount: $recoveryEventCount, '
        'totalRecoveryMinutes: $totalRecoveryMinutes, recoveryDurations: $recoveryDurations)';
  }

  static bool _listEquals(List<int> first, List<int> second) {
    if (identical(first, second)) return true;
    if (first.length != second.length) return false;

    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }

    return true;
  }
}
