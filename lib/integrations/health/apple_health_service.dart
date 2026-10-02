import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:noa/l10n/app_localizations.dart';
import '../healthkit_bridge/healthkit_bridge.dart';
import 'health_service.dart';
import 'models/daily_environment_snapshot.dart';
import 'models/daily_recovery_snapshot.dart';
import 'models/sleep_night.dart';
import 'models/sleep_record.dart';
import '../../features/state_of_mind/domain/state_of_mind_entry.dart';

/// Implementação do serviço de saúde conectado nativamente ao
/// Apple Health (iOS HealthKit) e Health Connect (Android).
class AppleHealthService implements HealthService {
  final Health _health = Health();

  static const List<HealthDataType> _sleepReadTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.HEART_RATE,
  ];

  static List<HealthDataType> get _recoveryReadTypes {
    if (kIsWeb) return const [];
    if (Platform.isIOS) {
      return const [
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.EXERCISE_TIME,
      ];
    }
    if (Platform.isAndroid) {
      return const [
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.STEPS,
      ];
    }
    return const [];
  }

  static List<HealthDataType> get _writeTypes {
    if (kIsWeb) return const [];
    if (Platform.isIOS) {
      return const [HealthDataType.WATER, HealthDataType.MINDFULNESS];
    }
    if (Platform.isAndroid) {
      return const [HealthDataType.WATER];
    }
    return const [];
  }

  static List<HealthDataType> get _readTypes => [
    ..._sleepReadTypes,
    ..._recoveryReadTypes,
  ];

  static List<HealthDataType> get _allTypes => [..._readTypes, ..._writeTypes];

  static List<HealthDataAccess> get _allPermissions => [
    ..._readTypes.map((_) => HealthDataAccess.READ),
    ..._writeTypes.map((_) => HealthDataAccess.READ_WRITE),
  ];

  bool get _isMobileHealthPlatform =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  @override
  String sourceName(AppLocalizations l10n) {
    if (kIsWeb) return l10n.healthSourceUnavailable;
    if (Platform.isIOS) return l10n.healthSourceApple;
    if (Platform.isAndroid) return l10n.healthSourceAndroid;
    return l10n.healthSourceUnavailable;
  }

  @override
  Future<void> initialize() async {
    if (!_isMobileHealthPlatform) return;
    try {
      await _health.configure();
    } catch (e) {
      debugPrint('[HealthService] Falha ao configurar Health plugin: $e');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_isMobileHealthPlatform) return false;

    try {
      final granted = await _health.requestAuthorization(
        _allTypes,
        permissions: _allPermissions,
      );
      if (granted) {
        await HealthKitBridge.requestAuthorization();
      }
      return granted;
    } catch (e) {
      debugPrint('[HealthService] Erro ao solicitar permissões HealthKit: $e');
      return false;
    }
  }

  @override
  Future<bool> hasPermissions() async {
    if (!_isMobileHealthPlatform) return false;

    try {
      final has = await _health.hasPermissions(
        _allTypes,
        permissions: _allPermissions,
      );
      return has ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<SleepRecord>> syncFromHealth({int days = 14}) async {
    await initialize();
    final granted = await requestPermissions();
    if (!granted) return [];
    return getSleepHistory(days: days);
  }

  @override
  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) async {
    if (!_isMobileHealthPlatform || liters <= 0) return false;

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
      debugPrint('[HealthService] Erro ao escrever água: $e');
      return false;
    }
  }

  @override
  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  }) async {
    // Mindfulness write é suportado de forma confiável no HealthKit (iOS).
    if (kIsWeb || !Platform.isIOS) return false;
    if (!end.isAfter(start)) return false;

    try {
      final minutes = end
          .difference(start)
          .inMinutes
          .toDouble()
          .clamp(1.0, 120.0);
      return await _health.writeHealthData(
        value: minutes,
        type: HealthDataType.MINDFULNESS,
        unit: HealthDataUnit.MINUTE,
        startTime: start,
        endTime: end,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('[HealthService] Erro ao escrever mindfulness: $e');
      return false;
    }
  }

  @override
  Future<SleepRecord?> getLastNightSleep() async {
    final history = await getSleepHistory(days: 1);
    return history.isNotEmpty ? history.first : null;
  }

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async {
    if (!_isMobileHealthPlatform) {
      return [];
    }

    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: days + 1));

      final healthData = await _health.getHealthDataFromTypes(
        types: _sleepReadTypes,
        startTime: startTime,
        endTime: now,
      );

      if (healthData.isEmpty) {
        return [];
      }

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
      debugPrint('[HealthService] Erro ao consultar dados de sono: $e');
      return [];
    }
  }

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({
    int days = 14,
  }) async {
    if (!_isMobileHealthPlatform || _recoveryReadTypes.isEmpty) {
      return [];
    }

    try {
      final now = DateTime.now();
      final startTime = now.subtract(Duration(days: days));

      final healthData = await _health.getHealthDataFromTypes(
        types: _recoveryReadTypes,
        startTime: startTime,
        endTime: now,
      );

      final snapshots = <DailyRecoverySnapshot>[];

      if (healthData.isNotEmpty) {
        final Map<String, List<HealthDataPoint>> byDay = {};
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
            final value = p.value;
            if (value is! NumericHealthValue) continue;
            final n = value.numericValue.toDouble();

            switch (p.type) {
              case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
              case HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
                hrvSamples.add(n);
                break;
              case HealthDataType.RESTING_HEART_RATE:
                restingSamples.add(n);
                break;
              case HealthDataType.STEPS:
                stepsTotal += n;
                hasSteps = true;
                break;
              case HealthDataType.EXERCISE_TIME:
                exerciseTotal += n;
                hasExercise = true;
                break;
              default:
                break;
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
      return _mergeEnvironmentMetrics(snapshots, startTime, now);
    } catch (e) {
      debugPrint('[HealthService] Erro ao consultar recuperação: $e');
      return [];
    }
  }

  @override
  Future<bool> isMedicationsApiAvailable() {
    return HealthKitBridge.isMedicationsApiAvailable();
  }

  @override
  Future<List<HealthKitMedicationInfo>> readMedications() {
    return HealthKitBridge.readMedications();
  }

  @override
  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  }) {
    return HealthKitBridge.readDoseEvents(
      appleConceptId: appleConceptId,
      start: start,
      end: end,
    );
  }

  @override
  Future<bool> writeStateOfMind(StateOfMindEntry entry) {
    return HealthKitBridge.writeStateOfMind(entry);
  }

  @override
  Future<List<StateOfMindEntry>> getStateOfMindHistory({int days = 14}) async {
    if (!HealthKitBridge.isSupported) return const [];
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final samples = await HealthKitBridge.readStateOfMind(
      start: start,
      end: end,
    );
    return samples
        .map((e) => e.copyWith(source: StateOfMindSource.appleHealth))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({
    int days = 14,
  }) async {
    if (!HealthKitBridge.isSupported) return const [];

    final end = DateTime.now();
    final start = DateTime(
      end.year,
      end.month,
      end.day,
    ).subtract(Duration(days: days - 1));

    final daylight = await HealthKitBridge.readTimeInDaylight(
      start: start,
      end: end,
    );
    final envAudio = await HealthKitBridge.readEnvironmentalAudio(
      start: start,
      end: end,
    );
    final headphone = await HealthKitBridge.readHeadphoneAudio(
      start: start,
      end: end,
    );

    final keys = {...daylight.keys, ...envAudio.keys, ...headphone.keys};
    if (keys.isEmpty) return const [];

    final snapshots = <DailyEnvironmentSnapshot>[];
    for (final key in keys) {
      final parts = key.split('-');
      if (parts.length != 3) continue;
      snapshots.add(
        DailyEnvironmentSnapshot(
          date: DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          ),
          daylightMinutes: daylight[key],
          envAudioDb: envAudio[key],
          headphoneAudioDb: headphone[key],
        ),
      );
    }
    snapshots.sort((a, b) => b.date.compareTo(a.date));
    return snapshots;
  }

  Future<List<DailyRecoverySnapshot>> _mergeEnvironmentMetrics(
    List<DailyRecoverySnapshot> base,
    DateTime start,
    DateTime end,
  ) async {
    if (!HealthKitBridge.isSupported) return base;

    final env = await getEnvironmentHistory(
      days: end.difference(start).inDays + 1,
    );
    if (env.isEmpty) return base;

    String dayKey(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final byKey = {for (final s in base) dayKey(s.date): s};

    for (final e in env) {
      final key = dayKey(e.date);
      final existing = byKey[key];
      byKey[key] = (existing ?? DailyRecoverySnapshot(date: e.date)).copyWith(
        timeInDaylightMinutes: e.daylightMinutes,
        avgEnvironmentalDb: e.envAudioDb,
        avgHeadphoneDb: e.headphoneAudioDb,
      );
    }

    final merged = byKey.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return merged;
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
