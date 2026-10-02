import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../integrations/health/health_service.dart';
import '../../routine_mood/domain/daily_routine_state.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';
import '../data/health_sync_prefs.dart';

/// Espelha deltas da rotina local para o Apple Health (água + mindfulness + SoM).
/// Falhas de escrita não bloqueiam o salvamento local.
class RoutineHealthMirror {
  static const double litersPerGlass = 0.25;
  static const Duration mindfulnessDuration = Duration(minutes: 3);

  static Future<void> mirrorIfEnabled({
    required SharedPreferences prefs,
    required HealthService healthService,
    required DailyRoutineState previous,
    required DailyRoutineState current,
    required bool syncEnabled,
  }) async {
    if (!syncEnabled) return;

    try {
      await healthService.initialize();
      await _mirrorWater(
        prefs: prefs,
        healthService: healthService,
        current: current,
      );
      await _mirrorMindfulness(
        prefs: prefs,
        healthService: healthService,
        previous: previous,
        current: current,
      );
      await _mirrorStateOfMind(
        prefs: prefs,
        healthService: healthService,
        current: current,
      );
    } catch (e) {
      debugPrint('[RoutineHealthMirror] Falha ao espelhar rotina: $e');
    }
  }

  static Future<void> _mirrorWater({
    required SharedPreferences prefs,
    required HealthService healthService,
    required DailyRoutineState current,
  }) async {
    final delta = current.waterGlasses;
    if (delta <= 0) return;

    final alreadySynced = getSyncedWaterGlasses(prefs, current.date);
    final now = DateTime.now();
    var written = 0;
    for (var i = 0; i < delta; i++) {
      final ok = await healthService.writeWaterIntake(
        when: now.add(Duration(milliseconds: i * 50)),
        liters: litersPerGlass,
      );
      if (ok) {
        written++;
      } else {
        break;
      }
    }
    if (written > 0) {
      await setSyncedWaterGlasses(
        prefs,
        current.date,
        alreadySynced + written,
      );
    }
  }

  static Future<void> _mirrorMindfulness({
    required SharedPreferences prefs,
    required HealthService healthService,
    required DailyRoutineState previous,
    required DailyRoutineState current,
  }) async {
    if (wasMindfulnessSyncedToday(prefs, current.date)) return;

    final newlyCompleted =
        current.completedHabits.difference(previous.completedHabits);
    final hasBreathing = newlyCompleted.any(isBreathingMindfulnessHabit);
    if (!hasBreathing) return;

    final end = DateTime.now();
    final start = end.subtract(mindfulnessDuration);
    final ok = await healthService.writeMindfulnessSession(
      start: start,
      end: end,
    );
    if (ok) {
      await setMindfulnessSyncedToday(prefs, current.date, synced: true);
    }
  }

  static Future<void> _mirrorStateOfMind({
    required SharedPreferences prefs,
    required HealthService healthService,
    required DailyRoutineState current,
  }) async {
    final entry = current.stateOfMind;
    if (entry == null || entry.source == StateOfMindSource.appleHealth) return;

    final syncedMs = getSyncedStateOfMindMs(prefs, current.date);
    final entryMs = entry.timestamp.millisecondsSinceEpoch;
    if (syncedMs != null && syncedMs == entryMs) return;

    final ok = await healthService.writeStateOfMind(entry);
    if (ok) {
      await setSyncedStateOfMindMs(prefs, current.date, entryMs);
    }
  }

  /// Lê SoM do Apple Health e mescla com o estado local do dia (mais recente vence).
  static Future<DailyRoutineState> mergeStateOfMindFromHealth({
    required DailyRoutineState local,
    required bool syncEnabled,
    required HealthService healthService,
  }) async {
    if (!syncEnabled) return local;

    final end = DateTime(local.date.year, local.date.month, local.date.day)
        .add(const Duration(days: 1));
    final start = DateTime(local.date.year, local.date.month, local.date.day);
    final all = await healthService.getStateOfMindHistory(days: 14);
    final remote = all
        .where((e) => !e.timestamp.isBefore(start) && e.timestamp.isBefore(end))
        .toList();
    if (remote.isEmpty) return local;

    final fromApple =
        remote.first.copyWith(source: StateOfMindSource.appleHealth);
    final merged =
        StateOfMindEntry.mergePreferNewest(local.stateOfMind, fromApple);
    if (merged == null || identical(merged, local.stateOfMind)) return local;
    return local.copyWith(stateOfMind: merged);
  }
}
