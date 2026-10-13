import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/routine_repository.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('item podre no meio do dia não congela o salvamento bom', () async {
    const key = 'noa_daily_routine_2026_10_13';
    SharedPreferences.setMockInitialValues({
      key: jsonEncode([
        {
          'id': 'ok',
          'savedAt': '2026-10-13T08:15:00.000',
          'mainFocusAnchor': 'Escrever',
          'waterGlasses': 3,
          'completedHabits': ['Água'],
        },
        'quebrado',
        {'id': 'sem-hora'},
      ]),
      'noa_daily_routine_extra': jsonEncode([
        {
          'id': 'fora',
          'savedAt': '2026-10-13T09:00:00.000',
          'mainFocusAnchor': 'Não é dia',
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);
    final day = DateTime(2026, 10, 13);

    final before = repo.getSnapshotsForDate(day);
    expect(before, hasLength(1));
    expect(before.single.mainFocusAnchor, 'Escrever');
    expect(before.single.waterGlasses, 3);
    expect(repo.markedDays(), {day});

    await repo.appendSnapshot(
      RoutineSnapshot.capture(
        id: 'noite',
        savedAt: DateTime(2026, 10, 13, 21),
        draft: DailyRoutineState(
          date: DateTime(2026, 10, 13),
          mainFocusAnchor: 'Fechar',
        ),
      ),
    );

    final after = repo.getSnapshotsForDate(day);
    expect(after.map((snapshot) => snapshot.id), ['ok', 'noite']);
    expect(after.first.mainFocusAnchor, 'Escrever');
    expect(after.first.waterGlasses, 3);
    final raw = prefs.getString(key);
    expect(raw, isNot(contains('quebrado')));
    expect(raw, contains('Escrever'));
    expect(prefs.getString('noa_daily_routine_extra'), contains('Não é dia'));
  });

  test('a janela da rotina inclui a manhã do dia civil e corta a véspera', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);

    await repo.appendSnapshot(
      RoutineSnapshot.capture(
        id: 'vespera',
        savedAt: DateTime(2026, 10, 12, 23, 30),
        draft: DailyRoutineState(date: DateTime(2026, 10, 12)),
      ),
    );
    await repo.appendSnapshot(
      RoutineSnapshot.capture(
        id: 'manha',
        savedAt: DateTime(2026, 10, 13, 8),
        draft: DailyRoutineState(date: DateTime(2026, 10, 13)),
      ),
    );

    final sinceEvening = repo.snapshotsSince(DateTime(2026, 10, 13, 23));
    expect(sinceEvening.map((snapshot) => snapshot.id), ['manha']);

    final sinceMidnight = repo.snapshotsSince(DateTime(2026, 10, 13));
    expect(sinceMidnight.map((snapshot) => snapshot.id), ['manha']);
  });
}
