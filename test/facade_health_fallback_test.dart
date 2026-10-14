import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
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
import 'package:noa/l10n/app_localizations.dart';

void main() {
  group('FacadeHealthService recuperação', () {
    test('preenche lacuna do fallback e não troca o que o primary já tem', () async {
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {
          HealthCapability.sleep,
          HealthCapability.steps,
          HealthCapability.hrv,
        },
        recovery: [
          DailyRecoverySnapshot(
            date: DateTime(2026, 10, 4),
            hrvMs: 50,
            steps: 0,
          ),
          DailyRecoverySnapshot(
            date: DateTime(2026, 10, 2),
            hrvMs: 30,
            steps: 1000,
          ),
        ],
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {
          HealthCapability.hrv,
          HealthCapability.restingHeartRate,
          HealthCapability.steps,
          HealthCapability.exercise,
        },
        recovery: [
          DailyRecoverySnapshot(
            date: DateTime(2026, 10, 4),
            hrvMs: 10,
            restingHeartRate: 62,
            steps: 8000,
            exerciseMinutes: 20,
          ),
          DailyRecoverySnapshot(
            date: DateTime(2026, 10, 3),
            hrvMs: 44,
            steps: 5000,
          ),
        ],
      );

      final merged = await _service(primary, fallback).getRecoveryHistory();

      expect(primary.recoveryReads, 1);
      expect(fallback.recoveryReads, 1);
      expect(merged.map((s) => s.date), [
        DateTime(2026, 10, 4),
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 2),
      ]);

      final newest = merged[0];
      expect(newest.hrvMs, 50);
      expect(newest.steps, 0);
      expect(newest.restingHeartRate, 62);
      expect(newest.exerciseMinutes, 20);

      expect(merged[1].hrvMs, 44);
      expect(merged[1].steps, 5000);
      expect(merged[2].hrvMs, 30);
      expect(merged[2].steps, 1000);
    });

    test('lista vazia de um lado devolve a do outro', () async {
      final onlyFallback = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.steps},
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.hrv},
        recovery: [
          DailyRecoverySnapshot(date: DateTime(2026, 10, 1), hrvMs: 41),
        ],
      );

      final fromFallback =
          await _service(onlyFallback, fallback).getRecoveryHistory();
      expect(fromFallback, hasLength(1));
      expect(fromFallback.single.hrvMs, 41);

      final onlyPrimary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.steps},
        recovery: [
          DailyRecoverySnapshot(date: DateTime(2026, 10, 1), steps: 1200),
        ],
      );
      final emptyFallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.hrv},
      );
      final fromPrimary =
          await _service(onlyPrimary, emptyFallback).getRecoveryHistory();
      expect(fromPrimary, hasLength(1));
      expect(fromPrimary.single.steps, 1200);
      expect(emptyFallback.recoveryReads, 1);
    });
  });

  group('FacadeHealthService sono e escrita', () {
    test('sono do primary dispensa o fallback', () async {
      final night = _night(DateTime(2026, 10, 4));
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.sleep},
        sleep: [night],
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.sleep},
        sleep: [_night(DateTime(2026, 10, 3))],
      );

      final history = await _service(primary, fallback).getSleepHistory();
      final last = await _service(primary, fallback).getLastNightSleep();

      expect(history, [night]);
      expect(fallback.sleepReads, 0);
      expect(last?.date, night.date);
    });

    test('sono vazio no primary cai no fallback uma vez', () async {
      final night = _night(DateTime(2026, 10, 3));
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.sleep},
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.sleep},
        sleep: [night],
      );

      final history = await _service(primary, fallback).getSleepHistory();

      expect(history, [night]);
      expect(primary.sleepReads, 1);
      expect(fallback.sleepReads, 1);
    });

    test('primary sem a capability de sono lê só o fallback', () async {
      final night = _night(DateTime(2026, 10, 2));
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.steps},
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.sleep},
        sleep: [night],
      );

      final history = await _service(primary, fallback).getSleepHistory();

      expect(history, [night]);
      expect(primary.sleepReads, 0);
      expect(fallback.sleepReads, 1);
    });

    test('água que falha no primary tenta o fallback e não escreve duas vezes se der certo', () async {
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.waterWrite},
        waterOk: false,
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.waterWrite},
      );
      final when = DateTime(2026, 10, 4, 9);

      final failed = await _service(primary, fallback).writeWaterIntake(
        when: when,
        liters: 0.25,
      );

      expect(failed, isTrue);
      expect(primary.waterWrites, 1);
      expect(fallback.waterWrites, 1);

      primary.waterOk = true;
      primary.waterWrites = 0;
      fallback.waterWrites = 0;
      final ok = await _service(primary, fallback).writeWaterIntake(
        when: when,
        liters: 0.25,
      );
      expect(ok, isTrue);
      expect(primary.waterWrites, 1);
      expect(fallback.waterWrites, 0);
    });

    test('primary sem escrita de água usa só o fallback', () async {
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.steps},
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.waterWrite},
      );

      final ok = await _service(primary, fallback).writeWaterIntake(
        when: DateTime(2026, 10, 4, 9),
        liters: 0.25,
      );

      expect(ok, isTrue);
      expect(primary.waterWrites, 0);
      expect(fallback.waterWrites, 1);
    });

    test('mindfulness segue o mesmo fallback da água', () async {
      final start = DateTime(2026, 10, 4, 9);
      final end = start.add(const Duration(minutes: 3));
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.mindfulnessWrite},
        mindOk: false,
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.mindfulnessWrite},
      );

      final ok = await _service(primary, fallback).writeMindfulnessSession(
        start: start,
        end: end,
      );

      expect(ok, isTrue);
      expect(primary.mindWrites, 1);
      expect(fallback.mindWrites, 1);
    });
  });

  group('FacadeHealthService permissão e demografia', () {
    test('primary negado usa a permissão do fallback', () async {
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.sleep},
        permissionGranted: false,
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.sleep},
      );

      final granted = await _service(primary, fallback).requestPermissions();

      expect(granted, isTrue);
      expect(primary.permissionRequests, 1);
      expect(fallback.permissionRequests, 1);
      expect(primary.initializes, 1);
      expect(fallback.initializes, 1);
    });

    test('Samsung autorizado também pede permissão no fallback', () async {
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.sleep},
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.hrv},
      );

      final granted = await _service(primary, fallback).requestPermissions();

      expect(granted, isTrue);
      expect(fallback.permissionRequests, 1);
    });

    test('Health Connect autorizado não pede o fallback de novo', () async {
      final primary = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.sleep},
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.sleep},
      );

      final granted = await _service(primary, fallback).requestPermissions();

      expect(granted, isTrue);
      expect(primary.permissionRequests, 1);
      expect(fallback.permissionRequests, 0);
    });

    test('permissão já concedida no primary não consulta o fallback', () async {
      final primary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.sleep},
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.sleep},
        permissionGranted: false,
      );

      final granted = await _service(primary, fallback).hasPermissions();

      expect(granted, isTrue);
      expect(primary.permissionChecks, 1);
      expect(fallback.permissionChecks, 0);
    });

    test('sem permissão o sync não inventa noite', () async {
      final primary = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.sleep},
        permissionGranted: false,
        sleep: [_night(DateTime(2026, 10, 4))],
      );

      final nights = await _service(primary).syncFromHealth();

      expect(nights, isEmpty);
      expect(primary.sleepReads, 0);
    });

    test('demografia vazia cai no fallback; preenchida fica no primary', () async {
      final emptyPrimary = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.demographics},
      );
      final fallback = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.demographics},
        demographics: const HealthDemographics(heightCm: 170),
      );

      final filled =
          await _service(emptyPrimary, fallback).readDemographics();
      expect(filled.heightCm, 170);
      expect(emptyPrimary.demographicReads, 1);
      expect(fallback.demographicReads, 1);

      final present = _FakeConnector(
        source: HealthAppSource.samsungHealth,
        supportedCapabilities: const {HealthCapability.demographics},
        demographics: const HealthDemographics(heightCm: 165),
      );
      final other = _FakeConnector(
        source: HealthAppSource.healthConnect,
        supportedCapabilities: const {HealthCapability.demographics},
        demographics: const HealthDemographics(heightCm: 190),
      );
      final kept = await _service(present, other).readDemographics();
      expect(kept.heightCm, 165);
      expect(other.demographicReads, 0);
    });
  });
}

