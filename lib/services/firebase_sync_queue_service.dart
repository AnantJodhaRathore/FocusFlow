import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseSyncQueueService {
  FirebaseSyncQueueService._internal();

  static final FirebaseSyncQueueService instance =
      FirebaseSyncQueueService._internal();

  static const String _pendingDailySummaryDatesKey =
      'firebase_pending_daily_summary_dates';

  Future<List<DateTime>> getPendingDailySummaryDates() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_pendingDailySummaryDatesKey) ?? [];

    final dates = <DateTime>[];

    for (final value in values) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        dates.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }

    dates.sort((a, b) => a.compareTo(b));
    return dates;
  }

  Future<void> addDailySummaryDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_pendingDailySummaryDatesKey) ?? [];

    final dateId = _dateDocumentId(date);

    if (!current.contains(dateId)) {
      current.add(dateId);
      current.sort();

      await prefs.setStringList(_pendingDailySummaryDatesKey, current);

      debugPrint('[FocusFlow] Queued daily summary sync retry: $dateId');
    }
  }

  Future<void> removeDailySummaryDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_pendingDailySummaryDatesKey) ?? [];

    final dateId = _dateDocumentId(date);
    current.remove(dateId);

    await prefs.setStringList(_pendingDailySummaryDatesKey, current);

    debugPrint('[FocusFlow] Removed daily summary retry: $dateId');
  }

  Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_pendingDailySummaryDatesKey) ?? [];

    return current.length;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingDailySummaryDatesKey);
  }

  String _dateDocumentId(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
