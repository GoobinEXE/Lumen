import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/persistence/sync_ledger.dart';
import '../../../integrations/health/health_service.dart';
import '../../routine_mood/domain/daily_routine_state.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';
import '../data/health_sync_prefs.dart';

/// Espelha deltas da rotina local para o app de saúde (água + mindfulness + SoM).
/// No Android, água e mindfulness passam pelo connector ativo (Samsung / HC);
/// SoM continua só no HealthKit. Falhas de escrita não bloqueiam o save local.
class RoutineHealthMirror {
  static const double litersPerGlass = 0.25;
  static const Duration mindfulnessDuration = Duration(minutes: 3);

  static Future<void> mirrorIfEnabled({
    required SharedPreferences prefs,
    required HealthService healthService,
    required String snapshotId,
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
        snapshotId: snapshotId,
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
    required String snapshotId,
    required DailyRoutineState current,
  }) async {
    if (SyncLedger.contains(prefs, SyncLedger.waterSnapshots, snapshotId)) {
      return;
    }

    final alreadySynced = getSyncedWaterGlasses(prefs, current.date);
    final pending = current.waterGlasses - alreadySynced;
    final delta = pending > 0 ? pending : 0;
    if (delta <= 0) return;

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
    if (written != delta) return;
    await SyncLedger.remember(prefs, SyncLedger.waterSnapshots, snapshotId);
    await setSyncedWaterGlasses(
      prefs,
      current.date,
      alreadySynced + written,
    );
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
    if (entry == null) return;
    await mirrorStateOfMindEntry(
      prefs: prefs,
      healthService: healthService,
      entry: entry,
      day: current.date,
    );
  }

  /// Espelha um SoM avulso (check-in ou rotina). Idempotente via ledger.
  static Future<void> mirrorStateOfMindEntry({
    required SharedPreferences prefs,
    required HealthService healthService,
    required StateOfMindEntry entry,
    required DateTime day,
  }) async {
    if (entry.source == StateOfMindSource.appleHealth) return;

    final entryMs = entry.timestamp.millisecondsSinceEpoch;
    final civil = DateTime(day.year, day.month, day.day);
    final legacyMs = getSyncedStateOfMindMs(prefs, civil);
    final marker = entryMs.toString();
    if (legacyMs == entryMs ||
        SyncLedger.contains(prefs, SyncLedger.stateOfMindMs, marker)) {
      await SyncLedger.remember(prefs, SyncLedger.stateOfMindMs, marker);
      return;
    }

    final ok = await healthService.writeStateOfMind(entry);
    if (ok) {
      await SyncLedger.remember(prefs, SyncLedger.stateOfMindMs, marker);
      await setSyncedStateOfMindMs(prefs, civil, entryMs);
    }
  }

  /// Check-in local → HealthKit SoM (iOS 18+). Falha não apaga o MoodEntry.
  static Future<void> mirrorCheckInIfEnabled({
    required SharedPreferences prefs,
    required HealthService healthService,
    required bool syncEnabled,
    required int valence,
    required Set<String> emotionLabels,
    required DateTime timestamp,
  }) async {
    if (!syncEnabled) return;
    try {
      await healthService.initialize();
      final entry = StateOfMindEntry(
        kind: StateOfMindKind.momentary,
        valence: StateOfMindEntry.checkinScaleToValence(valence),
        labels: emotionLabels,
        timestamp: timestamp,
        source: StateOfMindSource.lumen,
      );
      await mirrorStateOfMindEntry(
        prefs: prefs,
        healthService: healthService,
        entry: entry,
        day: timestamp,
      );
    } catch (e) {
      debugPrint('[RoutineHealthMirror] Falha ao espelhar check-in: $e');
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
