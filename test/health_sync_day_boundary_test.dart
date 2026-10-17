import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/health_sync/service/routine_health_mirror.dart';
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
  test('virada do dia não reaproveita água, respiração nem humor de ontem', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final health = _RecordingHealth();
    final yesterday = DateTime(2026, 10, 1, 23, 50);
    final today = DateTime(2026, 10, 2, 0, 10);

    await _mirror(
      prefs: prefs,
      health: health,
      day: yesterday,
      snapshotId: 'ontem',
      glasses: 2,
      breathing: true,
      som: StateOfMindEntry(timestamp: yesterday, valence: -0.2),
    );
    await _mirror(
      prefs: prefs,
      health: health,
      day: today,
      snapshotId: 'hoje',
      glasses: 1,
      breathing: true,
      som: StateOfMindEntry(timestamp: today, valence: 0.4),
    );

    // 2 copos ontem + 1 hoje. Se a marca fosse global, o copo de hoje sumia.
    expect(health.waterLiters, [0.25, 0.25, 0.25]);
    expect(health.mindWrites, 2);
    expect(health.somTimestamps, [yesterday, today]);
  });
}

Future<void> _mirror({
  required SharedPreferences prefs,
  required _RecordingHealth health,
  required DateTime day,
  required String snapshotId,
  required int glasses,
  required bool breathing,
  required StateOfMindEntry som,
}) {
  return RoutineHealthMirror.mirrorIfEnabled(
    prefs: prefs,
    healthService: health,
    snapshotId: snapshotId,
    previous: DailyRoutineState(date: day),
    current: DailyRoutineState(
      date: day,
      waterGlasses: glasses,
      completedHabits: breathing ? const {'Respirar fundo'} : const {},
      stateOfMind: som,
    ),
    syncEnabled: true,
  );
}

class _RecordingHealth implements HealthService {
  final waterLiters = <double>[];
  var mindWrites = 0;
  final somTimestamps = <DateTime>[];

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
    waterLiters.add(liters);
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
    somTimestamps.add(entry.timestamp);
    return true;
  }

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({
    int days = 14,
  }) async => const [];

  @override
  Future<SleepRecord?> getLastNightSleep() async => null;

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({
    int days = 14,
  }) async => const [];

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async => const [];

  @override
  Future<List<StateOfMindEntry>> getStateOfMindHistory({
    int days = 14,
  }) async => const [];

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
