import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/persistence/sync_ledger.dart';
import '../../../core/providers.dart';
import '../../../core/time/civil_day.dart';
import '../../../integrations/calendar/device_calendar.dart';
import '../../health_sync/data/health_sync_prefs.dart';
import '../../health_sync/service/routine_health_mirror.dart';
import '../data/micro_habits_prefs.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';
import '../data/routine_repository.dart';
import '../domain/daily_routine_state.dart';
import '../domain/routine_snapshot.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return RoutineRepository(prefs);
});

final deviceCalendarProvider = Provider<DeviceCalendar>((ref) {
  return DeviceCalendar();
});

class CivilTodayNotifier extends StateNotifier<DateTime> {
  CivilTodayNotifier() : super(civilDay(DateTime.now())) {
    _schedule();
  }

  Timer? _timer;

  void syncFromClock() {
    final today = civilDay(DateTime.now());
    if (!isSameCivilDay(state, today)) state = today;
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    var delay = next.difference(now);
    if (delay <= Duration.zero) delay = const Duration(seconds: 1);
    _timer = Timer(delay, () {
      syncFromClock();
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final civilTodayProvider =
    StateNotifierProvider<CivilTodayNotifier, DateTime>((ref) {
  return CivilTodayNotifier();
});

final todayRoutineDraftProvider = FutureProvider<DailyRoutineState>((ref) async {
  final l10n = ref.watch(appLocalizationsProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final repo = ref.watch(routineRepositoryProvider);
  final today = ref.watch(civilTodayProvider);
  final todaySnapshots = repo.getSnapshotsForDate(today);
  final waterGlasses = todaySnapshots.isEmpty
      ? 0
      : todaySnapshots
          .map((snapshot) => snapshot.waterGlasses)
          .reduce((a, b) => a > b ? a : b);
  return DailyRoutineState(
    date: today,
    microHabits: getMicroHabitsTemplate(prefs, l10n),
    waterGlasses: waterGlasses,
  );
});

final todaySnapshotsProvider = FutureProvider<List<RoutineSnapshot>>((ref) async {
  final repo = ref.watch(routineRepositoryProvider);
  final today = ref.watch(civilTodayProvider);
  return repo.getSnapshotsForDate(today);
});

final recentRoutineSnapshotsProvider =
    FutureProvider<List<RoutineSnapshot>>((ref) async {
  final repo = ref.watch(routineRepositoryProvider);
  final start = DateTime.now().subtract(const Duration(days: 31));
  return repo.snapshotsSince(start);
});

final markedRoutineDaysProvider = FutureProvider<Set<DateTime>>((ref) async {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.markedDays();
});

/// Contagem de State of Mind vindo do Apple Health. A UI só observa.
final appleHealthStateOfMindCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.countAppleHealthStateOfMind();
});

/// Espelha a rotina no Health. O [Ref] lê o SharedPreferences;
/// a tela não declara esse objeto.
Future<void> mirrorSavedRoutine(
  Ref ref, {
  required String snapshotId,
  required DailyRoutineState previous,
  required DailyRoutineState current,
}) {
  return RoutineHealthMirror.mirrorIfEnabled(
    prefs: ref.read(sharedPreferencesProvider),
    healthService: ref.read(healthServiceProvider),
    snapshotId: snapshotId,
    previous: previous,
    current: current,
    syncEnabled: ref.read(healthSyncEnabledProvider),
  );
}

class RoutineHealthMirrorNotifier extends StateNotifier<bool> {
  RoutineHealthMirrorNotifier(this._ref) : super(false);

  final Ref _ref;

  Future<void> mirror({
    required String snapshotId,
    required DailyRoutineState previous,
    required DailyRoutineState current,
  }) {
    return mirrorSavedRoutine(
      _ref,
      snapshotId: snapshotId,
      previous: previous,
      current: current,
    );
  }

  Future<void> saveSnapshot(RoutineSnapshot snapshot) async {
    final repo = _ref.read(routineRepositoryProvider);
    await repo.appendSnapshot(snapshot);
    final current = snapshot.toRoutineState();
    final previous = DailyRoutineState(
      date: current.date,
      microHabits: current.microHabits,
    );
    await mirror(
      snapshotId: snapshot.id,
      previous: previous,
      current: current,
    );
    await _writeCalendarEvent(repo, snapshot);
    _ref.invalidate(todaySnapshotsProvider);
    _ref.invalidate(recentRoutineSnapshotsProvider);
    _ref.invalidate(markedRoutineDaysProvider);
    _ref.invalidate(appleHealthStateOfMindCountProvider);
  }

  /// Funde o State of Mind do dia no snapshot canônico (merge in-place no
  /// último snapshot ou cria um mínimo) sem a UI tocar no SharedPreferences.
  /// Usado pelo quick check-in para que o SoM rápido seja a mesma fonte
  /// emocional da aba Dia. Retorna o snapshot resultante.
  Future<RoutineSnapshot> mergeTodayStateOfMind(StateOfMindEntry entry) async {
    final repo = _ref.read(routineRepositoryProvider);
    final snapshot = await repo.mergeTodayStateOfMind(entry);
    _ref.invalidate(todaySnapshotsProvider);
    _ref.invalidate(recentRoutineSnapshotsProvider);
    _ref.invalidate(markedRoutineDaysProvider);
    _ref.invalidate(appleHealthStateOfMindCountProvider);
    return snapshot;
  }

  Future<void> _writeCalendarEvent(
    RoutineRepository repo,
    RoutineSnapshot snapshot,
  ) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    if (snapshot.calendarEventId != null ||
        SyncLedger.contains(
          prefs,
          SyncLedger.calendarSnapshots,
          snapshot.id,
        )) {
      return;
    }
    final l10n = _ref.read(appLocalizationsProvider);
    final calendar = _ref.read(deviceCalendarProvider);
    final eventId = await calendar.createRoutineEvent(
      prefs: prefs,
      title: routineCalendarTitle(l10n, snapshot),
      start: snapshot.savedAt,
      notes: routineCalendarNotes(l10n, snapshot),
    );
    if (eventId == null || eventId.isEmpty) return;
    await SyncLedger.remember(
      prefs,
      SyncLedger.calendarSnapshots,
      snapshot.id,
    );
    await repo.setCalendarEventId(
      savedAt: snapshot.savedAt,
      snapshotId: snapshot.id,
      eventId: eventId,
    );
  }
}

final routineHealthMirrorProvider =
    StateNotifierProvider<RoutineHealthMirrorNotifier, bool>((ref) {
      return RoutineHealthMirrorNotifier(ref);
    });
