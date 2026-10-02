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

  group('hábito de respiração', () {
    test('reconhece respiração, alongamento e atenção plena', () {
      expect(isBreathingMindfulnessHabit('Respiração 4-7-8'), isTrue);
      expect(isBreathingMindfulnessHabit('Box breathing'), isTrue);
      expect(isBreathingMindfulnessHabit('Alongar o corpo'), isTrue);
      expect(isBreathingMindfulnessHabit('Morning stretch'), isTrue);
      expect(isBreathingMindfulnessHabit('Estiramiento'), isTrue);
      expect(isBreathingMindfulnessHabit('3 min mindful'), isTrue);
      expect(isBreathingMindfulnessHabit('Atenção plena'), isTrue);
      expect(isBreathingMindfulnessHabit('atencion plena'), isTrue);
      expect(isBreathingMindfulnessHabit('深呼吸'), isTrue);
      expect(isBreathingMindfulnessHabit('ストレッチ'), isTrue);
      expect(isBreathingMindfulnessHabit('Beber água'), isFalse);
      expect(isBreathingMindfulnessHabit('Caminhar'), isFalse);
    });
  });

  group('espelho da rotina', () {
    late SharedPreferences prefs;
    late _RecordingHealth health;
    final day = DateTime(2026, 10, 1);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      health = _RecordingHealth();
    });

    Future<void> mirror({
      required DailyRoutineState previous,
      required DailyRoutineState current,
      bool syncEnabled = true,
    }) {
      return RoutineHealthMirror.mirrorIfEnabled(
        prefs: prefs,
        healthService: health,
        previous: previous,
        current: current,
        syncEnabled: syncEnabled,
      );
    }

    test('sync desligado não abre o Health', () async {
      await mirror(
        previous: DailyRoutineState(date: day),
        current: DailyRoutineState(date: day, waterGlasses: 3),
        syncEnabled: false,
      );

      expect(health.initializeCalls, 0);
      expect(health.waterLiters, isEmpty);
    });

    test('cada copo vira 250 ml e a falha interrompe o resto', () async {
      health.failWaterAfter = 1;

      await mirror(
        previous: DailyRoutineState(date: day),
        current: DailyRoutineState(date: day, waterGlasses: 3),
      );

      expect(health.waterLiters, [0.25, 0.25]);
      expect(getSyncedWaterGlasses(prefs, day), 1);
    });

    test('zero copo não escreve água', () async {
      await mirror(
        previous: DailyRoutineState(date: day),
        current: DailyRoutineState(date: day),
      );

      expect(health.waterLiters, isEmpty);
      expect(getSyncedWaterGlasses(prefs, day), 0);
    });

    test('respiração nova vira uma sessão e não repete no mesmo dia', () async {
      final previous = DailyRoutineState(date: day);
      final current = DailyRoutineState(
        date: day,
        completedHabits: const {'Respiração 4-7-8', 'Beber água'},
      );

      await mirror(previous: previous, current: current);
      await mirror(previous: previous, current: current);

      expect(health.mindfulnessSpans, hasLength(1));
      expect(
        health.mindfulnessSpans.single,
        RoutineHealthMirror.mindfulnessDuration,
      );
      expect(wasMindfulnessSyncedToday(prefs, day), isTrue);
    });

    test('hábito que já estava feito ou não é respiração não escreve sessão', () async {
      await mirror(
        previous: DailyRoutineState(
          date: day,
          completedHabits: const {'Alongar o corpo'},
        ),
        current: DailyRoutineState(
          date: day,
          completedHabits: const {'Alongar o corpo', 'Caminhar'},
        ),
      );

      expect(health.mindfulnessSpans, isEmpty);
    });

    test('falha ao escrever a sessão deixa o dia livre para tentar de novo', () async {
      health.mindfulnessOk = false;
      final current = DailyRoutineState(
        date: day,
        completedHabits: const {'mindful'},
      );

      await mirror(previous: DailyRoutineState(date: day), current: current);

      expect(health.mindfulnessSpans, isEmpty);
      expect(wasMindfulnessSyncedToday(prefs, day), isFalse);
    });

    test('State of Mind do Apple ou já espelhado não escreve de novo', () async {
      final local = StateOfMindEntry(
        timestamp: day.add(const Duration(hours: 9)),
        valence: 0.2,
      );
      await mirror(
        previous: DailyRoutineState(date: day),
        current: DailyRoutineState(
          date: day,
          stateOfMind: local.copyWith(source: StateOfMindSource.appleHealth),
        ),
      );
      expect(health.stateOfMindWrites, isEmpty);

      await mirror(
        previous: DailyRoutineState(date: day),
        current: DailyRoutineState(date: day, stateOfMind: local),
      );
      await mirror(
        previous: DailyRoutineState(date: day),
        current: DailyRoutineState(date: day, stateOfMind: local),
      );

      expect(health.stateOfMindWrites, [local.timestamp]);
    });

    test('erro do Health não estoura o salvamento da rotina', () async {
      health.throwOnInitialize = true;

      await mirror(
        previous: DailyRoutineState(date: day),
        current: DailyRoutineState(
          date: day,
          waterGlasses: 2,
          completedHabits: const {'breath'},
        ),
      );

      expect(health.waterLiters, isEmpty);
    });
  });

  group('State of Mind vindo do Health', () {
    final day = DateTime(2026, 10, 1, 15);

    test('sync desligado ou amostra fora do dia devolve o local', () async {
      final local = DailyRoutineState(
        date: day,
        stateOfMind: StateOfMindEntry(
          timestamp: DateTime(2026, 10, 1, 9),
          valence: 0.2,
        ),
      );
      final health = _RecordingHealth()
        ..stateOfMind = [
          StateOfMindEntry(
            timestamp: DateTime(2026, 10, 2),
            valence: -1,
          ),
          StateOfMindEntry(
            timestamp: DateTime(2026, 9, 30, 23, 59),
            valence: -1,
          ),
        ];

      final disabled = await RoutineHealthMirror.mergeStateOfMindFromHealth(
        local: local,
        syncEnabled: false,
        healthService: health,
      );
      final outside = await RoutineHealthMirror.mergeStateOfMindFromHealth(
        local: local,
        syncEnabled: true,
        healthService: health,
      );

      expect(identical(disabled, local), isTrue);
      expect(identical(outside, local), isTrue);
    });

    test('amostra mais nova do dia substitui a local e marca a origem', () async {
      final localEntry = StateOfMindEntry(
        timestamp: DateTime(2026, 10, 1, 9),
        valence: -0.2,
        labels: {'anxious'},
      );
      final remote = StateOfMindEntry(
        timestamp: DateTime(2026, 10, 1, 18),
        valence: 0.6,
        labels: {'calm'},
      );
      final health = _RecordingHealth()..stateOfMind = [remote];

      final merged = await RoutineHealthMirror.mergeStateOfMindFromHealth(
        local: DailyRoutineState(date: day, stateOfMind: localEntry),
        syncEnabled: true,
        healthService: health,
      );

      expect(merged.stateOfMind?.source, StateOfMindSource.appleHealth);
      expect(merged.stateOfMind?.valence, 0.6);
      expect(merged.stateOfMind?.labels, contains('calm'));
    });

    test('amostra mais antiga do dia não cobre o registro local', () async {
      final localEntry = StateOfMindEntry(
        timestamp: DateTime(2026, 10, 1, 18),
        valence: 0.4,
      );
      final health = _RecordingHealth()
        ..stateOfMind = [
          StateOfMindEntry(
            timestamp: DateTime(2026, 10, 1, 8),
            valence: -0.8,
          ),
        ];

      final merged = await RoutineHealthMirror.mergeStateOfMindFromHealth(
        local: DailyRoutineState(date: day, stateOfMind: localEntry),
        syncEnabled: true,
        healthService: health,
      );

      expect(merged.stateOfMind?.valence, 0.4);
      expect(merged.stateOfMind?.source, StateOfMindSource.lumen);
    });

    test('meia-noite do dia entra e a meia-noite seguinte fica de fora', () async {
      final health = _RecordingHealth()
        ..stateOfMind = [
          StateOfMindEntry(
            timestamp: DateTime(2026, 10, 2),
            valence: -1,
          ),
          StateOfMindEntry(
            timestamp: DateTime(2026, 10, 1),
            valence: 0.3,
          ),
        ];

      final merged = await RoutineHealthMirror.mergeStateOfMindFromHealth(
        local: DailyRoutineState(date: day),
        syncEnabled: true,
        healthService: health,
      );

      expect(merged.stateOfMind?.valence, 0.3);
      expect(merged.stateOfMind?.source, StateOfMindSource.appleHealth);
    });
  });
}

