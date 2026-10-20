import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/facade_health_service.dart';
import 'package:noa/integrations/health/health_app_connector.dart';
import 'package:noa/integrations/health/health_app_source.dart';
import 'package:noa/integrations/health/health_capability.dart';
import 'package:noa/integrations/health/health_connector_selector.dart';
import 'package:noa/integrations/health/models/daily_environment_snapshot.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/health_demographics.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:noa/l10n/app_localizations_pt.dart';

void main() {
  final l10n = AppLocalizationsPt();

  test('demografia parcial do primary não puxa o que falta no fallback', () async {
    final primary = _FakeConnector(
      source: HealthAppSource.samsungHealth,
      capabilities: const {HealthCapability.demographics},
      demographics: const HealthDemographics(heightCm: 180),
    );
    final fallback = _FakeConnector(
      source: HealthAppSource.healthConnect,
      capabilities: const {HealthCapability.demographics},
      demographics: HealthDemographics(
        weightKg: 70,
        birthDate: DateTime(1990, 4, 2),
      ),
    );
    final service = FacadeHealthService(
      selector: _FixedSelector(
        SelectedHealthConnectors(primary: primary, fallback: fallback),
      ),
    );

    final read = await service.readDemographics();

    expect(read.heightCm, 180);
    expect(read.weightKg, isNull);
    expect(read.birthDate, isNull);
    expect(fallback.demographicsReads, 0);
  });

  test('Samsung sem sono ainda se apresenta como Samsung Health', () async {
    final primary = _FakeConnector(
      source: HealthAppSource.samsungHealth,
      capabilities: const {},
    );
    final fallback = _FakeConnector(
      source: HealthAppSource.healthConnect,
      capabilities: const {HealthCapability.sleep},
    );
    final service = FacadeHealthService(
      selector: _FixedSelector(
        SelectedHealthConnectors(primary: primary, fallback: fallback),
      ),
    );

    expect(service.sourceName(l10n), l10n.healthSourceUnavailable);

    await service.initialize();

    expect(service.sourceName(l10n), l10n.healthSourceSamsung);
    expect(service.sourceName(l10n), isNot(primary.sourceName(l10n)));
  });

  test('a última noite é o primeiro item e a lista vazia não inventa sono', () async {
    final older = _night(DateTime(2026, 10, 18, 7));
    final newer = _night(DateTime(2026, 10, 20, 7));
    final primary = _FakeConnector(
      source: HealthAppSource.healthConnect,
      capabilities: const {HealthCapability.sleep},
      sleep: [older, newer],
    );
    final service = FacadeHealthService(
      selector: _FixedSelector(
        SelectedHealthConnectors(primary: primary),
      ),
    );

    final night = await service.getLastNightSleep();

    expect(primary.sleepDays, 1);
    expect(night?.wakeTime, older.wakeTime);

    final empty = _FakeConnector(
      source: HealthAppSource.healthConnect,
      capabilities: const {HealthCapability.sleep},
    );
    final emptyService = FacadeHealthService(
      selector: _FixedSelector(SelectedHealthConnectors(primary: empty)),
    );
    expect(await emptyService.getLastNightSleep(), isNull);
    expect(empty.sleepDays, 1);
  });

  test('State of Mind só escreve no connector que declara a capability', () async {
    final entry = StateOfMindEntry(timestamp: DateTime(2026, 10, 20, 9));
    final primary = _FakeConnector(
      source: HealthAppSource.samsungHealth,
      capabilities: const {HealthCapability.sleep},
    );
    final fallback = _FakeConnector(
      source: HealthAppSource.appleHealthKit,
      capabilities: const {HealthCapability.stateOfMind},
    );
    final service = FacadeHealthService(
      selector: _FixedSelector(
        SelectedHealthConnectors(primary: primary, fallback: fallback),
      ),
    );

    expect(await service.writeStateOfMind(entry), isTrue);
    expect(primary.stateOfMindWrites, 0);
    expect(fallback.stateOfMindWrites, 1);

    final localOnly = _FakeConnector(
      source: HealthAppSource.samsungHealth,
      capabilities: const {},
    );
    final healthConnect = _FakeConnector(
      source: HealthAppSource.healthConnect,
      capabilities: const {HealthCapability.sleep},
    );
    final android = FacadeHealthService(
      selector: _FixedSelector(
        SelectedHealthConnectors(primary: localOnly, fallback: healthConnect),
      ),
    );

    expect(await android.writeStateOfMind(entry), isFalse);
    expect(localOnly.stateOfMindWrites, 1);
    expect(healthConnect.stateOfMindWrites, 0);
  });
}

SleepRecord _night(DateTime wake) {
  return SleepRecord(
    date: DateTime(wake.year, wake.month, wake.day),
    bedtime: wake.subtract(const Duration(hours: 8)),
    wakeTime: wake,
    totalSleep: const Duration(hours: 8),
  );
}

class _FixedSelector extends HealthConnectorSelector {
  _FixedSelector(this.selected);

  final SelectedHealthConnectors selected;

  @override
  Future<SelectedHealthConnectors> resolve() async => selected;
}

class _FakeConnector implements HealthAppConnector {
  _FakeConnector({
    required this.source,
    required Set<HealthCapability> capabilities,
    this.sleep = const [],
    this.demographics = HealthDemographics.empty,
  }) : supportedCapabilities = capabilities;

  @override
  final HealthAppSource source;

  @override
  final Set<HealthCapability> supportedCapabilities;

  final List<SleepRecord> sleep;
  final HealthDemographics demographics;

  int? sleepDays;
  int demographicsReads = 0;
  int stateOfMindWrites = 0;

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({
    int days = 14,
  }) async =>
      const [];

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({
    int days = 14,
  }) async =>
      const [];

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async {
    sleepDays = days;
    return sleep;
  }

  @override
  Future<List<StateOfMindEntry>> getStateOfMindHistory({int days = 14}) async =>
      const [];

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> isMedicationsApiAvailable() async => false;

  @override
  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  }) async =>
      const [];

  @override
  Future<HealthDemographics> readDemographics() async {
    demographicsReads++;
    return demographics;
  }

  @override
  Future<List<HealthKitMedicationInfo>> readMedications() async => const [];

  @override
  Future<bool> requestPermissions() async => true;

  @override
  String sourceName(AppLocalizations l10n) => 'conector-${source.name}';

  @override
  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  }) async =>
      false;

  @override
  Future<bool> writeStateOfMind(StateOfMindEntry entry) async {
    stateOfMindWrites++;
    return supports(HealthCapability.stateOfMind);
  }

  @override
  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) async =>
      false;
}
