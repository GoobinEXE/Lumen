import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/health_sync/service/routine_health_mirror.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/medications/presentation/providers/medication_providers.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/integrations/health/health_app_source.dart';
import 'package:noa/integrations/health/health_service.dart';
import 'package:noa/integrations/health/models/daily_environment_snapshot.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/health_demographics.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('o mesmo salvamento não espelha água, hábito e humor outra vez', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final health = _RecordingHealth();
    final when = DateTime(2026, 10, 2, 9, 30);
    final current = DailyRoutineState(
      date: DateTime(2026, 10, 2),
      waterGlasses: 2,
      completedHabits: const {'Respirar um minuto'},
      stateOfMind: StateOfMindEntry(timestamp: when, valence: 0.4),
    );
    final previous = DailyRoutineState(date: current.date);

    Future<void> mirror() {
      return RoutineHealthMirror.mirrorIfEnabled(
        prefs: prefs,
        healthService: health,
        snapshotId: 'snap-1',
        previous: previous,
        current: current,
        syncEnabled: true,
      );
    }

    await mirror();
    await mirror();

    expect(health.waterWrites, 2);
    expect(health.mindWrites, 1);
    expect(health.somWrites, 1);
  });

  test(
    'dois snapshots do mesmo dia (água 2 depois 3) espelham só o delta',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final health = _RecordingHealth();
      final day = DateTime(2026, 10, 2);
      final previous = DailyRoutineState(date: day);

      await RoutineHealthMirror.mirrorIfEnabled(
        prefs: prefs,
        healthService: health,
        snapshotId: 'snap-a',
        previous: previous,
        current: DailyRoutineState(date: day, waterGlasses: 2),
        syncEnabled: true,
      );
      // 2 copos no primeiro salvamento do dia.
      expect(health.waterWrites, 2);

      await RoutineHealthMirror.mirrorIfEnabled(
        prefs: prefs,
        healthService: health,
        snapshotId: 'snap-b',
        previous: previous,
        current: DailyRoutineState(date: day, waterGlasses: 3),
        syncEnabled: true,
      );

      // Só o delta (1 copo) deve ser escrito; nunca 2 + 3 = 5.
      expect(health.waterWrites, 3);
    },
  );

  test('humor já marcado no build anterior não é escrito de novo', () async {
    final when = DateTime(2026, 10, 2, 9, 30);
    SharedPreferences.setMockInitialValues({
      'noa_health_som_synced_2026_10_2': when.millisecondsSinceEpoch,
    });
    final prefs = await SharedPreferences.getInstance();
    final health = _RecordingHealth();

    await RoutineHealthMirror.mirrorIfEnabled(
      prefs: prefs,
      healthService: health,
      snapshotId: 'snap-2',
      previous: DailyRoutineState(date: DateTime(2026, 10, 2)),
      current: DailyRoutineState(
        date: DateTime(2026, 10, 2),
        stateOfMind: StateOfMindEntry(timestamp: when, valence: 0.4),
      ),
      syncEnabled: true,
    );

    expect(health.somWrites, 0);
  });

  test('dose do Saúde no mesmo minuto não clona o registro local', () async {
    final local = MedicationLog(
      id: 'local-1',
      medicationId: 'm1',
      medicationName: 'Med',
      scheduledTime: DateTime(2026, 10, 2, 8),
      takenAt: DateTime(2026, 10, 2, 8, 2),
    );
    final merged = mergeDoseEventsIntoLogs(
      medicationId: 'm1',
      medicationName: 'Med',
      existing: [local],
      events: [
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'taken',
          loggedAt: DateTime(2026, 10, 2, 8, 0, 40),
        ),
      ],
    );
    expect(merged, [local]);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = MedicationRepository(prefs);
    await repo.addExternalLog(local);
    await repo.addExternalLog(
      MedicationLog(
        id: 'apple_1_m1',
        medicationId: 'm1',
        medicationName: 'Med',
        scheduledTime: DateTime(2026, 10, 2, 8, 0, 40),
        takenAt: DateTime(2026, 10, 2, 8, 0, 40),
        source: MedicationLogSource.appleHealth,
      ),
    );
    expect(await repo.logById('local-1'), isNotNull);
    expect(await repo.logById('apple_1_m1'), isNull);
  });
}

class _RecordingHealth implements HealthService {
  int waterWrites = 0;
  int mindWrites = 0;
  int somWrites = 0;

  @override
  HealthAppSource get activeSource => HealthAppSource.healthConnect;

  @override
  bool get shouldGuideToHealthConnect => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) async {
    waterWrites++;
    return true;
  }

  @override
  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  }) async {
    mindWrites++;
    return true;
  }

  @override
  Future<bool> writeStateOfMind(StateOfMindEntry entry) async {
    somWrites++;
    return true;
  }

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({int days = 14}) async =>
      const [];

  @override
  Future<SleepRecord?> getLastNightSleep() async => null;

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({int days = 14}) async =>
      const [];

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async => const [];

  @override
  Future<List<StateOfMindEntry>> getStateOfMindHistory({int days = 14}) async =>
      const [];

  @override
  Future<HealthDemographics> readDemographics() async =>
      HealthDemographics.empty;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<bool> isMedicationsApiAvailable() async => false;

  @override
  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  }) async => const [];

  @override
  Future<List<HealthKitMedicationInfo>> readMedications() async => const [];

  @override
  Future<bool> requestPermissions() async => true;

  @override
  String sourceName(AppLocalizations l10n) => 'teste';

  @override
  Future<List<SleepRecord>> syncFromHealth({int days = 14}) async => const [];
}
