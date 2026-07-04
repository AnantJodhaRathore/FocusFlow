import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/windows_notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart'; // Added onboarding screen import
import 'services/app_lifecycle_service.dart';
import 'services/focus_alert_service.dart'; // Added Focus Alert Service import
import 'services/activity_service.dart';
import 'services/monitoring_service.dart';
import 'services/storage_service.dart';
import 'services/firebase_sync_service.dart';
import 'services/settings_service.dart';
import 'services/theme_mode_service.dart';
import 'services/first_launch_service.dart'; // Added first launch service import
import 'theme/focusflow_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = false;

  // Initialize Firebase first before local services spin up
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    debugPrint('[FocusFlow] Firebase initialized');
  } catch (error, stackTrace) {
    debugPrint('[FocusFlow] Firebase startup error: $error');
    debugPrint('$stackTrace');
  }

  final storageService = StorageService();
  final activityService = ActivityService(storageService: storageService);

  // Initialize local services and database
  try {
    await storageService.initialize();

    // Register native notification bridges
    await WindowsNotificationService.instance.registerWithNotificationService();

    await AppLifecycleService.instance.initialize();

    // Start the Focus Alert Service
    await FocusAlertService.instance.start();

    // Initialize the Theme Mode Service
    await ThemeModeService.instance.initialize();

    // Initialize the First Launch Service
    await FirstLaunchService.instance.initialize();

    // Process queued offline syncs before dispatching today's data milestone
    if (firebaseReady && SettingsService.syncEnabled.value) {
      final retryCount = await FirebaseSyncService.instance
          .retryPendingDailySummaries();

      debugPrint('[FocusFlow] Pending daily summaries retried: $retryCount');

      final syncResult = await FirebaseSyncService.instance.syncTodaySummary();

      debugPrint('[FocusFlow] Daily summary sync status: ${syncResult.status}');
      debugPrint('[FocusFlow] Daily summary path: ${syncResult.documentPath}');
    }

    if (kDebugMode) {
      await _runDebugDiagnosticDump(storageService, activityService);
    }
  } catch (error, stackTrace) {
    debugPrint('[FocusFlow] Startup error: $error');
    debugPrint('$stackTrace');
  }

  runApp(const FocusFlowApp());
}

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeService.instance.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'FocusFlow',
          debugShowCheckedModeBanner: false,
          theme: FocusFlowTheme.lightTheme,
          darkTheme: FocusFlowTheme.darkTheme,
          themeMode: themeMode,
          home: ValueListenableBuilder<bool>(
            valueListenable: FirstLaunchService.instance.shouldShowOnboarding,
            builder: (context, shouldShowOnboarding, _) {
              if (shouldShowOnboarding) {
                return const OnboardingScreen();
              }
              return const HomeScreen();
            },
          ),
        );
      },
    );
  }
}

Future<void> _runDebugDiagnosticDump(
  StorageService storageService,
  ActivityService activityService,
) async {
  try {
    final activities = await storageService.getActivities();
    final sessions = await activityService.getSessions();
    final monitoringStatus = MonitoringService.instance.status.value;

    debugPrint('[FocusFlow] Activities in DB: ${activities.length}');
    debugPrint('[FocusFlow] Sessions in DB: ${sessions.length}');
    debugPrint('[FocusFlow] Monitoring status: $monitoringStatus');
  } catch (error) {
    debugPrint('[FocusFlow] Debug diagnostics failed: $error');
  }
}
