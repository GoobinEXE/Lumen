import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'models/daily_recovery_snapshot.dart';
import 'models/health_demographics.dart';
import 'models/sleep_night.dart';
import 'models/sleep_record.dart';

/// Cliente compartilhado do plugin `health` (HealthKit no iOS, Health Connect no Android).
class PluginHealthStore {
  PluginHealthStore({Health? health}) : _health = health ?? Health();

  final Health _health;

  static const List<HealthDataType> sleepReadTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.HEART_RATE,
  ];

  static List<HealthDataType> recoveryReadTypes({required bool ios}) {
    if (kIsWeb) return const [];
    if (ios) {
      return const [
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.EXERCISE_TIME,
      ];
    }
    return const [
      HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.WORKOUT,
    ];
  }

  static List<HealthDataType> demographicsReadTypes({required bool ios}) {
    if (kIsWeb) return const [];
    if (ios) {
      return const [
        HealthDataType.HEIGHT,
        HealthDataType.WEIGHT,
        HealthDataType.GENDER,
        HealthDataType.BIRTH_DATE,
      ];
    }
    return const [HealthDataType.HEIGHT, HealthDataType.WEIGHT];
  }

  static List<HealthDataType> writeTypes({required bool ios}) {
    if (kIsWeb) return const [];
    if (ios) {
      return const [HealthDataType.WATER, HealthDataType.MINDFULNESS];
    }
    return const [HealthDataType.WATER, HealthDataType.WORKOUT];
  }

  List<HealthDataType> allTypes({required bool ios}) => [
        ...sleepReadTypes,
        ...recoveryReadTypes(ios: ios),
        ...demographicsReadTypes(ios: ios),
        ...writeTypes(ios: ios),
      ];

  List<HealthDataAccess> allPermissions({required bool ios}) {
    final reads = [
      ...sleepReadTypes,
      ...recoveryReadTypes(ios: ios),
      ...demographicsReadTypes(ios: ios),
    ];
    final writes = writeTypes(ios: ios);
    return [
      ...reads.map((_) => HealthDataAccess.READ),
      ...writes.map((_) => HealthDataAccess.READ_WRITE),
    ];
  }

  bool get isMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  Future<void> configure() async {
    if (!isMobile) return;
    try {
      await _health.configure();
    } catch (e) {
      debugPrint('[PluginHealthStore] Falha ao configurar: $e');
    }
  }

  Future<bool> requestAuthorization({required bool ios}) async {
    if (!isMobile) return false;
    try {
      return await _health.requestAuthorization(
        allTypes(ios: ios),
        permissions: allPermissions(ios: ios),
      );
    } catch (e) {
      debugPrint('[PluginHealthStore] Erro ao solicitar permissões: $e');
      return false;
    }
  }

  Future<bool> hasPermissions({required bool ios}) async {
    if (!isMobile) return false;
    try {
      final has = await _health.hasPermissions(
        allTypes(ios: ios),
        permissions: allPermissions(ios: ios),
      );
      return has ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) async {
    if (!isMobile || liters <= 0) return false;
    try {
      return await _health.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        unit: HealthDataUnit.LITER,
        startTime: when,
        endTime: when,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('[PluginHealthStore] Erro ao escrever água: $e');
      return false;
    }
  }

  Future<bool> writeMindfulnessIos({
    required DateTime start,
    required DateTime end,
  }) async {
    if (kIsWeb || !Platform.isIOS || !end.isAfter(start)) return false;
    try {
      final minutes =
          end.difference(start).inMinutes.toDouble().clamp(1.0, 120.0);
      return await _health.writeHealthData(
        value: minutes,
        type: HealthDataType.MINDFULNESS,
        unit: HealthDataUnit.MINUTE,
        startTime: start,
        endTime: end,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('[PluginHealthStore] Erro ao escrever mindfulness: $e');
      return false;
    }
  }

  /// Health Connect não tem MindfulnessRecord — grava sessão de exercício
  /// (yoga / atenção plena) conforme alternativa da matriz GDD §9.2.
  Future<bool> writeMindfulnessWorkout({
    required DateTime start,
    required DateTime end,
  }) async {
    if (kIsWeb || !Platform.isAndroid || !end.isAfter(start)) return false;
    try {
      return await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.YOGA,
        start: start,
        end: end,
        title: 'Mindfulness',
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('[PluginHealthStore] Erro ao escrever mindfulness (workout): $e');
      return false;
    }
  }

  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async {
    if (!isMobile) return [];
    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: days + 1));
      final healthData = await _health.getHealthDataFromTypes(
        types: sleepReadTypes,
        startTime: startTime,
        endTime: now,
      );
      if (healthData.isEmpty) return [];

      final intervals = <SleepInterval>[];
      for (final point in healthData) {
        final kind = _sleepKind(point.type);
        if (kind == null) continue;
        intervals.add(
          SleepInterval(kind: kind, start: point.dateFrom, end: point.dateTo),
        );
      }

      final nights = SleepNight.aggregate(intervals);
      return [
        for (final night in nights)
          SleepRecord(
            date: night.date,
            bedtime: night.bedtime,
            wakeTime: night.wakeTime,
            totalSleep: night.totalSleep,
            deepSleep: night.deepSleep,
            remSleep: night.remSleep,
            lightSleep: night.lightSleep,
            awakeDuration: night.awakeDuration,
            averageHeartRate: _averageNumericInRange(
              healthData,
              HealthDataType.HEART_RATE,
              night.bedtime,
              night.wakeTime,
            )?.round(),
          ),
      ];
    } catch (e) {
      debugPrint('[PluginHealthStore] Erro ao consultar sono: $e');
      return [];
    }
  }

  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({
    required bool ios,
    int days = 14,
  }) async {
    final types = recoveryReadTypes(ios: ios);
    if (!isMobile || types.isEmpty) return [];

    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: days));
      final healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: now,
      );

      final snapshots = <DailyRecoverySnapshot>[];
      if (healthData.isNotEmpty) {
        final byDay = <String, List<HealthDataPoint>>{};
        for (final point in healthData) {
          final dayKey =
              '${point.dateFrom.year}-${point.dateFrom.month}-${point.dateFrom.day}';
          byDay.putIfAbsent(dayKey, () => []).add(point);
        }

        for (final entry in byDay.entries) {
          final points = entry.value;
          final first = points.first.dateFrom;
          final day = DateTime(first.year, first.month, first.day);

          final hrvSamples = <double>[];
          final restingSamples = <double>[];
          var stepsTotal = 0.0;
          var exerciseTotal = 0.0;
          var hasSteps = false;
          var hasExercise = false;

          for (final p in points) {
            if (p.type == HealthDataType.HEART_RATE_VARIABILITY_SDNN ||
                p.type == HealthDataType.HEART_RATE_VARIABILITY_RMSSD) {
              final hrv = _numericOf(p);
              if (hrv != null) hrvSamples.add(hrv.toDouble());
            } else if (p.type == HealthDataType.RESTING_HEART_RATE) {
              final rhr = _numericOf(p);
              if (rhr != null) restingSamples.add(rhr.toDouble());
            } else if (p.type == HealthDataType.STEPS) {
              final steps = _numericOf(p);
              if (steps != null) {
                stepsTotal += steps.toDouble();
                hasSteps = true;
              }
            } else if (p.type == HealthDataType.EXERCISE_TIME) {
              final exercise = _numericOf(p);
              if (exercise != null) {
                exerciseTotal += exercise.toDouble();
                hasExercise = true;
              }
            } else if (p.type == HealthDataType.WORKOUT) {
              final minutes =
                  p.dateTo.difference(p.dateFrom).inSeconds / 60.0;
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
                  : restingSamples.reduce((a, b) => a + b) /
                      restingSamples.length,
              steps: hasSteps ? stepsTotal.round() : null,
              exerciseMinutes: hasExercise ? exerciseTotal : null,
            ),
          );
        }
      }

      snapshots.sort((a, b) => b.date.compareTo(a.date));
      return snapshots;
    } catch (e) {
      debugPrint('[PluginHealthStore] Erro ao consultar recuperação: $e');
      return [];
    }
  }

  Future<HealthDemographics> readDemographics({required bool ios}) async {
    final types = demographicsReadTypes(ios: ios);
    if (!isMobile || types.isEmpty) return HealthDemographics.empty;

    try {
      final now = DateTime.now();
      final points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: now.subtract(const Duration(days: 365 * 5)),
        endTime: now,
      );
      if (points.isEmpty) return HealthDemographics.empty;

      final height = _latestPoint(points, HealthDataType.HEIGHT);
      final weight = _latestPoint(points, HealthDataType.WEIGHT);
      final gender = _latestPoint(points, HealthDataType.GENDER);
      final birth = _latestPoint(points, HealthDataType.BIRTH_DATE);

      return HealthDemographics(
        heightCm: height == null
            ? null
            : HealthDemographics.heightToCm(
                _numericOf(height),
                height.unit.name,
              ),
        weightKg: weight == null
            ? null
            : HealthDemographics.weightToKg(
                _numericOf(weight),
                weight.unit.name,
              ),
        biologicalSex: HealthDemographics.sexFromHealthKitRawValue(
          gender == null ? null : _numericOf(gender),
        ),
        birthDate: HealthDemographics.birthDateFromEpochSeconds(
          birth == null ? null : _numericOf(birth),
        ),
      );
    } catch (e) {
      debugPrint('[PluginHealthStore] Erro ao consultar demografia: $e');
      return HealthDemographics.empty;
    }
  }

  HealthDataPoint? _latestPoint(
    List<HealthDataPoint> points,
    HealthDataType type,
  ) {
    HealthDataPoint? latest;
    for (final point in points) {
      if (point.type != type) continue;
      if (latest == null || point.dateFrom.isAfter(latest.dateFrom)) {
        latest = point;
      }
    }
    return latest;
  }

  num? _numericOf(HealthDataPoint point) {
    final value = point.value;
    return value is NumericHealthValue ? value.numericValue : null;
  }

  SleepIntervalKind? _sleepKind(HealthDataType type) {
    switch (type) {
      case HealthDataType.SLEEP_DEEP:
        return SleepIntervalKind.deep;
      case HealthDataType.SLEEP_REM:
        return SleepIntervalKind.rem;
      case HealthDataType.SLEEP_LIGHT:
        return SleepIntervalKind.light;
      case HealthDataType.SLEEP_ASLEEP:
        return SleepIntervalKind.asleep;
      case HealthDataType.SLEEP_AWAKE:
        return SleepIntervalKind.awake;
      default:
        return null;
    }
  }

  double? _averageNumericInRange(
    List<HealthDataPoint> allPoints,
    HealthDataType type,
    DateTime start,
    DateTime end,
  ) {
    final samples = <double>[];
    for (final p in allPoints) {
      if (p.type != type) continue;
      if (p.dateFrom.isBefore(start) || p.dateFrom.isAfter(end)) continue;
      final value = p.value;
      if (value is NumericHealthValue) {
        samples.add(value.numericValue.toDouble());
      }
    }
    if (samples.isEmpty) return null;
    return samples.reduce((a, b) => a + b) / samples.length;
  }
}
