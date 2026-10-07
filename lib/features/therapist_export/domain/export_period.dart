import '../../routine_mood/domain/routine_snapshot.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';

/// A amostra cai na janela que o cabeçalho do resumo imprime.
///
/// O início é [now] menos [periodDays], no mesmo instante. Um check-in
/// anterior a esse ponto fica de fora, mesmo que o dia do calendário coincida.
bool isWithinExportPeriod({
  required DateTime instant,
  required DateTime now,
  required int periodDays,
}) {
  final start = now.subtract(Duration(days: periodDays));
  return !instant.isBefore(start) && !instant.isAfter(now);
}

/// Dias com State of Mind vindo do Apple Health dentro da janela.
int appleHealthSomDaysInPeriod({
  required List<RoutineSnapshot> snapshots,
  required DateTime now,
  required int periodDays,
}) {
  final days = <DateTime>{};
  for (final snapshot in snapshots) {
    if (!isWithinExportPeriod(
      instant: snapshot.savedAt,
      now: now,
      periodDays: periodDays,
    )) {
      continue;
    }
    if (snapshot.stateOfMind?.source != StateOfMindSource.appleHealth) {
      continue;
    }
    final saved = snapshot.savedAt;
    days.add(DateTime(saved.year, saved.month, saved.day));
  }
  return days.length;
}
