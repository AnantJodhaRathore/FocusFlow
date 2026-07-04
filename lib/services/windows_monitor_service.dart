import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

class ActiveWindow {
  final String app;
  final String title;
  final DateTime timestamp;
  final bool isIdle;

  const ActiveWindow({
    required this.app,
    this.title = '',
    required this.timestamp,
    this.isIdle = false,
  });

  ActiveWindow copyWith({
    String? app,
    String? title,
    DateTime? timestamp,
    bool? isIdle,
  }) {
    return ActiveWindow(
      app: app ?? this.app,
      title: title ?? this.title,
      timestamp: timestamp ?? this.timestamp,
      isIdle: isIdle ?? this.isIdle,
    );
  }

  @override
  String toString() {
    return 'ActiveWindow(app: $app, title: $title, timestamp: $timestamp, isIdle: $isIdle)';
  }
}

class WindowsMonitorService {
  final Duration pollInterval;
  final Duration idleThreshold;

  Timer? _timer;
  String? _lastApp;
  String? _lastTitle;
  bool _isCurrentlyIdle = false;
  bool _isRunning = false;
  bool _isDisposed = false;

  final StreamController<ActiveWindow> _controller =
      StreamController<ActiveWindow>.broadcast();

  WindowsMonitorService({
    this.pollInterval = const Duration(seconds: 2),
    this.idleThreshold = const Duration(minutes: 3),
  });

  Stream<ActiveWindow> get stream => _controller.stream;

  bool get isRunning => _isRunning;

  void start() {
    if (_isDisposed || _isRunning) return;

    if (!Platform.isWindows) {
      debugPrint(
        '[WindowsMonitorService] Active-window tracking is Windows only.',
      );
      return;
    }

    _resetState();
    _isRunning = true;

    _poll();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void dispose() {
    if (_isDisposed) return;

    stop();
    _controller.close();
    _isDisposed = true;
  }

  void _resetState() {
    _lastApp = null;
    _lastTitle = null;
    _isCurrentlyIdle = false;
  }

  void _poll() {
    if (_isDisposed || !Platform.isWindows) return;

    try {
      if (_emitIdleStateIfNeeded()) return;

      final hwnd = GetForegroundWindow();
      if (hwnd == 0) return;

      final title = _readWindowTitle(hwnd);
      if (title.isEmpty) return;

      final processPath = _readProcessPath(hwnd);
      if (processPath.isEmpty) return;

      final app = normalizeApp(processPath.split(RegExp(r'[\\/]')).last);

      if (app != _lastApp || title != _lastTitle || _isCurrentlyIdle) {
        _isCurrentlyIdle = false;
        _lastApp = app;
        _lastTitle = title;

        _emit(
          ActiveWindow(
            app: app,
            title: title,
            timestamp: DateTime.now(),
            isIdle: false,
          ),
        );
      }
    } catch (error) {
      debugPrint('[WindowsMonitorService] Poll failed: $error');
    }
  }

  bool _emitIdleStateIfNeeded() {
    final idleDuration = _readIdleDuration();
    if (idleDuration == null || idleDuration < idleThreshold) {
      return false;
    }

    if (_isCurrentlyIdle) return true;

    _isCurrentlyIdle = true;
    _lastApp = 'Idle Time';
    _lastTitle = 'System Idle';

    _emit(
      ActiveWindow(
        app: 'Idle Time',
        title: 'System Idle > ${idleThreshold.inMinutes} Minutes',
        timestamp: DateTime.now(),
        isIdle: true,
      ),
    );

    return true;
  }

  Duration? _readIdleDuration() {
    final lastInputInfo = calloc<LASTINPUTINFO>();

    try {
      lastInputInfo.ref.cbSize = ffi.sizeOf<LASTINPUTINFO>();

      if (GetLastInputInfo(lastInputInfo) == 0) {
        return null;
      }

      final lastInputTick = lastInputInfo.ref.dwTime;
      final currentTick = GetTickCount();
      final elapsedMilliseconds = currentTick - lastInputTick;

      if (elapsedMilliseconds < 0) return Duration.zero;

      return Duration(milliseconds: elapsedMilliseconds);
    } finally {
      calloc.free(lastInputInfo);
    }
  }

  String _readWindowTitle(int hwnd) {
    final length = GetWindowTextLength(hwnd);
    if (length <= 0) return '';

    final buffer = calloc<ffi.Uint16>(length + 1).cast<Utf16>();

    try {
      final copied = GetWindowText(hwnd, buffer, length + 1);
      if (copied <= 0) return '';

      return buffer.toDartString().trim();
    } finally {
      calloc.free(buffer);
    }
  }

  String _readProcessPath(int hwnd) {
    final pidPointer = calloc<ffi.Uint32>();

    try {
      GetWindowThreadProcessId(hwnd, pidPointer);
      final pid = pidPointer.value;
      if (pid == 0) return '';

      final processHandle = OpenProcess(
        PROCESS_QUERY_LIMITED_INFORMATION,
        FALSE,
        pid,
      );

      if (processHandle == 0) return '';

      try {
        final pathBuffer = calloc<ffi.Uint16>(MAX_PATH).cast<Utf16>();
        final sizePointer = calloc<ffi.Uint32>()..value = MAX_PATH;

        try {
          final ok =
              QueryFullProcessImageName(
                processHandle,
                0,
                pathBuffer,
                sizePointer,
              ) !=
              0;

          return ok ? pathBuffer.toDartString().trim() : '';
        } finally {
          calloc.free(pathBuffer);
          calloc.free(sizePointer);
        }
      } finally {
        CloseHandle(processHandle);
      }
    } finally {
      calloc.free(pidPointer);
    }
  }

  String normalizeApp(String app) {
    final lower = app.toLowerCase().trim();

    return switch (lower) {
      'code.exe' => 'VS Code',
      'chrome.exe' => 'Chrome',
      'firefox.exe' => 'Firefox',
      'msedge.exe' => 'Edge',
      'discord.exe' => 'Discord',
      'figma.exe' => 'Figma',
      'winword.exe' => 'Word',
      'excel.exe' => 'Excel',
      'powerpnt.exe' => 'PowerPoint',
      'onenote.exe' => 'OneNote',
      'cmd.exe' => 'Command Prompt',
      'powershell.exe' => 'PowerShell',
      'windowsterminal.exe' => 'Windows Terminal',
      _ => app.replaceAll(RegExp(r'\.exe$', caseSensitive: false), '').trim(),
    };
  }

  void _emit(ActiveWindow window) {
    if (_isDisposed || _controller.isClosed) return;
    _controller.add(window);
  }
}
