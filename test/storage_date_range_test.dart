import 'package:flutter_test/flutter_test.dart';
import 'package:focusflow/services/storage_service.dart';
import 'package:focusflow/models/activity_record.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Ensure ffi is initialized for desktop tests and use ffi factory.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    // Remove any existing DB so tests run against a clean state.
    await deleteDatabase(join(dbPath, 'focusflow.db'));

    await StorageService().initialize();
  });

  test(
    'StorageService date and range queries return expected activities',
    () async {
      final storage = StorageService();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final sevenDaysAgo = today.subtract(const Duration(days: 6));

      // Seed three activities on different dates
      final aToday = ActivityRecord(
        appName: 'Editor',
        category: 'Work',
        durationMinutes: 30,
        startTime: today.add(const Duration(hours: 9)),
      );

      final aYesterday = ActivityRecord(
        appName: 'Browser',
        category: 'Research',
        durationMinutes: 15,
        startTime: yesterday.add(const Duration(hours: 10)),
      );

      final aSevenDays = ActivityRecord(
        appName: 'Notes',
        category: 'Other',
        durationMinutes: 20,
        startTime: sevenDaysAgo.add(const Duration(hours: 8)),
      );

      await storage.saveActivity(aToday);
      await storage.saveActivity(aYesterday);
      await storage.saveActivity(aSevenDays);

      // Query by calendar day
      final tActs = await storage.getActivities(date: today);
      expect(tActs.length, 1);
      expect(tActs.first.appName, 'Editor');

      final yActs = await storage.getActivities(date: yesterday);
      expect(yActs.length, 1);
      expect(yActs.first.appName, 'Browser');

      // Query range covering last 7 days (inclusive of sevenDaysAgo -> today)
      final rangeStart = sevenDaysAgo;
      final rangeEnd = today.add(const Duration(days: 1));
      final rangeActs = await storage.getActivitiesInRange(
        rangeStart,
        rangeEnd,
      );
      // All three activities fall within this range
      expect(rangeActs.length, 3);
    },
  );
}
