import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/time/civil_day.dart';
import '../../medications/presentation/providers/medication_providers.dart';
import '../../routine_mood/presentation/routine_providers.dart';
import '../../tasks/presentation/task_providers.dart';
import '../domain/day_digest.dart';

final dayDigestProvider =
    FutureProvider.family<DayDigest, DateTime>((ref, day) async {
  final civil = DayDigest.civilDay(day);
  final moodRepo = ref.watch(moodRepositoryProvider);
  final routineRepo = ref.watch(routineRepositoryProvider);
  final medRepo = ref.watch(medicationRepositoryProvider);
  final tasks = ref.watch(tasksListProvider).value ?? const [];

  final checkIns = await moodRepo.getEntriesForCivilDay(civil);
  final snapshots = routineRepo.getSnapshotsForDate(civil);
  // Digest só lê — reconcile/write fica na aba Remédios / ações de dose.
  final logs = await medRepo.getLogsForDateReadOnly(civil);

  final dayKey = civilDayKey(civil);
  final completed = <String>{};
  for (final task in tasks) {
    if (!task.active) continue;
    final key = task.completedPeriodKey;
    if (key == null || key.isEmpty) continue;
    final fromSnapshot = snapshots.any(
      (s) => s.completedHabits.contains(task.title),
    );
    if (key == dayKey || fromSnapshot) {
      completed.add(task.title);
    }
  }

  return DayDigest(
    day: civil,
    checkIns: checkIns,
    snapshots: snapshots,
    medicationLogs: logs,
    completedTaskTitles: completed.toList()..sort(),
  );
});

/// Dias com rotina e/ou check-in (badges do calendário).
final markedHistoryDaysProvider = FutureProvider<Set<DateTime>>((ref) async {
  final routineDays = await ref.watch(markedRoutineDaysProvider.future);
  final moodDays = await ref.watch(moodRepositoryProvider).markedCivilDays();
  return {...routineDays, ...moodDays};
});
