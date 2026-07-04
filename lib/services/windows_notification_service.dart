import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_service.dart';

class WindowsNotificationService implements NotificationBridge {
  WindowsNotificationService._internal();

  static final WindowsNotificationService instance =
      WindowsNotificationService._internal();

  static const MethodChannel _channel = MethodChannel(
    'focusflow/windows_notifications',
  );

  bool _isInitialized = false;
  bool _nativeBridgeAvailable = true;

  bool get isSupported => Platform.isWindows;

  bool get isInitialized => _isInitialized;

  bool get nativeBridgeAvailable => _nativeBridgeAvailable;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!isSupported) {
      _isInitialized = true;
      return;
    }

    try {
      await _channel.invokeMethod<void>('initialize', {'appName': 'FocusFlow'});

      _nativeBridgeAvailable = true;
      debugPrint('[WindowsNotificationService] Initialized');
    } on MissingPluginException {
      _nativeBridgeAvailable = false;
      debugPrint(
        '[WindowsNotificationService] Native notification bridge not registered. Using debug fallback.',
      );
    } on PlatformException catch (error) {
      _nativeBridgeAvailable = false;
      debugPrint(
        '[WindowsNotificationService] Initialize failed: ${error.message}',
      );
    } catch (error, stackTrace) {
      _nativeBridgeAvailable = false;
      debugPrint('[WindowsNotificationService] Initialize error: $error');
      debugPrint('$stackTrace');
    }

    _isInitialized = true;
  }

  @override
  Future<void> show(FocusNotification notification) async {
    await initialize();

    if (!isSupported || !_nativeBridgeAvailable) {
      _logFallback(notification);
      return;
    }

    try {
      await _channel.invokeMethod<void>('show', {
        'id': notification.id,
        'title': notification.title,
        'message': notification.message,
        'type': notification.type.name,
        'createdAt': notification.createdAt.toIso8601String(),
        'payload': notification.payload,
      });
    } on MissingPluginException {
      _nativeBridgeAvailable = false;
      _logFallback(notification);
    } on PlatformException catch (error) {
      debugPrint('[WindowsNotificationService] Show failed: ${error.message}');
      _logFallback(notification);
    } catch (error, stackTrace) {
      debugPrint('[WindowsNotificationService] Show error: $error');
      debugPrint('$stackTrace');
      _logFallback(notification);
    }
  }

  @override
  Future<void> cancelAll() async {
    await initialize();

    if (!isSupported || !_nativeBridgeAvailable) return;

    try {
      await _channel.invokeMethod<void>('cancelAll');
    } on MissingPluginException {
      _nativeBridgeAvailable = false;
    } on PlatformException catch (error) {
      debugPrint(
        '[WindowsNotificationService] Cancel all failed: ${error.message}',
      );
    } catch (error, stackTrace) {
      debugPrint('[WindowsNotificationService] Cancel all error: $error');
      debugPrint('$stackTrace');
    }
  }

  @override
  Future<void> dispose() async {
    if (isSupported && _nativeBridgeAvailable) {
      try {
        await _channel.invokeMethod<void>('dispose');
      } on MissingPluginException {
        _nativeBridgeAvailable = false;
      } on PlatformException catch (error) {
        debugPrint(
          '[WindowsNotificationService] Dispose failed: ${error.message}',
        );
      } catch (error, stackTrace) {
        debugPrint('[WindowsNotificationService] Dispose error: $error');
        debugPrint('$stackTrace');
      }
    }

    _isInitialized = false;
  }

  Future<void> registerWithNotificationService() async {
    await NotificationService.instance.initialize(bridge: this);
  }

  void _logFallback(FocusNotification notification) {
    debugPrint(
      '[WindowsNotificationService] ${notification.title}: ${notification.message}',
    );
  }
}
