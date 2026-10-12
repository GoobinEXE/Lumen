import 'package:health/health.dart';

import 'models/daily_recovery_snapshot.dart';

/// Amostra já tirada do plugin `health`, sem o ponto cru.
class RecoverySample {
  const RecoverySample({
    required this.type,
    required this.start,
    required this.end,
    this.value,
  });

  final HealthDataType type;
  final DateTime start;
  final DateTime end;
  final num? value;
}

/// Junta amostras do dia civil em um snapshot.
///
/// HRV e FC de repouso viram média. Passos e exercício somam.
/// Dia sem número fica com o campo nulo — zero inventado contaria como dado.
List<DailyRecoverySnapshot> aggregateRecoverySamples(
  List<RecoverySample> samples,
) {
  if (samples.isEmpty) return const [];

  final byDay = <String, List<RecoverySample>>{};
  for (final sample in samples) {
    final dayKey =
        '${sample.start.year}-${sample.start.month}-${sample.start.day}';
    byDay.putIfAbsent(dayKey, () => []).add(sample);
  }

  final snapshots = <DailyRecoverySnapshot>[];
  for (final points in byDay.values) {
    final first = points.first.start;
    final day = DateTime(first.year, first.month, first.day);

    final hrvSamples = <double>[];
    final restingSamples = <double>[];
    var stepsTotal = 0.0;
    var exerciseTotal = 0.0;
    var hasSteps = false;
    var hasExercise = false;

    for (final sample in points) {
      if (sample.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN ||
          sample.type == HealthDataType.HEART_RATE_VARIABILITY_RMSSD) {
        final hrv = sample.value;
        if (hrv != null) hrvSamples.add(hrv.toDouble());
      } else if (sample.type == HealthDataType.RESTING_HEART_RATE) {
        final rhr = sample.value;
        if (rhr != null) restingSamples.add(rhr.toDouble());
      } else if (sample.type == HealthDataType.STEPS) {
        final steps = sample.value;
        if (steps != null) {
          stepsTotal += steps.toDouble();
          hasSteps = true;
        }
      } else if (sample.type == HealthDataType.EXERCISE_TIME) {
        final exercise = sample.value;
        if (exercise != null) {
          exerciseTotal += exercise.toDouble();
          hasExercise = true;
        }
      } else if (sample.type == HealthDataType.WORKOUT) {
        final minutes = sample.end.difference(sample.start).inSeconds / 60.0;
        if (minutes > 0) {
          exerciseTotal += minutes;
          hasExercise = true;
        }
      }
    }

    snapshots.add(
      DailyRecoverySnapshot(
        date: day,
        hrvMs: hrvSamples.isEmpty
            ? null
            : hrvSamples.reduce((a, b) => a + b) / hrvSamples.length,
        restingHeartRate: restingSamples.isEmpty
            ? null
            : restingSamples.reduce((a, b) => a + b) / restingSamples.length,
        steps: hasSteps ? stepsTotal.round() : null,
        exerciseMinutes: hasExercise ? exerciseTotal : null,
      ),
    );
  }

  snapshots.sort((a, b) => b.date.compareTo(a.date));
  return snapshots;
}
