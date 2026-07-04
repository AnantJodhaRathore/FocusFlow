import '../models/focus_input.dart';
import '../models/focus_score_result.dart';
import '../services/activity_service.dart';
import '../services/settings_service.dart';
import 'focus_score_engine.dart';

class FocusMetrics {
  FocusMetrics._();

  static FocusScoreResult calculate(FocusInput input) {
    return FocusScoreEngine.calculate(input);
  }

  static EvaluatedMetrics evaluate(FocusInput input) {
    return EvaluatedMetrics._(calculate(input));
  }

  static Future<FocusInput> inputAsync({
    DateTime? date,
    ActivityService? activityService,
  }) {
    return (activityService ?? ActivityService()).buildFocusInputForDate(
      date ?? DateTime.now(),
      platform: SettingsService.platform.value,
    );
  }

  static Future<FocusScoreResult> resultAsync({
    DateTime? date,
    ActivityService? activityService,
  }) async {
    final input = await inputAsync(
      date: date,
      activityService: activityService,
    );

    return calculate(input);
  }

  static Future<int> focusScoreAsync({
    DateTime? date,
    ActivityService? activityService,
  }) async {
    return (await resultAsync(
      date: date,
      activityService: activityService,
    )).focusScore;
  }

  static Future<int> productiveTimeScoreAsync({
    DateTime? date,
    ActivityService? activityService,
  }) async {
    return (await resultAsync(
      date: date,
      activityService: activityService,
    )).productiveTimeScore;
  }

  static Future<int> distractionScoreAsync({
    DateTime? date,
    ActivityService? activityService,
  }) async {
    return (await resultAsync(
      date: date,
      activityService: activityService,
    )).distractionScore;
  }

  static Future<int> recoveryScoreAsync({
    DateTime? date,
    ActivityService? activityService,
  }) async {
    return (await resultAsync(
      date: date,
      activityService: activityService,
    )).recoveryScore;
  }

  static Future<int> deepWorkScoreAsync({
    DateTime? date,
    ActivityService? activityService,
  }) async {
    return (await resultAsync(
      date: date,
      activityService: activityService,
    )).deepWorkScore;
  }

  static Future<int> breakComplianceScoreAsync({
    DateTime? date,
    ActivityService? activityService,
  }) async {
    return (await resultAsync(
      date: date,
      activityService: activityService,
    )).breakComplianceScore;
  }

  static Future<int> screenTimeScoreAsync({
    DateTime? date,
    ActivityService? activityService,
  }) async {
    return (await resultAsync(
      date: date,
      activityService: activityService,
    )).screenTimeScore;
  }
}

class EvaluatedMetrics {
  final FocusScoreResult result;

  const EvaluatedMetrics._(this.result);

  int get focusScore => result.focusScore;

  int get productiveTimeScore => result.productiveTimeScore;

  int get distractionScore => result.distractionScore;

  int get recoveryScore => result.recoveryScore;

  int get deepWorkScore => result.deepWorkScore;

  int get breakComplianceScore => result.breakComplianceScore;

  int get screenTimeScore => result.screenTimeScore;

  FocusLevel get level => result.level;

  String get label => result.label;
}
