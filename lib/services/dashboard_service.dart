import '../models/activity_record.dart';
import '../models/dashboard_data.dart';
import '../models/focus_input.dart';
import '../models/focus_score_result.dart';
import '../services/activity_service.dart';
import '../services/settings_service.dart';

class DashboardService {
  DashboardService._internal() : activityService = ActivityService();

  DashboardService._custom(this.activityService);

  factory DashboardService({ActivityService? activityService}) {
    if (activityService != null) {
      return DashboardService._custom(activityService);
    }

    return instance;
  }

  static final DashboardService instance = DashboardService._internal();

  final ActivityService activityService;

  DashboardData? _cachedDashboardData;
  DevicePlatform? _cachedPlatform;
  DateTime? _cachedAt;

  static const Duration cacheDuration = Duration(seconds: 30);

  bool get hasCachedData => _cachedDashboardData != null;

  DashboardData? get cachedDashboardData => _cachedDashboardData;

  bool _isCacheValid(DevicePlatform platform) {
    final cachedAt = _cachedAt;

    if (_cachedDashboardData == null || cachedAt == null) return false;
    if (_cachedPlatform != platform) return false;

    return DateTime.now().difference(cachedAt) < cacheDuration;
  }

  Future<DashboardData> getDashboardData({
    DevicePlatform? platform,
    bool forceRefresh = false,
  }) async {
    final selectedPlatform = platform ?? SettingsService.platform.value;

    if (!forceRefresh && _isCacheValid(selectedPlatform)) {
      return _cachedDashboardData!;
    }

    final data = await activityService.getDashboardData(selectedPlatform);
    _saveCache(data, selectedPlatform);

    return data;
  }

  Future<DashboardData> refresh({DevicePlatform? platform}) {
    return getDashboardData(platform: platform, forceRefresh: true);
  }

  void clearCache() {
    _cachedDashboardData = null;
    _cachedPlatform = null;
    _cachedAt = null;
  }

  Future<List<ActivityRecord>> getTodayActivities({
    bool forceRefresh = false,
  }) async {
    final data = await getDashboardData(forceRefresh: forceRefresh);
    return data.todayActivities;
  }

  Future<FocusInput> getTodayFocusInput({
    DevicePlatform? platform,
    bool forceRefresh = false,
  }) async {
    final data = await getDashboardData(
      platform: platform,
      forceRefresh: forceRefresh,
    );

    return data.focusInput;
  }

  Future<FocusScoreResult> getTodayFocusResult({
    DevicePlatform? platform,
    bool forceRefresh = false,
  }) async {
    final data = await getDashboardData(
      platform: platform,
      forceRefresh: forceRefresh,
    );

    return data.focusResult;
  }

  Future<List<double>> getWeeklyFocusTrend({
    DevicePlatform? platform,
    bool forceRefresh = false,
  }) async {
    final data = await getDashboardData(
      platform: platform,
      forceRefresh: forceRefresh,
    );

    return data.weeklyFocusTrend;
  }

  Future<int> getTodayScreenMinutes({bool forceRefresh = false}) async {
    final data = await getDashboardData(forceRefresh: forceRefresh);
    return data.totalScreenMinutes;
  }

  Future<void> warmUp({DevicePlatform? platform}) async {
    await getDashboardData(platform: platform, forceRefresh: true);
  }

  void _saveCache(DashboardData data, DevicePlatform platform) {
    _cachedDashboardData = data;
    _cachedPlatform = platform;
    _cachedAt = DateTime.now();
  }
}
