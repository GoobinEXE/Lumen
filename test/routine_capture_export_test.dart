import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/therapist_export/service/routine_export_copy.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  test('salvar a rotina corta espaço e solta nota em branco', () {
    final habits = <String>{'água'};
    final draft = DailyRoutineState(
      date: DateTime(2026, 9, 20),
      mainFocusAnchor: '  Escrever  ',
      eveningReflection: '  tarde  ',
      therapistNotes: '   ',
      completedHabits: habits,
      waterGlasses: 3,
    );

    final snapshot = RoutineSnapshot.capture(
      id: 's',
      savedAt: DateTime(2026, 9, 20, 10),
      draft: draft,
    );
    habits.add('outro');

    expect(snapshot.mainFocusAnchor, 'Escrever');
    expect(snapshot.eveningReflection, 'tarde');
    expect(snapshot.therapistNotes, isNull);
    expect(snapshot.waterGlasses, 3);
    expect(snapshot.completedHabits, {'água'});
  });

  test('linha do export descreve âncora vazia, sem tarefa e sem medicação', () {
    final l10n = lookupAppLocalizations(const Locale('pt'));
    final savedAt = DateTime(2026, 9, 20, 10, 15);
    final rows = describeRoutineExportLine(
      l10n: l10n,
      line: RoutineExportLine(
        savedAt: savedAt,
        anchor: '',
        waterGlasses: 0,
        completedHabits: const [],
        tookPrescribedMedication: false,
        eveningReflection: 'fechei tarde',
      ),
      dateFormat: DateFormat('dd/MM'),
      timeFormat: DateFormat('HH:mm'),
    );

    expect(rows, [
      l10n.homeRoutineSnapshotLine(
        '20/09 10:15',
        l10n.exportRoutineAnchorEmpty,
      ),
      l10n.exportRoutineWater(0),
      l10n.exportRoutineHabitsNone,
      l10n.exportRoutineMedNo,
      l10n.exportRoutineReflection('fechei tarde'),
    ]);
  });
}
