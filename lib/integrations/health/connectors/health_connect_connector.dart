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

/// Connector genérico Android via Health Connect (`package:health`).
class HealthConnectConnector implements HealthAppConnector {
  HealthConnectConnector({PluginHealthStore? store})
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
  };

  @override
  HealthAppSource get source => HealthAppSource.healthConnect;

  @override
  Set<HealthCapability> get supportedCapabilities => _capabilities;

  @override
  Future<bool> isAvailable() async => !kIsWeb && Platform.isAndroid;

  @override
  Future<void> initialize() => _store.configure();

  @override
  Future<bool> requestPermissions() =>
      _store.requestAuthorization(ios: false);

  @override
  Future<bool> hasPermissions() => _store.hasPermissions(ios: false);

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) =>
      _store.getSleepHistory(days: days);

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({int days = 14}) =>
      _store.getRecoveryHistory(ios: false, days: days);

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({
    int days = 14,
  }) async =>
      const [];

  @override
  Future<HealthDemographics> readDemographics() =>
      _store.readDemographics(ios: false);

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
      _store.writeMindfulnessWorkout(start: start, end: end);

  @override
  Future<bool> writeStateOfMind(StateOfMindEntry entry) async => false;

  @override
  Future<List<StateOfMindEntry>> getStateOfMindHistory({int days = 14}) async =>
      const [];

  @override
  Future<bool> isMedicationsApiAvailable() async => false;

  @override
  Future<List<HealthKitMedicationInfo>> readMedications() async => const [];

  @override
  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  }) async =>
      const [];

  @override
  String sourceName(AppLocalizations l10n) => l10n.healthSourceHealthConnect;
}
