import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/integrations/calendar/device_calendar.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));

  test('evento do calendário usa a âncora e deixa a reflexão de fora', () {
    const reflection = 'pensei demais na reunião';
    const notes = 'não levar isso pro calendário do sistema';
    final snapshot = RoutineSnapshot(
      id: 's1',
      savedAt: DateTime(2026, 10, 21, 21),
      mainFocusAnchor: '  Fechar o relatório  ',
      waterGlasses: 3,
      completedHabits: const {'Água'},
      tookPrescribedMedication: true,
      eveningReflection: reflection,
      therapistNotes: notes,
    );

    expect(routineCalendarTitle(l10n, snapshot), 'Fechar o relatório');

    final body = routineCalendarNotes(l10n, snapshot);
    expect(body, contains(l10n.exportRoutineWater(3)));
    expect(body, contains('Água'));
    expect(body, contains(l10n.exportRoutineMedYes));
    expect(body, isNot(contains(reflection)));
    expect(body, isNot(contains(notes)));
  });

  test(
    'âncora em branco cai no título padrão e hábito vazio não inventa lista',
    () {
      final snapshot = RoutineSnapshot(
        id: 's2',
        savedAt: DateTime(2026, 10, 21, 8),
        mainFocusAnchor: '   ',
        waterGlasses: 0,
        tookPrescribedMedication: false,
      );

      expect(
        routineCalendarTitle(l10n, snapshot),
        l10n.routineCalendarEventTitle,
      );

      final body = routineCalendarNotes(l10n, snapshot);
      expect(body, contains(l10n.exportRoutineHabitsNone));
      expect(body, contains(l10n.exportRoutineMedNo));
      expect(body, contains(l10n.exportRoutineWater(0)));
    },
  );
}
