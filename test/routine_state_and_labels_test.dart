import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_associations.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_labels.dart';
import 'package:noa/integrations/calendar/device_calendar.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  test('limpar o humor do dia solta o registro', () {
    final day = DateTime(2026, 10, 1);
    final local = StateOfMindEntry(
      timestamp: day.add(const Duration(hours: 9)),
      valence: -0.4,
      labels: const {'anxious'},
    );
    final incoming = StateOfMindEntry(
      timestamp: day.add(const Duration(hours: 18)),
      valence: 0.4,
    );
    final state = DailyRoutineState(date: day, stateOfMind: local);

    expect(
      state.copyWith(clearStateOfMind: true, stateOfMind: incoming).stateOfMind,
      isNull,
    );
    expect(state.copyWith(stateOfMind: incoming).stateOfMind, incoming);
  });

  test('rótulo desconhecido volta o id e idioma faltante usa o inglês', () {
    expect(StateOfMindLabels.label('calm', 'pt'), 'Calmo(a)');
    expect(StateOfMindLabels.label('calm', 'fr'), 'Calm');
    expect(StateOfMindLabels.label('not-a-label', 'pt'), 'not-a-label');
    expect(StateOfMindAssociations.label('work', 'es'), 'Trabajo');
    expect(StateOfMindAssociations.label('work', 'fr'), 'Work');
    expect(StateOfMindAssociations.label('nope', 'pt'), 'nope');
  });

  test('evento da rotina leva pauta e reflexão e descarta espaço vazio', () {
    final l10n = lookupAppLocalizations(const Locale('pt'));
    final filled = RoutineSnapshot(
      id: 's',
      savedAt: DateTime(2026, 10, 1, 9),
      mainFocusAnchor: 'Escrever',
      eveningReflection: 'fechei',
      therapistNotes: 'pauta',
      completedHabits: const {'agua', 'sol'},
      waterGlasses: 1,
      tookPrescribedMedication: true,
    );
    final notes = routineCalendarNotes(l10n, filled);
    expect(routineCalendarTitle(l10n, filled), 'Escrever');
    expect(notes, contains('Como o dia fechou: fechei'));
    expect(notes, contains('Pauta: pauta'));
    expect(notes, contains('Medicação prescrita: tomada'));
    expect(notes, contains('agua'));
    expect(notes, contains('sol'));

    final hidden = routineCalendarNotes(
      l10n,
      RoutineSnapshot(
        id: 'b',
        savedAt: filled.savedAt,
        eveningReflection: '   ',
        therapistNotes: '   ',
        waterGlasses: 1,
      ),
    );
    expect(hidden, isNot(contains('Como o dia fechou')));
    expect(hidden, isNot(contains('Pauta:')));
  });
}
