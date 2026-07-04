import 'package:flutter/foundation.dart';

import '../services/activity_tracker_service.dart';
import '../services/dashboard_service.dart';
import '../services/storage_service.dart';

enum MonitoringStatus { stopped, starting, running, stopping, error }

class MonitoringService {
  MonitoringService._internal();

  static final MonitoringService instance = MonitoringService._internal();

  final ActivityTrackerService _activityTracker =
      ActivityTrackerService.instance;
  final StorageService _storage = StorageService();
  final DashboardService _dashboardService = DashboardService.instance;

  final ValueNotifier<MonitoringStatus> status =
      ValueNotifier<MonitoringStatus>(MonitoringStatus.stopped);

  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  bool get isRunning => status.value == MonitoringStatus.running;

  bool get isStarting => status.value == MonitoringStatus.starting;

  bool get isStopping => status.value == MonitoringStatus.stopping;

  Future<void> start() async {
    if (isRunning || isStarting) return;

    status.value = MonitoringStatus.starting;
    lastError.value = null;

    try {
      await _storage.initialize();
      await _activityTracker.start();
      await _dashboardService.warmUp();

      status.value = MonitoringStatus.running;
    } catch (error) {
      lastError.value = error.toString();
      status.value = MonitoringStatus.error;
      debugPrint('[MonitoringService] Failed to start monitoring: $error');
    }
  }

  Future<void> stop() async {
    if (status.value == MonitoringStatus.stopped || isStopping) return;

    status.value = MonitoringStatus.stopping;

    try {
      await _activityTracker.stop();
      _dashboardService.clearCache();

      status.value = MonitoringStatus.stopped;
    } catch (error) {
      lastError.value = error.toString();
      status.value = MonitoringStatus.error;
      debugPrint('[MonitoringService] Failed to stop monitoring: $error');
    }
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  Future<void> flush() async {
    if (!isRunning) return;

    try {
      await _activityTracker.flush();
      _dashboardService.clearCache();
    } catch (error) {
      lastError.value = error.toString();
      debugPrint('[MonitoringService] Failed to flush monitoring data: $error');
    }
  }

  void clearError() {
    lastError.value = null;

    if (status.value == MonitoringStatus.error) {
      status.value = MonitoringStatus.stopped;
    }
  }

  void dispose() {
    status.dispose();
    lastError.dispose();
  }
}
