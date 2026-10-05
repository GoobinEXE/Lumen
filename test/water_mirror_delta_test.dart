import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/health_sync/data/health_sync_prefs.dart';
import 'package:noa/features/health_sync/service/routine_health_mirror.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/integrations/health/health_service.dart';
import 'package:noa/integrations/health/models/daily_environment_snapshot.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('atenção plena com acento também espelha a sessão', () {
    expect(isBreathingMindfulnessHabit('Atención plena'), isTrue);
    expect(isBreathingMindfulnessHabit('Tomar sol'), isFalse);
  });

  group('espelho de água', () {
    late SharedPreferences prefs;
    late _RecordingHealth health;
    final day = DateTime(2026, 10, 1);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      health = _RecordingHealth();
    });

    Future<void> mirror(int glasses) {
      return RoutineHealthMirror.mirrorIfEnabled(
        prefs: prefs,
        healthService: health,
        previous: DailyRoutineState(date: day),
        current: DailyRoutineState(date: day, waterGlasses: glasses),
        syncEnabled: true,
      );
    }

    test('salvar de novo só escreve os copos que faltam', () async {
      await mirror(2);
      await mirror(2);
      await mirror(4);

      expect(health.successfulLiters, [0.25, 0.25, 0.25, 0.25]);
      expect(getSyncedWaterGlasses(prefs, day), 4);
    });

    test('falha no meio continua do copo que não entrou', () async {
      health.failAfterSuccesses = 2;

      await mirror(3);

      expect(health.successfulLiters, [0.25, 0.25]);
      expect(getSyncedWaterGlasses(prefs, day), 2);

      health.failAfterSuccesses = 100;
      await mirror(3);

      expect(health.successfulLiters, [0.25, 0.25, 0.25]);
      expect(getSyncedWaterGlasses(prefs, day), 3);
    });

    test('diminuir o copo do dia não escreve água de novo', () async {
      await mirror(3);
      await mirror(1);

      expect(health.successfulLiters, [0.25, 0.25, 0.25]);
      expect(getSyncedWaterGlasses(prefs, day), 3);
    });
  });
}

class _RecordingHealth implements HealthService {
  int failAfterSuccesses = 100;
  final List<double> successfulLiters = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) async {
    if (successfulLiters.length >= failAfterSuccesses) return false;
    successfulLiters.add(liters);
    return true;
  }

  @override
  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  }) async => false;

  @override
  Future<bool> writeStateOfMind(StateOfMindEntry entry) async => false;

  @override
  Future<List<StateOfMindEntry>> getStateOfMindHistory({int days = 14}) async {
    return const [];
  }

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> hasPermissions() async => false;

  @override
  Future<bool> isMedicationsApiAvailable() async => false;

  @override
  Future<List<HealthKitMedicationInfo>> readMedications() async => const [];

  @override
  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  }) async => const [];

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async => const [];

  @override
  Future<SleepRecord?> getLastNightSleep() async => null;

  @override
  Future<List<SleepRecord>> syncFromHealth({int days = 14}) async => const [];

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({
    int days = 14,
  }) async => const [];

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({
    int days = 14,
  }) async => const [];

  @override
  String sourceName(AppLocalizations l10n) => 'test';
}
