import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers.dart';

const String healthSyncEnabledKey = 'noa_health_sync_enabled';
const String _waterSyncedPrefix = 'noa_health_water_synced_';
const String _mindfulnessSyncedPrefix = 'noa_health_mindfulness_synced_';

/// Preferência local: usuário confirmou sync com Apple Health.
class HealthSyncEnabledNotifier extends StateNotifier<bool> {
  HealthSyncEnabledNotifier(this._prefs) : super(false) {
    state = _prefs.getBool(healthSyncEnabledKey) ?? false;
  }

  final SharedPreferences _prefs;

  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(healthSyncEnabledKey, enabled);
    state = enabled;
  }
}

final healthSyncEnabledProvider =
    StateNotifierProvider<HealthSyncEnabledNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HealthSyncEnabledNotifier(prefs);
});

String _dayKey(DateTime date) => '${date.year}_${date.month}_${date.day}';

/// Quantidade de copos já espelhados no Health para o dia.
int getSyncedWaterGlasses(SharedPreferences prefs, DateTime date) {
  return prefs.getInt('$_waterSyncedPrefix${_dayKey(date)}') ?? 0;
}

Future<void> setSyncedWaterGlasses(
  SharedPreferences prefs,
  DateTime date,
  int glasses,
) async {
  await prefs.setInt('$_waterSyncedPrefix${_dayKey(date)}', glasses);
}

/// Se a sessão de mindfulness do hábito de respirar já foi escrita hoje.
bool wasMindfulnessSyncedToday(SharedPreferences prefs, DateTime date) {
  return prefs.getBool('$_mindfulnessSyncedPrefix${_dayKey(date)}') ?? false;
}

Future<void> setMindfulnessSyncedToday(
  SharedPreferences prefs,
  DateTime date, {
  required bool synced,
}) async {
  await prefs.setBool('$_mindfulnessSyncedPrefix${_dayKey(date)}', synced);
}

/// Identifica o micro-hábito de respiração / atenção plena (qualquer idioma).
bool isBreathingMindfulnessHabit(String habit) {
  final lower = habit.toLowerCase();
  return lower.contains('respir') ||
      lower.contains('breath') ||
      lower.contains('alongar') ||
      lower.contains('stretch') ||
      lower.contains('estir') ||
      lower.contains('mindful') ||
      lower.contains('atenção plena') ||
      lower.contains('atención plena') ||
      lower.contains('atencion plena') ||
      habit.contains('深呼吸') ||
      habit.contains('ストレッチ');
}

const String _somSyncedPrefix = 'noa_health_som_synced_';

int? getSyncedStateOfMindMs(SharedPreferences prefs, DateTime date) {
  return prefs.getInt('$_somSyncedPrefix${date.year}_${date.month}_${date.day}');
}

Future<void> setSyncedStateOfMindMs(
  SharedPreferences prefs,
  DateTime date,
  int timestampMs,
) async {
  await prefs.setInt(
    '$_somSyncedPrefix${date.year}_${date.month}_${date.day}',
    timestampMs,
  );
}
