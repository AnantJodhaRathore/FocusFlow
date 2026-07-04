import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../analytics/focus_metrics.dart';
import '../services/activity_service.dart';
import '../services/settings_service.dart';
import 'firebase_privacy_guard.dart'; // Added privacy guard import
import 'firebase_sync_queue_service.dart'; // Added queue service import

enum FirebaseSyncStatus { idle, syncing, success, error }

class FirebaseDailySummarySyncResult {
  final FirebaseSyncStatus status;
  final String? uid;
  final String? documentPath;
  final String? message;

  const FirebaseDailySummarySyncResult({
    required this.status,
    this.uid,
    this.documentPath,
    this.message,
  });

  bool get isSuccess => status == FirebaseSyncStatus.success;
}

class FirebaseSyncService {
  FirebaseSyncService._internal();

  static final FirebaseSyncService instance = FirebaseSyncService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();
  final FirebaseSyncQueueService _queue =
      FirebaseSyncQueueService.instance; // Added queue field

  FirebaseSyncStatus _status = FirebaseSyncStatus.idle;
  DateTime? _lastSyncedAt;
  String? _lastError;

  FirebaseSyncStatus get status => _status;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError;

  Future<FirebaseDailySummarySyncResult> syncTodaySummary() {
    return syncDailySummary(DateTime.now());
  }

  Future<FirebaseDailySummarySyncResult> syncDailySummary(
    DateTime date, {
    bool enqueueOnFailure = true,
  }) async {
    if (_status == FirebaseSyncStatus.syncing) {
      return const FirebaseDailySummarySyncResult(
        status: FirebaseSyncStatus.syncing,
        message: 'Daily summary sync is already running.',
      );
    }

    _status = FirebaseSyncStatus.syncing;
    _lastError = null;

    try {
      final user = await _ensureSignedIn();
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final documentId = _dateDocumentId(normalizedDate);

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries')
          .doc(documentId);

      final summary = await _buildDailySummaryMap(
        date: normalizedDate,
        uid: user.uid,
      );

      final existingDoc = await docRef.get();

      final payload = <String, dynamic>{
        ...summary,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!existingDoc.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      // Validating payload before committing to Firestore
      FirebasePrivacyGuard.validateDailySummaryPayload(payload);

      await docRef.set(payload, SetOptions(merge: true));

      // Successfully written, safe to clear from queue
      await _queue.removeDailySummaryDate(normalizedDate);

      _lastSyncedAt = DateTime.now();
      _status = FirebaseSyncStatus.success;

      final path = 'users/${user.uid}/daily_summaries/$documentId';

      debugPrint('[FocusFlow] Daily summary synced: $path');

      return FirebaseDailySummarySyncResult(
        status: FirebaseSyncStatus.success,
        uid: user.uid,
        documentPath: path,
        message: 'Daily summary synced successfully.',
      );
    } catch (error, stackTrace) {
      _lastError = error.toString();
      _status = FirebaseSyncStatus.error;

      debugPrint('[FocusFlow] Daily summary sync error: $error');
      debugPrint('$stackTrace');

      if (enqueueOnFailure) {
        await _queue.addDailySummaryDate(date);
      }

      return FirebaseDailySummarySyncResult(
        status: FirebaseSyncStatus.error,
        message: _lastError,
      );
    }
  }

  /// Retries syncing all daily summaries currently waiting in the offline queue.
  Future<int> retryPendingDailySummaries() async {
    final pendingDates = await _queue.getPendingDailySummaryDates();

    if (pendingDates.isEmpty) {
      debugPrint('[FocusFlow] No pending daily summary syncs.');
      return 0;
    }

    debugPrint(
      '[FocusFlow] Retrying ${pendingDates.length} pending daily summary syncs.',
    );

    var successCount = 0;

    for (final date in pendingDates) {
      final result = await syncDailySummary(date, enqueueOnFailure: false);

      if (result.isSuccess) {
        successCount++;
      }
    }

    debugPrint(
      '[FocusFlow] Pending daily summary retry complete. Success: $successCount/${pendingDates.length}',
    );

    return successCount;
  }

  Future<User> _ensureSignedIn() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) return currentUser;

    final credential = await _auth.signInAnonymously();
    final user = credential.user;

    if (user == null) {
      throw StateError('Anonymous Firebase sign-in returned null user.');
    }

    return user;
  }

  Future<Map<String, dynamic>> _buildDailySummaryMap({
    required DateTime date,
    required String uid,
  }) async {
    final platform = SettingsService.platform.value;

    final activities = await _activityService.getActivitiesByDate(date);

    final focusInput = await _activityService.buildFocusInputForDate(
      date,
      cachedActivities: activities,
      platform: platform,
    );

    final focusResult = FocusMetrics.calculate(focusInput);
    final weeklyFocusTrend = await _activityService.getWeeklyFocusTrend(
      platform,
    );

    return {
      'schemaVersion': 1,
      'syncType': 'daily_summary_only',
      'uid': uid,
      'date': _dateDocumentId(date),
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

      'weeklyFocusTrend': weeklyFocusTrend,

      'privacy': {
        'rawActivityLogsSynced': false,
        'appNamesSynced': false,
        'windowTitlesSynced': false,
        'summaryOnly': true,
      },
    };
  }

  String _dateDocumentId(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
