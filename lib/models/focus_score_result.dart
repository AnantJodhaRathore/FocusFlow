import 'package:flutter/material.dart';

import 'focus_input.dart';

enum FocusLevel { excellent, good, moderate, low }

class FocusScoreResult {
  final int focusScore;
  final int productiveTimeScore;
  final int distractionScore;
  final int recoveryScore;
  final int breakComplianceScore;
  final int screenTimeScore;
  final int deepWorkScore;
  final DevicePlatform platform;
  final String label;
  final FocusLevel level;

  const FocusScoreResult({
    required this.focusScore,
    required this.productiveTimeScore,
    required this.distractionScore,
    required this.recoveryScore,
    required this.breakComplianceScore,
    required this.screenTimeScore,
    required this.deepWorkScore,
    required this.platform,
    required this.label,
    required this.level,
  }) : assert(focusScore >= 0 && focusScore <= 100),
       assert(productiveTimeScore >= 0 && productiveTimeScore <= 100),
       assert(distractionScore >= 0 && distractionScore <= 100),
       assert(recoveryScore >= 0 && recoveryScore <= 100),
       assert(breakComplianceScore >= 0 && breakComplianceScore <= 100),
       assert(screenTimeScore >= 0 && screenTimeScore <= 100),
       assert(deepWorkScore >= 0 && deepWorkScore <= 100);

  factory FocusScoreResult.empty({
    DevicePlatform platform = DevicePlatform.windows,
  }) {
    return FocusScoreResult(
      focusScore: 0,
      productiveTimeScore: 0,
      distractionScore: 0,
      recoveryScore: 0,
      breakComplianceScore: 0,
      screenTimeScore: 0,
      deepWorkScore: 0,
      platform: platform,
      label: 'No Data',
      level: FocusLevel.low,
    );
  }

  factory FocusScoreResult.fromScore({
    required int focusScore,
    required int productiveTimeScore,
    required int distractionScore,
    required int recoveryScore,
    required int breakComplianceScore,
    required int screenTimeScore,
    required int deepWorkScore,
    required DevicePlatform platform,
  }) {
    final safeScore = clampScore(focusScore);
    final level = levelForScore(safeScore);

    return FocusScoreResult(
      focusScore: safeScore,
      productiveTimeScore: clampScore(productiveTimeScore),
      distractionScore: clampScore(distractionScore),
      recoveryScore: clampScore(recoveryScore),
      breakComplianceScore: clampScore(breakComplianceScore),
      screenTimeScore: clampScore(screenTimeScore),
      deepWorkScore: clampScore(deepWorkScore),
      platform: platform,
      label: labelForLevel(level),
      level: level,
    );
  }

  bool get hasData => focusScore > 0;

  bool get isHealthy => focusScore >= 70;

  bool get needsAttention => focusScore < 50;

  Map<String, dynamic> toMap() {
    return {
      'focusScore': focusScore,
      'productiveTimeScore': productiveTimeScore,
      'distractionScore': distractionScore,
      'recoveryScore': recoveryScore,
      'breakComplianceScore': breakComplianceScore,
      'screenTimeScore': screenTimeScore,
      'deepWorkScore': deepWorkScore,
      'platform': platform.name,
      'label': label,
      'level': level.name,
    };
  }

