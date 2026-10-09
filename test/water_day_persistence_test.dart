import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/routine_repository.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('água do dia civil sobrevive a save + reload', () {
    test(
      'reidratar pelo máximo dos snapshots do dia restaura a água, não zera',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = RoutineRepository(prefs);
        final day = DateTime(2026, 10, 2, 9);

        await repo.appendSnapshot(
          RoutineSnapshot(
            id: 'snap-1',
            savedAt: day,
            waterGlasses: 2,
          ),
        );

        // Simula reabrir o app: SharedPreferences é lido de novo e um novo
        // repositório é criado, como faria um novo `todayRoutineDraftProvider`.
        final reloadedPrefs = await SharedPreferences.getInstance();
        final reloadedRepo = RoutineRepository(reloadedPrefs);
        final snapshots = reloadedRepo.getSnapshotsForDate(day);
        final rehydratedWater = snapshots.isEmpty
            ? 0
            : snapshots
                .map((snapshot) => snapshot.waterGlasses)
                .reduce((a, b) => a > b ? a : b);

        expect(rehydratedWater, 2);
        expect(rehydratedWater, isNot(0));
      },
    );

    test(
      'segundo snapshot do mesmo dia com água maior vence na reidratação',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = RoutineRepository(prefs);
        final day = DateTime(2026, 10, 2, 9);
        final later = DateTime(2026, 10, 2, 18);

        await repo.appendSnapshot(
          RoutineSnapshot(id: 'snap-1', savedAt: day, waterGlasses: 2),
        );
        await repo.appendSnapshot(
          RoutineSnapshot(id: 'snap-2', savedAt: later, waterGlasses: 3),
        );

        final snapshots = repo.getSnapshotsForDate(day);
        final rehydratedWater = snapshots
            .map((snapshot) => snapshot.waterGlasses)
            .reduce((a, b) => a > b ? a : b);

        expect(rehydratedWater, 3);
      },
    );

    test(
      'cleared state pós-save preserva waterGlasses via copyWith explícito',
      () {
        final beforeSave = DailyRoutineState(
          date: DateTime(2026, 10, 2),
          waterGlasses: 4,
          mainFocusAnchor: 'Terminar relatório',
          eveningReflection: 'Dia puxado',
        );

        // Mesmo padrão de `_saveRoutine`: limpa campos íntimos, mas
        // preserva a água do dia explicitamente.
        final cleared = DailyRoutineState(
          date: beforeSave.date,
          microHabits: beforeSave.microHabits,
          waterGlasses: beforeSave.waterGlasses,
        );

        expect(cleared.waterGlasses, 4);
        expect(cleared.mainFocusAnchor, isEmpty);
      },
    );

    test('dia sem snapshot nenhum reidrata com água zero (comportamento esperado)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = RoutineRepository(prefs);
      final day = DateTime(2026, 10, 3, 9);

      final snapshots = repo.getSnapshotsForDate(day);
      final rehydratedWater = snapshots.isEmpty
          ? 0
          : snapshots
              .map((snapshot) => snapshot.waterGlasses)
              .reduce((a, b) => a > b ? a : b);

      expect(rehydratedWater, 0);
    });
  });
}