class _RecordingHealth implements HealthService {
  int initializeCalls = 0;
  bool throwOnInitialize = false;
  int failWaterAfter = 1 << 30;
  bool mindfulnessOk = true;
  final List<double> waterLiters = [];
  final List<Duration> mindfulnessSpans = [];
  final List<DateTime> stateOfMindWrites = [];
  List<StateOfMindEntry> stateOfMind = [];

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (throwOnInitialize) throw StateError('health indisponível');
  }

  @override
  Future<bool> writeWaterIntake({
    required DateTime when,
    required double liters,
  }) async {
    waterLiters.add(liters);
    return waterLiters.length <= failWaterAfter;
  }

  @override
  Future<bool> writeMindfulnessSession({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!mindfulnessOk) return false;
    mindfulnessSpans.add(end.difference(start));
    return true;
  }

  @override
  Future<bool> writeStateOfMind(StateOfMindEntry entry) async {
    stateOfMindWrites.add(entry.timestamp);
    return true;
  }

  @override
  Future<List<StateOfMindEntry>> getStateOfMindHistory({int days = 14}) async {
    return stateOfMind;
  }

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<bool> hasPermissions() async => false;

  @override
  Future<bool> isMedicationsApiAvailable() async => false;

  @override
  Future<List<HealthKitMedicationInfo>> readMedications() async => [];

  @override
  Future<List<HealthKitDoseEvent>> readDoseEvents({
    required String appleConceptId,
    required DateTime start,
    required DateTime end,
  }) async => [];

  @override
  Future<List<SleepRecord>> getSleepHistory({int days = 7}) async => [];

  @override
  Future<SleepRecord?> getLastNightSleep() async => null;

  @override
  Future<List<SleepRecord>> syncFromHealth({int days = 14}) async => [];

  @override
  Future<List<DailyRecoverySnapshot>> getRecoveryHistory({int days = 14}) async {
    return [];
  }

  @override
  Future<List<DailyEnvironmentSnapshot>> getEnvironmentHistory({
    int days = 14,
  }) async => [];

  @override
  String sourceName(AppLocalizations l10n) => 'teste';
}