  factory FocusScoreResult.fromMap(Map<String, dynamic> map) {
    return FocusScoreResult(
      focusScore: clampScore(_readInt(map['focusScore'])),
      productiveTimeScore: clampScore(_readInt(map['productiveTimeScore'])),
      distractionScore: clampScore(_readInt(map['distractionScore'])),
      recoveryScore: clampScore(_readInt(map['recoveryScore'])),
      breakComplianceScore: clampScore(_readInt(map['breakComplianceScore'])),
      screenTimeScore: clampScore(_readInt(map['screenTimeScore'])),
      deepWorkScore: clampScore(_readInt(map['deepWorkScore'])),
      platform: _parsePlatform(map['platform'] as String?),
      label: (map['label'] as String?) ?? 'Unknown',
      level: _parseLevel(map['level'] as String?),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory FocusScoreResult.fromJson(Map<String, dynamic> json) {
    return FocusScoreResult.fromMap(json);
  }

  FocusScoreResult copyWith({
    int? focusScore,
    int? productiveTimeScore,
    int? distractionScore,
    int? recoveryScore,
    int? breakComplianceScore,
    int? screenTimeScore,
    int? deepWorkScore,
    DevicePlatform? platform,
    String? label,
    FocusLevel? level,
  }) {
    final nextScore = clampScore(focusScore ?? this.focusScore);
    final nextLevel = level ?? this.level;

    return FocusScoreResult(
      focusScore: nextScore,
      productiveTimeScore: clampScore(
        productiveTimeScore ?? this.productiveTimeScore,
      ),
      distractionScore: clampScore(distractionScore ?? this.distractionScore),
      recoveryScore: clampScore(recoveryScore ?? this.recoveryScore),
      breakComplianceScore: clampScore(
        breakComplianceScore ?? this.breakComplianceScore,
      ),
      screenTimeScore: clampScore(screenTimeScore ?? this.screenTimeScore),
      deepWorkScore: clampScore(deepWorkScore ?? this.deepWorkScore),
      platform: platform ?? this.platform,
      label: label ?? this.label,
      level: nextLevel,
    );
  }

  static int clampScore(num value) {
    return value.round().clamp(0, 100);
  }

  static FocusLevel levelForScore(int score) {
    if (score >= 85) return FocusLevel.excellent;
    if (score >= 70) return FocusLevel.good;
    if (score >= 50) return FocusLevel.moderate;
    return FocusLevel.low;
  }

  static String labelForLevel(FocusLevel level) {
    return switch (level) {
      FocusLevel.excellent => 'Excellent',
      FocusLevel.good => 'Good',
      FocusLevel.moderate => 'Moderate',
      FocusLevel.low => 'Low',
    };
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DevicePlatform _parsePlatform(String? value) {
    return DevicePlatform.values.firstWhere(
      (platform) => platform.name == value,
      orElse: () => DevicePlatform.windows,
    );
  }

  static FocusLevel _parseLevel(String? value) {
    return FocusLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => FocusLevel.low,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FocusScoreResult &&
            other.focusScore == focusScore &&
            other.productiveTimeScore == productiveTimeScore &&
            other.distractionScore == distractionScore &&
            other.recoveryScore == recoveryScore &&
            other.breakComplianceScore == breakComplianceScore &&
            other.screenTimeScore == screenTimeScore &&
            other.deepWorkScore == deepWorkScore &&
            other.platform == platform &&
            other.label == label &&
            other.level == level;
  }

  @override
  int get hashCode => Object.hash(
    focusScore,
    productiveTimeScore,
    distractionScore,
    recoveryScore,
    breakComplianceScore,
    screenTimeScore,
    deepWorkScore,
    platform,
    label,
    level,
  );

  @override
  String toString() {
    return 'FocusScoreResult($label: $focusScore%, level: ${level.name})';
  }
}

extension FocusLevelExtension on FocusLevel {
  Color get color {
    return switch (this) {
      FocusLevel.excellent => const Color(0xFF2ECC71),
      FocusLevel.good => const Color(0xFF3498DB),
      FocusLevel.moderate => const Color(0xFFF39C12),
      FocusLevel.low => const Color(0xFFE74C3C),
    };
  }

  Color themeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return switch (this) {
      FocusLevel.excellent => colorScheme.primary,
      FocusLevel.good => colorScheme.secondary,
      FocusLevel.moderate => colorScheme.tertiary,
      FocusLevel.low => colorScheme.error,
    };
  }

  String get label => FocusScoreResult.labelForLevel(this);
}
