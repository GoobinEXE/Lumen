import '../../routine_mood/domain/mood_entry.dart';
import '../../routine_mood/domain/routine_export.dart';
import '../../../integrations/health/models/daily_recovery_snapshot.dart';
import '../../../integrations/health/models/sleep_record.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';

/// Agregados do período para PDF, WhatsApp e card semanal — uma fonte de verdade.
class PeriodExportStats {
  const PeriodExportStats({
    required this.avgSleepHours,
    required this.avgRemHours,
    required this.deficitNights,
    required this.sleepNights,
    required this.paralyzedCount,
    required this.hyperfocusCount,
    required this.scatteredCount,
    required this.focusedCount,
    required this.sensoryCount,
    required this.medCount,
    required this.topEmotionLabels,
    required this.avgHrv,
    required this.avgRestingHeartRate,
    required this.avgSteps,
    required this.avgExerciseMinutes,
    required this.avgDaylightMinutes,
    required this.avgNoiseDb,
    required this.somFromAppleCount,
  });

  final double avgSleepHours;
  final double avgRemHours;
  final int deficitNights;
  final int sleepNights;
  final int paralyzedCount;
  final int hyperfocusCount;
  final int scatteredCount;
  final int focusedCount;
  final int sensoryCount;
  final int medCount;
  final List<MapEntry<String, int>> topEmotionLabels;
  final double? avgHrv;
  final double? avgRestingHeartRate;
  final double? avgSteps;
  final double? avgExerciseMinutes;
  final double? avgDaylightMinutes;
  final double? avgNoiseDb;
  final int somFromAppleCount;

  factory PeriodExportStats.from({
    required List<SleepRecord> sleepRecords,
    required List<MoodEntry> moodEntries,
    List<DailyRecoverySnapshot> recoverySnapshots = const [],
    List<RoutineExportLine> routineLines = const [],
    int appleHealthSomCount = 0,
  }) {
    final sleepHours = sleepRecords.map((s) => s.totalHours).toList();
    final remHours = sleepRecords.map((s) => s.remHours).toList();

    final labelCounts = <String, int>{};
    for (final mood in moodEntries) {
      for (final id in mood.emotionLabels) {
        labelCounts[id] = (labelCounts[id] ?? 0) + 1;
      }
    }
    for (final line in routineLines) {
      final som = line.stateOfMind;
      if (som == null) continue;
      for (final id in som.labels) {
        labelCounts[id] = (labelCounts[id] ?? 0) + 1;
      }
    }
    final topLabels = labelCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final somFromApple = appleHealthSomCount +
        moodEntries
            .where(
              (m) =>
                  m.emotionSource == StateOfMindSource.appleHealth &&
                  m.emotionLabels.isNotEmpty,
            )
            .length;

    return PeriodExportStats(
      avgSleepHours: _avg(sleepHours) ?? 0.0,
      avgRemHours: _avg(remHours) ?? 0.0,
      deficitNights: sleepRecords.where((s) => s.hasSleepDeficit).length,
      sleepNights: sleepRecords.length,
      paralyzedCount:
          moodEntries.where((m) => m.focus == FocusState.paralyzed).length,
      hyperfocusCount:
          moodEntries.where((m) => m.focus == FocusState.hyperfocus).length,
      scatteredCount:
          moodEntries.where((m) => m.focus == FocusState.scattered).length,
      focusedCount:
          moodEntries.where((m) => m.focus == FocusState.focused).length,
      sensoryCount: moodEntries.where((m) => m.sensoryOverload).length,
      medCount: moodEntries.where((m) => m.tookMedication).length,
      topEmotionLabels: topLabels,
      avgHrv: _avgNullable(recoverySnapshots.map((r) => r.hrvMs)),
      avgRestingHeartRate:
          _avgNullable(recoverySnapshots.map((r) => r.restingHeartRate)),
      avgSteps: _avgNullable(recoverySnapshots.map((r) => r.steps?.toDouble())),
      avgExerciseMinutes:
          _avgNullable(recoverySnapshots.map((r) => r.exerciseMinutes)),
      avgDaylightMinutes:
          _avgNullable(recoverySnapshots.map((r) => r.timeInDaylightMinutes)),
      avgNoiseDb:
          _avgNullable(recoverySnapshots.map((r) => r.avgEnvironmentalDb)),
      somFromAppleCount: somFromApple,
    );
  }

  static double? _avg(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double? _avgNullable(Iterable<double?> values) {
    final nums = values.whereType<double>().toList();
    if (nums.isEmpty) return null;
    return nums.reduce((a, b) => a + b) / nums.length;
  }
}
