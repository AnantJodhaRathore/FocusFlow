import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow/analytics/focus_score_engine.dart';
import 'package:focusflow/models/focus_input.dart';

void main() {
  test('recovery score maps average recovery to 0-100 scale (Windows)', () {
    final inputFast = FocusInput(
      platform: DevicePlatform.windows,
      productiveMinutes: 120,
      nonProductiveMinutes: 30,
      totalScreenMinutes: 150,
      appSwitchCount: 5,
      breaksTaken: 3,
      breaksExpected: 7,
      longestFocusBlockMinutes: 60,
      averageRecoveryMinutes: 3.0,
      recoveryEventCount: 2,
    );

    final resFast = FocusScoreEngine.calculate(inputFast);
    expect(resFast.recoveryScore, 100);

    final inputSlow = FocusInput(
      platform: DevicePlatform.windows,
      productiveMinutes: 80,
      nonProductiveMinutes: 60,
      totalScreenMinutes: 140,
      appSwitchCount: 20,
      breaksTaken: 2,
      breaksExpected: 7,
      longestFocusBlockMinutes: 20,
      averageRecoveryMinutes: 40.0,
      recoveryEventCount: 3,
    );

    final resSlow = FocusScoreEngine.calculate(inputSlow);
    expect(resSlow.recoveryScore, 0);
  });
}
