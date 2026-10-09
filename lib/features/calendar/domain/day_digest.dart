import '../../../core/time/civil_day.dart' as civil;
import '../../medications/domain/medication_log.dart';
import '../../routine_mood/domain/mood_entry.dart';
import '../../routine_mood/domain/routine_snapshot.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';

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