FacadeHealthService _service(
  HealthAppConnector primary, [
  HealthAppConnector? fallback,
]) {
  return FacadeHealthService(
    selector: _FixedSelector(
      SelectedHealthConnectors(primary: primary, fallback: fallback),
    ),
  );
}

SleepRecord _night(DateTime wake) {
  return SleepRecord(
    date: wake,
    bedtime: wake.subtract(const Duration(hours: 8)),
    wakeTime: wake,
    totalSleep: const Duration(hours: 7),
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
    required this.supportedCapabilities,
    this.recovery = const [],
    this.sleep = const [],
    this.demographics = HealthDemographics.empty,
    this.permissionGranted = true,
    this.waterOk = true,
    this.mindOk = true,
  });

  @override
  final HealthAppSource source;

  @override
  final Set<HealthCapability> supportedCapabilities;

  final List<DailyRecoverySnapshot> recovery;
  final List<SleepRecord> sleep;
  final HealthDemographics demographics;
  bool permissionGranted;
  bool waterOk;
  bool mindOk;

  int recoveryReads = 0;
  int sleepReads = 0;
  int permissionRequests = 0;
  int permissionChecks = 0;
  int waterWrites = 0;
  int mindWrites = 0;
  int demographicReads = 0;
  int initializes = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> initialize() async {
    initializes++;
  }

  @override
  Future<bool> requestPermissions() async {
    permissionRequests++;
    return permissionGranted;
  }

  @override
  Future<bool> hasPermissions() async {
    permissionChecks++;
    return permissionGranted;
  }

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async {
    sleepReads++;
    return sleep;
  }

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({
    int days = 14,
  }) async {
    recoveryReads++;
    return recovery;
  }

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({
    int days = 14,
  }) async =>
      const [];

  @override
  Future<HealthDemographics> readDemographics() async {
    demographicReads++;
    return demographics;
  }

  @override
  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) async {
    waterWrites++;
    return waterOk;
  }

  @override
  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  }) async {
    mindWrites++;
    return mindOk;
  }

  @override
  Future<bool> writeStateOfMind(StateOfMindEntry entry) async => false;

  @override
  Future<List<StateOfMindEntry>> getStateOfMindHistory({
    int days = 14,
  }) async =>
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
  String sourceName(AppLocalizations l10n) => source.name;
}
