import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/monitoring_service.dart';

class AppLifecycleService extends WidgetsBindingObserver {
  AppLifecycleService._internal();

  static final AppLifecycleService instance = AppLifecycleService._internal();

  final MonitoringService _monitoringService = MonitoringService.instance;

  bool _isObserving = false;
  bool _isFlushing = false;
  DateTime? _lastFlushAt;

  static const Duration _minimumFlushGap = Duration(seconds: 5);

  bool get isObserving => _isObserving;

  Future<void> initialize({bool startMonitoring = true}) async {
    if (!_isObserving) {
      WidgetsBinding.instance.addObserver(this);
      _isObserving = true;
    }

    if (startMonitoring) {
      await _monitoringService.start();
    }
  }

  Future<void> shutdown({bool stopMonitoring = true}) async {
    await flush();

    if (stopMonitoring) {
      await _monitoringService.stop();
    }

    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }
  }

  Future<void> flush() async {
    if (_isFlushing) return;

    final now = DateTime.now();
    final lastFlushAt = _lastFlushAt;

    if (lastFlushAt != null && now.difference(lastFlushAt) < _minimumFlushGap) {
      return;
    }

    _isFlushing = true;

    try {
      await _monitoringService.flush();
      _lastFlushAt = DateTime.now();
    } finally {
      _isFlushing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(flush());
      return;
    }

    if (state == AppLifecycleState.detached) {
      unawaited(shutdown());
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_monitoringService.start());
    }
  }
}
