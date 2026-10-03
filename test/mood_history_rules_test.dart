import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/mood_repository.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MoodRepository> repoWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return MoodRepository(prefs);
  }

  MoodEntry entry(String id, DateTime timestamp) {
    return MoodEntry(
      id: id,
      timestamp: timestamp,
      valence: 4,
      energy: EnergyLevel.balanced,
      focus: FocusState.focused,
    );
  }

  test('JSON quebrado de humor não derruba a leitura', () async {
    final repo = await repoWith({'noa_mood_entries_v2': '{'});

    expect(await repo.getAllEntries(), isEmpty);
    expect(await repo.getLatestEntry(), isNull);
  });

  test(
    'o check-in novo fica na frente e o anterior continua na lista',
    () async {
      final repo = await repoWith({});
      final older = entry('old', DateTime(2026, 10, 1, 9));
      final newer = entry('new', DateTime(2026, 10, 1, 18));

      await repo.addEntry(older);
      await repo.addEntry(newer);

      final all = await repo.getAllEntries();
      expect(all.map((item) => item.id), ['new', 'old']);
      expect((await repo.getLatestEntry())?.id, 'new');
    },
  );

  test('a janela de 7 dias deixa a semana anterior de fora', () async {
    final repo = await repoWith({});
    final now = DateTime.now();

    await repo.addEntry(entry('fora', now.subtract(const Duration(days: 8))));
    await repo.addEntry(entry('dentro', now.subtract(const Duration(days: 6))));
    await repo.addEntry(entry('agora', now));

    final window = await repo.getEntriesForDays(7);

    expect(window.map((item) => item.id), ['agora', 'dentro']);
  });

  test('energia, foco e origem desconhecidos não apagam o check-in', () async {
    final repo = await repoWith({
      'noa_mood_entries_v2': jsonEncode([
        {
          'id': 'legado',
          'timestamp': '2026-10-01T12:00:00.000',
          'energy': 'sleepy',
          'focus': 'gone',
          'emotionSource': 'watch',
          'emotionLabels': ['calm'],
        },
      ]),
    });

    final restored = await repo.getAllEntries();

    expect(restored, hasLength(1));
    expect(restored.single.valence, 3);
    expect(restored.single.energy, EnergyLevel.balanced);
    expect(restored.single.focus, FocusState.focused);
    expect(restored.single.emotionSource, StateOfMindSource.lumen);
    expect(restored.single.emotionLabels, contains('calm'));
  });
}
