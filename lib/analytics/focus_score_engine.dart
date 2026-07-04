import 'dart:math' as math;

import '../models/focus_input.dart';
import '../models/focus_score_result.dart';

class _Thresholds {
  final int switchesForPerfect;
  final int switchesForZero;
  final int screenPerfectMinutes;
  final int screenZeroMinutes;
  final int deepWorkPerfectMinutes;
  final int recoveryPerfectMinutes;
  final int recoveryZeroMinutes;

  const _Thresholds({
    required this.switchesForPerfect,
    required this.switchesForZero,
    required this.screenPerfectMinutes,
    required this.screenZeroMinutes,
    required this.deepWorkPerfectMinutes,
    required this.recoveryPerfectMinutes,
    required this.recoveryZeroMinutes,
  });

  static const windows = _Thresholds(
    switchesForPerfect: 5,
    switchesForZero: 40,
    screenPerfectMinutes: 360,
    screenZeroMinutes: 600,
    deepWorkPerfectMinutes: 90,
    recoveryPerfectMinutes: 5,
    recoveryZeroMinutes: 30,
  );

  static const android = _Thresholds(
    switchesForPerfect: 10,
    switchesForZero: 60,
    screenPerfectMinutes: 180,
    screenZeroMinutes: 420,
    deepWorkPerfectMinutes: 45,
    recoveryPerfectMinutes: 3,
    recoveryZeroMinutes: 20,
  );

  static const tablet = _Thresholds(
    switchesForPerfect: 8,
    switchesForZero: 50,
    screenPerfectMinutes: 240,
    screenZeroMinutes: 480,
    deepWorkPerfectMinutes: 60,
    recoveryPerfectMinutes: 4,
    recoveryZeroMinutes: 25,
  );

  static const web = _Thresholds(
    switchesForPerfect: 8,
    switchesForZero: 45,
    screenPerfectMinutes: 300,
    screenZeroMinutes: 540,
    deepWorkPerfectMinutes: 75,
    recoveryPerfectMinutes: 5,
    recoveryZeroMinutes: 30,
  );

  static _Thresholds forPlatform(DevicePlatform platform) {
    return switch (platform) {
      DevicePlatform.windows => windows,
      DevicePlatform.android => android,
      DevicePlatform.tablet => tablet,
      DevicePlatform.web => web,
    };
  }
}

class FocusScoreEngine {
  FocusScoreEngine._();

  static const double productiveWeight = 0.25;
  static const double distractionWeight = 0.25;
  static const double breakComplianceWeight = 0.20;
  static const double screenTimeWeight = 0.15;
  static const double deepWorkWeight = 0.15;

  static FocusScoreResult calculate(FocusInput input) {
    final thresholds = _Thresholds.forPlatform(input.platform);

    final productive = _productiveTimeScore(input);
    final distraction = _distractionScore(input, thresholds);
    final breakCompliance = _breakComplianceScore(input);
    final screenTime = _screenTimeScore(input, thresholds);
    final deepWork = _deepWorkScore(input, thresholds);
    final recovery = _recoveryScore(input, thresholds);

    final composite = _weightedAverage(
      productive: productive,
      distraction: distraction,
      breakCompliance: breakCompliance,
      screenTime: screenTime,
      deepWork: deepWork,
    );

    return FocusScoreResult.fromScore(
      focusScore: composite,
      productiveTimeScore: productive,
      distractionScore: distraction,
      recoveryScore: recovery,
      breakComplianceScore: breakCompliance,
      screenTimeScore: screenTime,
      deepWorkScore: deepWork,
      platform: input.platform,
    );
  }

  static int _productiveTimeScore(FocusInput input) {
    if (input.totalScreenMinutes <= 0) return 0;

    final ratio = input.productiveMinutes / input.totalScreenMinutes;
    return _scoreFromRatio(ratio);
  }

  static int _distractionScore(FocusInput input, _Thresholds thresholds) {
    final switches = input.appSwitchCount;

    if (switches <= thresholds.switchesForPerfect) return 100;
    if (switches >= thresholds.switchesForZero) return 0;

    return _linearDecayScore(
      value: switches,
      perfectAt: thresholds.switchesForPerfect,
      zeroAt: thresholds.switchesForZero,
    );
  }

  static int _breakComplianceScore(FocusInput input) {
    if (input.breaksExpected <= 0) return 100;

    final ratio = input.breaksTaken / input.breaksExpected;
    return _scoreFromRatio(math.min(ratio, 1.0));
  }

  static int _screenTimeScore(FocusInput input, _Thresholds thresholds) {
    final minutes = input.totalScreenMinutes;

    if (minutes <= thresholds.screenPerfectMinutes) return 100;
    if (minutes >= thresholds.screenZeroMinutes) return 0;

    return _linearDecayScore(
      value: minutes,
      perfectAt: thresholds.screenPerfectMinutes,
      zeroAt: thresholds.screenZeroMinutes,
    );
  }

  static int _deepWorkScore(FocusInput input, _Thresholds thresholds) {
    if (input.longestFocusBlockMinutes <= 0) return 0;

    final ratio =
        input.longestFocusBlockMinutes / thresholds.deepWorkPerfectMinutes;

    return _scoreFromRatio(math.min(ratio, 1.0));
  }

  static int _recoveryScore(FocusInput input, _Thresholds thresholds) {
    if (input.recoveryEventCount <= 0) return 100;

    final average = input.averageRecoveryMinutes;

    if (average <= thresholds.recoveryPerfectMinutes) return 100;
    if (average >= thresholds.recoveryZeroMinutes) return 0;

    return _linearDecayScore(
      value: average,
      perfectAt: thresholds.recoveryPerfectMinutes,
      zeroAt: thresholds.recoveryZeroMinutes,
    );
  }

  static int _weightedAverage({
    required int productive,
    required int distraction,
    required int breakCompliance,
    required int screenTime,
    required int deepWork,
  }) {
    final score =
        (productive * productiveWeight) +
        (distraction * distractionWeight) +
        (breakCompliance * breakComplianceWeight) +
        (screenTime * screenTimeWeight) +
        (deepWork * deepWorkWeight);

    return FocusScoreResult.clampScore(score);
  }

  static int _scoreFromRatio(double ratio) {
    return FocusScoreResult.clampScore(ratio.clamp(0.0, 1.0) * 100);
  }

  static int _linearDecayScore({
    required num value,
    required num perfectAt,
    required num zeroAt,
  }) {
    final range = zeroAt - perfectAt;
    if (range <= 0) return 0;

    final excess = value - perfectAt;
    final score = 100 - ((excess / range) * 100);

    return FocusScoreResult.clampScore(score);
  }
}
