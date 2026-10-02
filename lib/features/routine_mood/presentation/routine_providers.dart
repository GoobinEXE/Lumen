import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../integrations/calendar/device_calendar.dart';
import '../../health_sync/data/health_sync_prefs.dart';
import '../../health_sync/service/routine_health_mirror.dart';
import '../data/micro_habits_prefs.dart';
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

final todayRoutineDraftProvider = FutureProvider<DailyRoutineState>((ref) async {
  final l10n = ref.watch(appLocalizationsProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final now = DateTime.now();
  return DailyRoutineState(
    date: DateTime(now.year, now.month, now.day),
    microHabits: getMicroHabitsTemplate(prefs, l10n),
  );
});

final todaySnapshotsProvider = FutureProvider<List<RoutineSnapshot>>((ref) async {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.getSnapshotsForDate(DateTime.now());
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
  required DailyRoutineState previous,
  required DailyRoutineState current,
}) {
  return RoutineHealthMirror.mirrorIfEnabled(
    prefs: ref.read(sharedPreferencesProvider),
    healthService: ref.read(healthServiceProvider),
    previous: previous,
    current: current,
    syncEnabled: ref.read(healthSyncEnabledProvider),
  );
}

class RoutineHealthMirrorNotifier extends StateNotifier<bool> {
  RoutineHealthMirrorNotifier(this._ref) : super(false);

  final Ref _ref;

  Future<void> mirror({
    required DailyRoutineState previous,
    required DailyRoutineState current,
  }) {
    return mirrorSavedRoutine(_ref, previous: previous, current: current);
  }

  Future<void> saveSnapshot(RoutineSnapshot snapshot) async {
    final repo = _ref.read(routineRepositoryProvider);
    await repo.appendSnapshot(snapshot);
    final current = snapshot.toRoutineState();
    final previous = DailyRoutineState(
      date: current.date,
      microHabits: current.microHabits,
    );
    await mirror(previous: previous, current: current);
    await _writeCalendarEvent(repo, snapshot);
    _ref.invalidate(todaySnapshotsProvider);
    _ref.invalidate(recentRoutineSnapshotsProvider);
    _ref.invalidate(markedRoutineDaysProvider);
    _ref.invalidate(appleHealthStateOfMindCountProvider);
  }

  Future<void> _writeCalendarEvent(
    RoutineRepository repo,
    RoutineSnapshot snapshot,
  ) async {
    if (snapshot.calendarEventId != null) return;
    final l10n = _ref.read(appLocalizationsProvider);
    final calendar = _ref.read(deviceCalendarProvider);
    final prefs = _ref.read(sharedPreferencesProvider);
    final eventId = await calendar.createRoutineEvent(
      prefs: prefs,
      title: routineCalendarTitle(l10n, snapshot),
      start: snapshot.savedAt,
      notes: routineCalendarNotes(l10n, snapshot),
    );
    if (eventId == null || eventId.isEmpty) return;
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
