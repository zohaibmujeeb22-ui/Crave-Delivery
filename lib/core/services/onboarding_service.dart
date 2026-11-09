import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences is not initialized');
});

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingService(prefs);
});

class OnboardingService {
  final SharedPreferences _prefs;
  static const String _onboardingKey = 'has_completed_onboarding';

  OnboardingService(this._prefs);

  bool hasCompletedOnboarding() {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
  }
}
