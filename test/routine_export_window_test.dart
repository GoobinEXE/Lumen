import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';

void main() {
  final now = DateTime(2026, 10, 8, 12);
  final start = now.subtract(const Duration(days: 7));

  RoutineSnapshot shot({
    required String id,
    required DateTime savedAt,
    String anchor = '  escrever  ',
    List<String> habits = const ['zeta', 'agua'],
    String reflection = '  fechei  ',
    String? notes = '  nota  ',
  }) {
    return RoutineSnapshot(
      id: id,
      savedAt: savedAt,
      mainFocusAnchor: anchor,
      completedHabits: habits.toSet(),
      eveningReflection: reflection,
      therapistNotes: notes,
      waterGlasses: 3,
      tookPrescribedMedication: true,
    );
  }

  test('o instante exato do período entra e o minuto anterior fica de fora', () {
    final lines = routineExportLines(
      snapshots: [
        shot(id: 'tarde', savedAt: now),
        shot(id: 'limite', savedAt: start),
        shot(id: 'antes', savedAt: start.subtract(const Duration(minutes: 1))),
      ],
      now: now,
      periodDays: 7,
      hideIntimateNotes: false,
    );

    expect(lines.map((line) => line.savedAt), [start, now]);
    expect(lines.first.anchor, 'escrever');
    expect(lines.first.completedHabits, ['agua', 'zeta']);
    expect(lines.first.eveningReflection, 'fechei');
    expect(lines.first.therapistNotes, 'nota');
  });

  test('nota só com espaço some, e o modo íntimo esconde o texto', () {
    final open = routineExportLines(
      snapshots: [
        shot(
          id: 'branco',
          savedAt: now,
          reflection: '   ',
          notes: '  ',
        ),
      ],
      now: now,
      periodDays: 7,
      hideIntimateNotes: false,
    );
    expect(open.single.eveningReflection, isNull);
    expect(open.single.therapistNotes, isNull);

    final hidden = routineExportLines(
      snapshots: [
        shot(id: 'intimo', savedAt: now),
      ],
      now: now,
      periodDays: 7,
      hideIntimateNotes: true,
    );
    expect(hidden.single.eveningReflection, isNull);
    expect(hidden.single.therapistNotes, isNull);
    expect(hidden.single.anchor, 'escrever');
  });
}
