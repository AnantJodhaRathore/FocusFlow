import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstLaunchService {
  FirstLaunchService._internal();

  static final FirstLaunchService instance = FirstLaunchService._internal();

  static const String _onboardingCompleteKey = 'focusflow_onboarding_complete';

  final ValueNotifier<bool> shouldShowOnboarding = ValueNotifier(true);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_onboardingCompleteKey) ?? false;

    shouldShowOnboarding.value = !completed;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_onboardingCompleteKey, true);
    shouldShowOnboarding.value = false;
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_onboardingCompleteKey, false);
    shouldShowOnboarding.value = true;
  }
}
