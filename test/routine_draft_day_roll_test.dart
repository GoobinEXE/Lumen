import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';

void main() {
  final yesterday = DateTime(2026, 10, 21);
  final today = DateTime(2026, 10, 22, 8, 30);

  DailyRoutineState draft({
    required DateTime date,
    int water = 0,
    bool tookMeds = false,
    String anchor = '',
    List<String> habits = const ['Água'],
  }) {
    return DailyRoutineState(
      date: date,
      waterGlasses: water,
      tookPrescribedMedication: tookMeds,
      mainFocusAnchor: anchor,
      microHabits: habits,
    );
  }

  test('rascunho de ontem não entra no dia novo', () {
    final rolled = DailyRoutineState.forCivilDay(
      held: draft(date: yesterday, water: 6, tookMeds: true, anchor: 'Relatório'),
      loaded: draft(date: yesterday, water: 6, tookMeds: true),
      now: today,
    );

    expect(rolled.date, DateTime(2026, 10, 22));
    expect(rolled.waterGlasses, 0);
    expect(rolled.tookPrescribedMedication, isFalse);
    expect(rolled.mainFocusAnchor, isEmpty);
    expect(rolled.microHabits, ['Água']);
  });

  test('reidratação de hoje vence o rascunho que ainda é de ontem', () {
    final rolled = DailyRoutineState.forCivilDay(
      held: draft(date: yesterday, water: 6),
      loaded: draft(date: DateTime(2026, 10, 22), water: 2, habits: const ['Sol']),
      now: today,
    );

    expect(rolled.waterGlasses, 2);
    expect(rolled.date, DateTime(2026, 10, 22));
    expect(rolled.microHabits, ['Sol']);
  });

  test('edição já feita hoje não é trocada pela carga', () {
    final held = draft(date: DateTime(2026, 10, 22), water: 3, tookMeds: true);
    final rolled = DailyRoutineState.forCivilDay(
      held: held,
      loaded: draft(date: DateTime(2026, 10, 22), water: 1),
      now: today,
    );

    expect(identical(rolled, held), isTrue);
  });
}
