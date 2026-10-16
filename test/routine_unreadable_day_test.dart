import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/routine_repository.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('lista só com itens sem hora não é trocada por um salvamento novo', () async {
    const raw = '[{"id":"x"},{"savedAt":1}]';
    SharedPreferences.setMockInitialValues({
      'noa_daily_routine_2026_10_1': raw,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);
    final day = DateTime(2026, 10, 1, 11);

    expect(repo.getSnapshotsForDate(day), isEmpty);

    await repo.appendSnapshot(
      RoutineSnapshot(
        id: 'novo',
        savedAt: day,
        mainFocusAnchor: 'Fechar o relatório',
      ),
    );

    expect(prefs.getString('noa_daily_routine_2026_10_1'), raw);
    expect(repo.getSnapshotsForDate(day), isEmpty);
  });

  test('registro antigo sem data não é apagado ao salvar o dia', () async {
    const raw = '{"mainFocusAnchor":"Rotina da manhã"}';
    SharedPreferences.setMockInitialValues({
      'noa_daily_routine_2026_10_2': raw,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);
    final day = DateTime(2026, 10, 2, 9);

    expect(repo.getSnapshotsForDate(day), isEmpty);

    await repo.appendSnapshot(
      RoutineSnapshot(
        id: 'novo',
        savedAt: day,
        mainFocusAnchor: 'Ler o livro',
      ),
    );

    expect(prefs.getString('noa_daily_routine_2026_10_2'), raw);
    expect(repo.getSnapshotsForDate(day), isEmpty);
  });

  test('dia ilegível não bloqueia o salvamento de outro dia', () async {
    const broken = '[{"id":"x"}]';
    SharedPreferences.setMockInitialValues({
      'noa_daily_routine_2026_10_1': broken,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);
    final other = DateTime(2026, 10, 3, 18);

    await repo.appendSnapshot(
      RoutineSnapshot(
        id: 'outro',
        savedAt: other,
        mainFocusAnchor: 'Caminhar',
      ),
    );

    expect(prefs.getString('noa_daily_routine_2026_10_1'), broken);
    expect(repo.getSnapshotsForDate(DateTime(2026, 10, 1)), isEmpty);
    expect(
      repo.getSnapshotsForDate(other).single.mainFocusAnchor,
      'Caminhar',
    );
  });
}
