import 'package:shared_preferences/shared_preferences.dart';

const String onboardingDoneKey = 'noa_onboarding_done_v1';

bool shouldShowFirstLaunchOnboarding(SharedPreferences prefs) {
  if (prefs.getBool(onboardingDoneKey) ?? false) return false;

  final alreadyUsing = prefs.containsKey('noa_mood_entries_v2') ||
      prefs.containsKey('noa_medications_list_v2') ||
      prefs.containsKey('noa_user_profile_v1') ||
      prefs.getBool('noa_health_sync_enabled') == true;
  if (alreadyUsing) {
    prefs.setBool(onboardingDoneKey, true);
    return false;
  }
  return true;
}

Future<void> markOnboardingDone(SharedPreferences prefs) {
  return prefs.setBool(onboardingDoneKey, true);
}
