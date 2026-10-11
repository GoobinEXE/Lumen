import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/mood_repository.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MoodRepository repo;

  MoodEntry entry(String id, DateTime timestamp) {
    return MoodEntry(
      id: id,
      timestamp: timestamp,
      valence: 3,
      energy: EnergyLevel.balanced,
      focus: FocusState.focused,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = MoodRepository(prefs);
  });

  test('23:59 fica no dia e meia-noite abre o seguinte', () async {
    await repo.addEntry(entry('tarde', DateTime(2026, 10, 6, 23, 59)));
    await repo.addEntry(entry('meia-noite', DateTime(2026, 10, 7)));

    final sixth = await repo.getEntriesForCivilDay(DateTime(2026, 10, 6, 15));
    final seventh = await repo.getEntriesForCivilDay(
      DateTime(2026, 10, 7, 0, 1),
    );

    expect(sixth.map((item) => item.id), ['tarde']);
    expect(seventh.map((item) => item.id), ['meia-noite']);

    final marked = await repo.markedCivilDays();
    expect(marked, {DateTime(2026, 10, 6), DateTime(2026, 10, 7)});
  });

  test('no mesmo dia a leitura sai da mais antiga para a mais nova', () async {
    await repo.addEntry(entry('tarde', DateTime(2026, 10, 6, 18)));
    await repo.addEntry(entry('manha', DateTime(2026, 10, 6, 8)));

    final day = await repo.getEntriesForCivilDay(DateTime(2026, 10, 6));
    expect(day.map((item) => item.id), ['manha', 'tarde']);

    final all = await repo.getAllEntries();
    expect(all.first.id, 'manha');
  });
}
