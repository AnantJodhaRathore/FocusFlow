import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../analytics/focus_metrics.dart';
import 'activity_service.dart';
import 'settings_service.dart';

class DailySummaryExportResult {
  final bool success;
  final String? filePath;
  final String? message;

  const DailySummaryExportResult({
    required this.success,
    this.filePath,
    this.message,
  });
}

class DailySummaryExportService {
  DailySummaryExportService._internal();

  static final DailySummaryExportService instance =
      DailySummaryExportService._internal();

  final ActivityService _activityService = ActivityService();

  Future<DailySummaryExportResult> exportLast7Days() async {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 6));

    return exportDailySummaries(startDate: startDate, endDate: today);
  }

  Future<DailySummaryExportResult> exportToday() async {
    final today = DateTime.now();

    return exportDailySummaries(startDate: today, endDate: today);
  }

  Future<DailySummaryExportResult> exportDailySummaries({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final normalizedStart = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

      final platform = SettingsService.platform.value;
      final summaries = <Map<String, dynamic>>[];

      var currentDate = normalizedStart;

      while (!currentDate.isAfter(normalizedEnd)) {
        final activities = await _activityService.getActivitiesByDate(
          currentDate,
        );

        final focusInput = await _activityService.buildFocusInputForDate(
          currentDate,
          cachedActivities: activities,
          platform: platform,
        );

        final focusResult = FocusMetrics.calculate(focusInput);

        summaries.add({
          'date': _dateId(currentDate),
          'platform': platform.name,
          'scores': {
            'focusScore': focusResult.focusScore,
            'focusLabel': focusResult.label,
            'focusLevel': focusResult.level.name,
            'productiveTimeScore': focusResult.productiveTimeScore,
            'distractionScore': focusResult.distractionScore,
            'recoveryScore': focusResult.recoveryScore,
            'breakComplianceScore': focusResult.breakComplianceScore,
            'screenTimeScore': focusResult.screenTimeScore,
            'deepWorkScore': focusResult.deepWorkScore,
          },
          'minutes': {
            'totalScreenMinutes': focusInput.totalScreenMinutes,
            'productiveMinutes': focusInput.productiveMinutes,
            'nonProductiveMinutes': focusInput.nonProductiveMinutes,
            'totalRecoveryMinutes': focusInput.totalRecoveryMinutes,
            'longestFocusBlockMinutes': focusInput.longestFocusBlockMinutes,
          },
          'activitySummary': {
            'activityCount': activities.length,
            'appSwitchCount': focusInput.appSwitchCount,
            'breaksTaken': focusInput.breaksTaken,
            'breaksExpected': focusInput.breaksExpected,
            'recoveryEventCount': focusInput.recoveryEventCount,
            'averageRecoveryMinutes': focusInput.averageRecoveryMinutes,
          },
          'privacy': {
            'summaryOnly': true,
            'rawActivityLogsExported': false,
            'appNamesExported': false,
            'windowTitlesExported': false,
          },
        });

        currentDate = currentDate.add(const Duration(days: 1));
      }

      final exportPayload = {
        'app': 'FocusFlow',
        'schemaVersion': 1,
        'exportType': 'daily_summary_only',
        'exportedAt': DateTime.now().toIso8601String(),
        'range': {
          'startDate': _dateId(normalizedStart),
          'endDate': _dateId(normalizedEnd),
        },
        'privacy': {
          'rawActivityLogsExported': false,
          'appNamesExported': false,
          'windowTitlesExported': false,
          'summaryOnly': true,
        },
        'dailySummaries': summaries,
      };

      final filePath = await _writeJsonFile(exportPayload);

      debugPrint('[FocusFlow] Daily summaries exported: $filePath');

      return DailySummaryExportResult(
        success: true,
        filePath: filePath,
        message: 'Daily summaries exported successfully.',
      );
    } catch (error, stackTrace) {
      debugPrint('[FocusFlow] Daily summary export error: $error');
      debugPrint('$stackTrace');

      return DailySummaryExportResult(
        success: false,
        message: error.toString(),
      );
    }
  }

  Future<String> _writeJsonFile(Map<String, dynamic> payload) async {
    final exportDirectory = await _getExportDirectory();

    if (!exportDirectory.existsSync()) {
      exportDirectory.createSync(recursive: true);
    }

    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}focusflow_daily_summaries_$timestamp.json',
    );

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload));

    return file.path;
  }

  Future<Directory> _getExportDirectory() async {
    final userProfile = Platform.environment['USERPROFILE'];

    if (userProfile != null && userProfile.trim().isNotEmpty) {
      return Directory(
        '$userProfile${Platform.pathSeparator}Documents${Platform.pathSeparator}FocusFlow${Platform.pathSeparator}exports',
      );
    }

    return Directory(
      '${Directory.current.path}${Platform.pathSeparator}focusflow_exports',
    );
  }

  String _dateId(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
