import '../../../core/time/civil_day.dart' as civil;
import '../../medications/domain/medication_log.dart';
import '../../routine_mood/domain/mood_entry.dart';
import '../../routine_mood/domain/routine_snapshot.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';
import '../../tasks/domain/task_item.dart';

/// Leitura agregada do que o Lumen guardou num dia civil — fonte local do HUD.
class DayDigest {
  const DayDigest({
    required this.day,
    required this.checkIns,
    required this.snapshots,
    required this.medicationLogs,
    required this.completedTaskTitles,
  });

  final DateTime day;
  final List<MoodEntry> checkIns;
  final List<RoutineSnapshot> snapshots;
  final List<MedicationLog> medicationLogs;
  final List<String> completedTaskTitles;

  bool get isEmpty =>
      checkIns.isEmpty &&
      snapshots.isEmpty &&
      medicationLogs.isEmpty &&
      completedTaskTitles.isEmpty;

  /// State of Mind mais recente entre os salvamentos da rotina do dia.
  StateOfMindEntry? get latestStateOfMind {
    StateOfMindEntry? newest;
    for (final snapshot in snapshots) {
      final som = snapshot.stateOfMind;
      if (som == null) continue;
      if (newest == null || som.timestamp.isAfter(newest.timestamp)) {
        newest = som;
      }
    }
    return newest;
  }

  static DateTime civilDay(DateTime value) => civil.civilDay(value);

  static bool sameCivilDay(DateTime a, DateTime b) =>
      civil.isSameCivilDay(a, b);
}

/// Tarefas concluídas que o Raio-X mostra naquele dia civil.
///
/// A chave diária (`yyyy-mm-dd`) casa com o dia. Chave de semana, quinzena ou
/// mês só entra se algum snapshot do dia listar o título do hábito — o mesmo
/// título no snapshot também puxa uma conclusão de outro período.
List<String> completedTaskTitlesForDay({
  required DateTime day,
  required Iterable<TaskItem> tasks,
  required Iterable<RoutineSnapshot> snapshots,
}) {
  final dayKey = civil.civilDayKey(day);
  final completed = <String>{};
  for (final task in tasks) {
    if (!task.active) continue;
    final key = task.completedPeriodKey;
    if (key == null || key.isEmpty) continue;
    final fromSnapshot = snapshots.any(
      (snapshot) => snapshot.completedHabits.contains(task.title),
    );
    if (key == dayKey || fromSnapshot) {
      completed.add(task.title);
    }
  }
  return completed.toList()..sort();
}
