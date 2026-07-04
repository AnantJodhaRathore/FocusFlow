import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../analytics/recovery_engine.dart';
import '../models/activity_record.dart';
import '../models/focus_session.dart';
import '../models/recovery_metric.dart';

class StorageService {
  StorageService._internal();

  static final StorageService instance = StorageService._internal();

  factory StorageService() => instance;

  static const String _databaseName = 'focusflow.db';
  static const int _databaseVersion = 4;

  static Database? _db;

  Database get database {
    final db = _db;
    if (db == null) {
      throw StateError('Database not initialized. Call initialize() first.');
    }
    return db;
  }

  Future<void> initialize() async {
    if (_db != null) return;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> init() => initialize();

  Future<void> _createDatabase(Database db, int version) async {
    await _createActivitiesTable(db);
    await _createFocusSessionsTable(db);
    await _createAttentionFlowsTable(db);
    await _createRecoveryMetricsTable(db);
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createFocusSessionsTable(db);
    }

    if (oldVersion < 3) {
      await _createAttentionFlowsTable(db);
    }

    if (oldVersion < 4) {
      await _createRecoveryMetricsTable(db);
    }
  }

  Future<void> _createActivitiesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appName TEXT NOT NULL,
        category TEXT NOT NULL,
        startTime TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createFocusSessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        appName TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createAttentionFlowsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attention_flows(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productive_app TEXT NOT NULL,
        distraction_app TEXT NOT NULL,
        productive_start TEXT NOT NULL,
        distraction_start TEXT NOT NULL,
        recovery_start TEXT NOT NULL,
        distraction_duration INTEGER NOT NULL,
        recovery_duration INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _createRecoveryMetricsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recovery_metrics(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        recoveryScore INTEGER NOT NULL,
        type TEXT NOT NULL,
        quality TEXT NOT NULL,
        source TEXT,
        note TEXT
      )
    ''');
  }

  Future<int> saveActivity(ActivityRecord activity) {
    return database.insert(
      'activities',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertActivity(ActivityRecord activity) => saveActivity(activity);

  Future<int> updateActivity(ActivityRecord activity) {
    if (activity.id == null) {
      throw ArgumentError('Cannot update ActivityRecord without id.');
    }

    return database.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<int> deleteActivity(int id) {
    return database.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ActivityRecord>> getActivities({DateTime? date}) {
    if (date == null) {
      return _getActivities(orderBy: 'startTime ASC');
    }

    return getActivitiesByDate(date);
  }

  Future<List<ActivityRecord>> getActivitiesByDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return getActivitiesInRange(start, end);
  }

  Future<List<ActivityRecord>> getActivitiesInRange(
    DateTime start,
    DateTime end,
  ) {
    return _getActivities(
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'startTime ASC',
    );
  }

  Future<List<ActivityRecord>> getTodayActivities() {
    return getActivitiesByDate(DateTime.now());
  }

  Future<List<ActivityRecord>> getYesterdayActivities() {
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));

    return getActivitiesByDate(yesterday);
  }

  Future<List<ActivityRecord>> getLastNDaysActivities(int days) {
    if (days <= 0) return Future.value([]);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: days - 1));
    final end = today.add(const Duration(days: 1));

    return getActivitiesInRange(start, end);
  }

  Future<List<ActivityRecord>> getLast7DaysActivities() {
    return getLastNDaysActivities(7);
  }

  Future<List<ActivityRecord>> _getActivities({
    String? where,
    List<Object?>? whereArgs,
    String orderBy = 'startTime ASC',
  }) async {
    final maps = await database.query(
      'activities',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return maps.map(ActivityRecord.fromMap).toList();
  }

  Future<int> saveSession(FocusSession session) {
    return database.insert(
      'focus_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<FocusSession>> getSessions() async {
    final maps = await database.query(
      'focus_sessions',
      orderBy: 'startTime ASC',
    );

    return maps.map(FocusSession.fromMap).toList();
  }

  Future<List<FocusSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final maps = await database.query(
      'focus_sessions',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'startTime ASC',
    );

    return maps.map(FocusSession.fromMap).toList();
  }

  Future<int> deleteSession(int id) {
    return database.delete('focus_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> saveAttentionFlow(AttentionFlow flow) {
    return database.insert(
      'attention_flows',
      flow.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AttentionFlow>> getAttentionFlows() async {
    final maps = await database.query(
      'attention_flows',
      orderBy: 'productive_start ASC',
    );

    return maps.map(AttentionFlow.fromMap).toList();
  }

  Future<int> deleteAttentionFlow(int id) {
    return database.delete('attention_flows', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> saveRecoveryMetric(RecoveryMetric metric) {
    return database.insert(
      'recovery_metrics',
      metric.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RecoveryMetric>> getRecoveryMetrics() async {
    final maps = await database.query(
      'recovery_metrics',
      orderBy: 'startTime ASC',
    );

    return maps.map(RecoveryMetric.fromMap).toList();
  }

  Future<List<RecoveryMetric>> getRecoveryMetricsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final maps = await database.query(
      'recovery_metrics',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'startTime ASC',
    );

    return maps.map(RecoveryMetric.fromMap).toList();
  }

  Future<int> deleteRecoveryMetric(int id) {
    return database.delete(
      'recovery_metrics',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> totalScreenMinutesForDate(DateTime date) async {
    final activities = await getActivitiesByDate(date);
    return activities.fold<int>(
      0,
      (total, activity) => total + activity.durationMinutes,
    );
  }

  Future<void> seedTestData({bool force = false}) async {
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM activities'),
    );

    if (!force && (count ?? 0) > 0) return;

    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);

    final records = [
      ActivityRecord(
        appName: 'VS Code',
        category: 'work',
        durationMinutes: 120,
        startTime: base.add(const Duration(hours: 9)),
      ),
      ActivityRecord(
        appName: 'Chrome',
        category: 'research',
        durationMinutes: 60,
        startTime: base.add(const Duration(hours: 11)),
      ),
      ActivityRecord(
        appName: 'Break',
        category: 'break',
        durationMinutes: 30,
        startTime: base.add(const Duration(hours: 12)),
      ),
      ActivityRecord(
        appName: 'Word',
        category: 'work',
        durationMinutes: 75,
        startTime: base.add(const Duration(hours: 13)),
      ),
    ];

    for (final record in records) {
      await saveActivity(record);
    }
  }

  Future<void> clearAllData() async {
    await database.delete('activities');
    await database.delete('focus_sessions');
    await database.delete('attention_flows');
    await database.delete('recovery_metrics');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
