import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../../features/state_of_mind/domain/state_of_mind_entry.dart';
import '../../healthkit_bridge/healthkit_bridge.dart';
import '../health_app_connector.dart';
import '../health_app_source.dart';
import '../health_capability.dart';
import '../models/daily_environment_snapshot.dart';
import '../models/daily_recovery_snapshot.dart';
import '../models/health_demographics.dart';
import '../models/sleep_record.dart';
import '../plugin_health_store.dart';

/// Connector iOS via HealthKit (`package:health` + HealthKitBridge).
class AppleHealthKitConnector implements HealthAppConnector {
  AppleHealthKitConnector({PluginHealthStore? store})
      : _store = store ?? PluginHealthStore();

  final PluginHealthStore _store;

  static const Set<HealthCapability> _capabilities = {
    HealthCapability.sleep,
    HealthCapability.heartRate,
    HealthCapability.hrv,
    HealthCapability.restingHeartRate,
    HealthCapability.steps,
    HealthCapability.exercise,
    HealthCapability.demographics,
    HealthCapability.waterWrite,
    HealthCapability.mindfulnessWrite,
    HealthCapability.stateOfMind,
    HealthCapability.medications,
    HealthCapability.environment,
  };

  @override
  HealthAppSource get source => HealthAppSource.appleHealthKit;

  @override
  Set<HealthCapability> get supportedCapabilities => _capabilities;

  @override
  Future<bool> isAvailable() async => !kIsWeb && Platform.isIOS;

  @override
  Future<void> initialize() => _store.configure();

  @override
  Future<bool> requestPermissions() async {
    final granted = await _store.requestAuthorization(ios: true);
    if (granted) {
      await HealthKitBridge.requestAuthorization();
    }
    return granted;
  }

  @override
  Future<bool> hasPermissions() => _store.hasPermissions(ios: true);

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) =>
      _store.getSleepHistory(days: days);

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({
    int days = 14,
  }) async {
    final base = await _store.getRecoveryHistory(ios: true, days: days);
    return _mergeEnvironmentMetrics(base, days: days);
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

  @override
  Future<HealthDemographics> readDemographics() =>
      _store.readDemographics(ios: true);

  @override
  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) =>
      _store.writeWaterIntake(when: when, liters: liters);

  @override
  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  }) =>
      _store.writeMindfulnessIos(start: start, end: end);

  @override
  Future<bool> writeStateOfMind(StateOfMindEntry entry) =>
      HealthKitBridge.writeStateOfMind(entry);

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
  Future<bool> isMedicationsApiAvailable() =>
      HealthKitBridge.isMedicationsApiAvailable();

  @override
  Future<List<HealthKitMedicationInfo>> readMedications() =>
      HealthKitBridge.readMedications();

  @override
  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  }) =>
      HealthKitBridge.readDoseEvents(
        appleConceptId: appleConceptId,
        start: start,
        end: end,
      );

  @override
  String sourceName(AppLocalizations l10n) => l10n.healthSourceApple;

  Future<List<DailyRecoverySnapshot>> _mergeEnvironmentMetrics(
    List<DailyRecoverySnapshot> base, {
    required int days,
  }) async {
    if (!HealthKitBridge.isSupported) return base;

    final env = await getEnvironmentHistory(days: days);
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
}
