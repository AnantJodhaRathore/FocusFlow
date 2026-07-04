import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../analytics/app_classifier.dart';
import '../models/activity_record.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/windows_monitor_service.dart';

class ActivityTrackerService {
  ActivityTrackerService._internal();

  static final ActivityTrackerService instance =
      ActivityTrackerService._internal();

  final WindowsMonitorService _monitor = WindowsMonitorService();
  final StorageService _storage = StorageService();

  final ValueNotifier<int> activityVersion = ValueNotifier<int>(0);

  StreamSubscription<ActiveWindow>? _subscription;
  ActiveWindow? _lastWindow;
  Future<void> _saveQueue = Future.value();
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) return;

    await _storage.initialize();

    _isRunning = true;
    _monitor.start();

    _subscription = _monitor.stream.listen(
      _handleWindowEvent,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[ActivityTrackerService] Monitor stream error: $error');
      },
    );
  }

  Future<void> stop() async {
    if (!_isRunning) return;

    _isRunning = false;

    await _subscription?.cancel();
    _subscription = null;

    _monitor.stop();

    final finalWindow = _lastWindow;
    _lastWindow = null;

    if (finalWindow != null) {
      await _saveWindowSegment(window: finalWindow, endTime: DateTime.now());
    }
  }

  Future<void> flush() async {
    final currentWindow = _lastWindow;
    if (currentWindow == null) return;

    final now = DateTime.now();

    await _saveWindowSegment(window: currentWindow, endTime: now);

    _lastWindow = ActiveWindow(
      app: currentWindow.app,
      timestamp: now,
      isIdle: currentWindow.isIdle,
      title: '',
    );
  }

  void _handleWindowEvent(ActiveWindow currentWindow) {
    final previousWindow = _lastWindow;

    if (previousWindow != null &&
        previousWindow.app == currentWindow.app &&
        previousWindow.isIdle == currentWindow.isIdle) {
      return;
    }

    _lastWindow = currentWindow;

    if (previousWindow == null) return;

    unawaited(
      _saveWindowSegment(
        window: previousWindow,
        endTime: currentWindow.timestamp,
      ),
    );
  }

  Future<void> _saveWindowSegment({
    required ActiveWindow window,
    required DateTime endTime,
  }) async {
    final duration = endTime.difference(window.timestamp);
    if (duration.inSeconds <= 0) return;

    _saveQueue = _saveQueue.then((_) async {
      try {
        final record = ActivityRecord(
          appName: _appNameFor(window),
          category: _categoryFor(window),
          durationMinutes: _durationToStoredMinutes(duration),
          startTime: window.timestamp,
        );

        await _storage.insertActivity(record);
        activityVersion.value++;
      } catch (error) {
        debugPrint('[ActivityTrackerService] Failed to save activity: $error');
      }
    });

    await _saveQueue;
  }

  String _appNameFor(ActiveWindow window) {
    if (window.isIdle) return 'Idle Time';

    final app = window.app.trim();
    return app.isEmpty ? 'Unknown App' : app;
  }

  String _categoryFor(ActiveWindow window) {
    if (window.isIdle) return 'break';

    // Updated to use the cleaner categoryName helper for analytics
    return AppClassifier.categoryName(
      window.app,
      SettingsService.platform.value,
    );
  }

  int _durationToStoredMinutes(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds <= 0) return 0;

    return math.max(1, (seconds / 60).round());
  }
}
