import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/routine_repository.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('RoutineRepository.mergeTodayStateOfMind — SoM canônico do dia', () {
    late RoutineRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = RoutineRepository(prefs);
    });

    test('dia sem snapshot: cria exatamente um snapshot mínimo com o SoM', () async {
      final day = DateTime(2026, 10, 7, 9);
      final entry = StateOfMindEntry(
        valence: 0.4,
        labels: const {'calm'},
        timestamp: day,
      );

      final result = await repo.mergeTodayStateOfMind(entry);

      final snapshots = repo.getSnapshotsForDate(day);
      expect(snapshots, hasLength(1));
      expect(snapshots.single.id, result.id);
      expect(snapshots.single.stateOfMind?.labels, contains('calm'));
      // Defaults honestos: sem hábitos/âncora, água 0, sem dado de saúde.
      expect(snapshots.single.mainFocusAnchor, isEmpty);
      expect(snapshots.single.microHabits, isEmpty);
      expect(snapshots.single.completedHabits, isEmpty);
      expect(snapshots.single.waterGlasses, 0);
    });

    test('segunda chamada no mesmo dia atualiza o mesmo snapshot (mesmo id)', () async {
      final day = DateTime(2026, 10, 7, 9);
      final first = await repo.mergeTodayStateOfMind(
        StateOfMindEntry(
          valence: -0.5,
          labels: const {'tired'},
          timestamp: day,
        ),
      );

      final second = await repo.mergeTodayStateOfMind(
        StateOfMindEntry(
          valence: 0.6,
          labels: const {'happy'},
          timestamp: day.add(const Duration(hours: 5)),
        ),
      );

      final snapshots = repo.getSnapshotsForDate(day);
      expect(snapshots, hasLength(1), reason: 'não multiplica snapshots');
      expect(second.id, first.id, reason: 'merge in-place no mesmo registro');
      expect(snapshots.single.stateOfMind?.labels, contains('happy'));
      expect(snapshots.single.stateOfMind?.valence, 0.6);
    });

    test('N chamadas no mesmo dia não multiplicam snapshots', () async {
      final day = DateTime(2026, 10, 7, 8);
      for (var i = 0; i < 6; i++) {
        await repo.mergeTodayStateOfMind(
          StateOfMindEntry(
            valence: 0.1 * i,
            timestamp: day.add(Duration(hours: i)),
          ),
        );
      }

      final snapshots = repo.getSnapshotsForDate(day);
      expect(snapshots, hasLength(1));
      expect(snapshots.single.stateOfMind?.valence, closeTo(0.5, 1e-9));
    });

    test('dia com snapshot existente: funde SoM no último sem criar novo', () async {
      final day = DateTime(2026, 10, 7, 7);
      await repo.appendSnapshot(
        RoutineSnapshot(
          id: 'snap-rotina',
          savedAt: day,
          mainFocusAnchor: 'Terminar o rascunho',
          waterGlasses: 2,
          completedHabits: const {'Ler'},
        ),
      );

      final merged = await repo.mergeTodayStateOfMind(
        StateOfMindEntry(
          valence: 0.3,
          labels: const {'focused'},
          timestamp: day.add(const Duration(hours: 10)),
        ),
      );

      final snapshots = repo.getSnapshotsForDate(day);
      expect(snapshots, hasLength(1));
      expect(merged.id, 'snap-rotina');
      // Preserva o resto do snapshot e só atualiza o SoM.
      expect(snapshots.single.mainFocusAnchor, 'Terminar o rascunho');
      expect(snapshots.single.waterGlasses, 2);
      expect(snapshots.single.completedHabits, contains('Ler'));
      expect(snapshots.single.stateOfMind?.labels, contains('focused'));
    });
  });
}
