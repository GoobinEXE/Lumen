import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/mood_repository.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MoodEntry entry(String id, DateTime timestamp) {
    return MoodEntry(
      id: id,
      timestamp: timestamp,
      valence: 3,
      energy: EnergyLevel.balanced,
      focus: FocusState.focused,
    );
  }

  test('janela de 7 dias corta o limite e fica com o minuto seguinte', () async {
    final now = DateTime.now();
    final outside = entry(
      'fora',
      now.subtract(const Duration(days: 7, minutes: 2)),
    );
    final inside = entry(
      'dentro',
      now.subtract(const Duration(days: 7)).add(const Duration(minutes: 2)),
    );
    final today = entry('hoje', now.subtract(const Duration(minutes: 1)));

    SharedPreferences.setMockInitialValues({
      'noa_mood_entries_v2': jsonEncode([
        outside.toMap(),
        inside.toMap(),
        today.toMap(),
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final found = await MoodRepository(prefs).getEntriesForDays(7);
    final ids = found.map((mood) => mood.id).toSet();

    expect(ids, containsAll(['dentro', 'hoje']));
    expect(ids, isNot(contains('fora')));
  });
}
