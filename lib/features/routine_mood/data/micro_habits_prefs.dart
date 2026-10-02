import 'dart:convert';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String microHabitsTemplateKey = 'noa_micro_habits_template';

List<String> defaultMicroHabits(AppLocalizations l10n) => [
      l10n.microHabitSun,
      l10n.microHabitWater,
      l10n.microHabitScreenPause,
      l10n.microHabitStretch,
    ];

List<String> getMicroHabitsTemplate(
  SharedPreferences prefs,
  AppLocalizations l10n,
) {
  final raw = prefs.getString(microHabitsTemplateKey);
  if (raw == null || raw.isEmpty) {
    return List<String>.from(defaultMicroHabits(l10n));
  }
  try {
    final list =
        (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toList();
    return list;
  } catch (_) {
    return List<String>.from(defaultMicroHabits(l10n));
  }
}

Future<void> setMicroHabitsTemplate(
  SharedPreferences prefs,
  List<String> habits,
) async {
  await prefs.setString(microHabitsTemplateKey, jsonEncode(habits));
}
