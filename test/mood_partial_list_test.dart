import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/mood_repository.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('item podre no meio não apaga o check-in bom ao salvar outro', () async {
    SharedPreferences.setMockInitialValues({
      'noa_mood_entries_v2': jsonEncode([
        {
          'id': 'ok',
          'timestamp': '2026-10-01T09:00:00.000',
          'valence': 4,
          'energy': 'balanced',
          'focus': 'focused',
        },
        {'id': 'bad'},
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = MoodRepository(prefs);

    await repo.addEntry(
      MoodEntry(
        id: 'novo',
        timestamp: DateTime(2026, 10, 2, 8),
        valence: 2,
        energy: EnergyLevel.low,
        focus: FocusState.scattered,
      ),
    );

    final all = await repo.getAllEntries();
    expect(all.map((entry) => entry.id).toList(), ['novo', 'ok']);
    expect(all.last.valence, 4);
    expect(all.last.focus, FocusState.focused);

    final days = await repo.markedCivilDays();
    expect(days, {DateTime(2026, 10, 1), DateTime(2026, 10, 2)});
  });
}
