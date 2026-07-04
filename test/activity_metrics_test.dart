import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow/analytics/activity_metrics.dart';
import 'package:focusflow/models/activity_record.dart';

void main() {
  test('countSwitches counts consecutive app changes', () {
    final acts = [
      ActivityRecord(
        appName: 'VS Code',
        category: 'Work',
        durationMinutes: 30,
        startTime: DateTime.now(),
      ),
      ActivityRecord(
        appName: 'Chrome',
        category: 'Research',
        durationMinutes: 10,
        startTime: DateTime.now(),
      ),
      ActivityRecord(
        appName: 'VS Code',
        category: 'Work',
        durationMinutes: 20,
        startTime: DateTime.now(),
      ),
      ActivityRecord(
        appName: 'Word',
        category: 'Work',
        durationMinutes: 15,
        startTime: DateTime.now(),
      ),
    ];

    final switches = ActivityMetrics.countSwitches(acts);
    expect(switches, 3);
    // also verify new API name
    expect(ActivityMetrics.countAppSwitches(acts), 3);
  });

  test('countSwitches returns 0 for empty or single-record lists', () {
    expect(ActivityMetrics.countSwitches([]), 0);
    final one = [
      ActivityRecord(
        appName: 'VS Code',
        category: 'Work',
        durationMinutes: 30,
        startTime: DateTime.now(),
      ),
    ];
    expect(ActivityMetrics.countSwitches(one), 0);
  });
}
