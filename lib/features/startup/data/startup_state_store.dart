import 'package:shared_preferences/shared_preferences.dart';

abstract interface class StartupStateStore {
  Future<bool> isOnboardingComplete();

  Future<void> markOnboardingComplete();
}

final class SharedPreferencesStartupStateStore implements StartupStateStore {
  SharedPreferencesStartupStateStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _onboardingCompleteKey = 'startup.onboarding_complete.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isOnboardingComplete() async {
    return await _preferences.getBool(_onboardingCompleteKey) ?? false;
  }

  @override
  Future<void> markOnboardingComplete() {
    return _preferences.setBool(_onboardingCompleteKey, true);
  }
}
