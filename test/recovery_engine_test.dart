import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow/analytics/recovery_engine.dart';
import 'package:focusflow/models/activity_record.dart';

void main() {
  test('computeRecoveryDurations detects single distraction', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final acts = [
      ActivityRecord(
        appName: 'VS Code',
        category: 'Work',
        durationMinutes: 45,
        startTime: today.add(const Duration(hours: 9)),
      ),
      ActivityRecord(
        appName: 'YouTube',
        category: 'Entertainment',
        durationMinutes: 15,
        startTime: today.add(const Duration(hours: 9, minutes: 45)),
      ),
      ActivityRecord(
        appName: 'VS Code',
        category: 'Work',
        durationMinutes: 60,
        startTime: today.add(const Duration(hours: 10)),
      ),
    ];

    final durations = RecoveryEngine.computeRecoveryDurations(acts);
    expect(durations.length, 1);
    expect(durations.first, 15);
    expect(RecoveryEngine.averageRecoveryMinutes(acts), 15.0);
    expect(RecoveryEngine.totalRecoveryMinutes(acts), 15);
    expect(RecoveryEngine.recoveryEventCount(acts), 1);
  });

  test('ignore trailing distraction without resume', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final acts = [
      ActivityRecord(
        appName: 'VS Code',
        category: 'Work',
        durationMinutes: 30,
        startTime: today.add(const Duration(hours: 9)),
      ),
      ActivityRecord(
        appName: 'YouTube',
        category: 'Entertainment',
        durationMinutes: 20,
        startTime: today.add(const Duration(hours: 9, minutes: 30)),
      ),
      // no productive resume after this
    ];

    final durations = RecoveryEngine.computeRecoveryDurations(acts);
    expect(durations.isEmpty, true);
    expect(RecoveryEngine.averageRecoveryMinutes(acts), 0.0);
    expect(RecoveryEngine.totalRecoveryMinutes(acts), 0);
    expect(RecoveryEngine.recoveryEventCount(acts), 0);
  });
}
