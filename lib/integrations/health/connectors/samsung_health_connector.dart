import 'package:noa/l10n/app_localizations.dart';

import '../../../features/state_of_mind/domain/state_of_mind_entry.dart';
import '../../healthkit_bridge/healthkit_bridge.dart';
import '../../samsung_health_bridge/samsung_health_bridge.dart';
import '../health_app_connector.dart';
import '../health_app_source.dart';
import '../health_capability.dart';
import '../models/daily_environment_snapshot.dart';
import '../models/daily_recovery_snapshot.dart';
import '../models/health_demographics.dart';
import '../models/sleep_record.dart';

/// Connector Samsung Health Data SDK.
///
/// Declara as capabilities do GDD cobertas pelo Data SDK. HRV e outros gaps
/// ficam de fora de [supportedCapabilities] para o facade cair no Health Connect.
class SamsungHealthConnector implements HealthAppConnector {
  SamsungHealthConnector({SamsungHealthBridge? bridge})
      : _bridge = bridge ?? SamsungHealthBridge();

  final SamsungHealthBridge _bridge;

  bool _sdkReady = false;

  static const Set<HealthCapability> _capabilities = {
    HealthCapability.sleep,
    HealthCapability.heartRate,
    HealthCapability.restingHeartRate,
    HealthCapability.steps,
    HealthCapability.exercise,
    HealthCapability.demographics,
    HealthCapability.waterWrite,
    HealthCapability.mindfulnessWrite,
  };

  @override
  HealthAppSource get source => HealthAppSource.samsungHealth;

  @override
  Set<HealthCapability> get supportedCapabilities {
    if (!_sdkReady) return const {};
    return _capabilities;
  }

  @override
  Future<bool> isAvailable() => _bridge.isAvailable();

  @override
  Future<void> initialize() async {
    final linked = await _bridge.isSdkLinked();
    if (!linked) {
      _sdkReady = false;
      return;
    }
    _sdkReady = await _bridge.connect();
  }

  @override
  Future<bool> requestPermissions() async {
    if (!_sdkReady) {
      await initialize();
    }
    if (!_sdkReady) return false;
    return _bridge.requestPermissions();
  }

  @override
  Future<bool> hasPermissions() async {
    if (!_sdkReady) return false;
    return _bridge.hasPermissions();
  }

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async {
    if (!_sdkReady) return const [];
    return _bridge.readSleep(days: days);
  }

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({
    int days = 14,
  }) async {
    if (!_sdkReady) return const [];
    return _bridge.readRecovery(days: days);
  }

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({
    int days = 14,
  }) async =>
      const [];

  @override
  Future<HealthDemographics> readDemographics() async {
    if (!_sdkReady) return HealthDemographics.empty;
    return _bridge.readDemographics();
  }

  @override
  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) async {
    if (!_sdkReady) return false;
    return _bridge.writeWater(when: when, liters: liters);
  }

  @override
  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!_sdkReady) return false;
    return _bridge.writeMindfulnessExercise(start: start, end: end);
  }

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
  String sourceName(AppLocalizations l10n) => l10n.healthSourceSamsung;
}
