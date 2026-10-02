import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/routine_repository.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/therapist_export/service/whatsapp_text_formatter.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('JSON antigo de um dia vira um registro na lista', () async {
    SharedPreferences.setMockInitialValues({
      'noa_daily_routine_2026_9_20': jsonEncode({
        'date': '2026-09-20T00:00:00.000',
        'mainFocusAnchor': 'Legado',
        'microHabits': ['A'],
        'completedHabits': <String>[],
        'waterGlasses': 1,
        'tookPrescribedMedication': false,
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);

    final restored = repo.getSnapshotsForDate(DateTime(2026, 9, 20));

    expect(restored, hasLength(1));
    expect(restored.first.mainFocusAnchor, 'Legado');
    expect(restored.first.waterGlasses, 1);
  });

  test('dois salvamentos no mesmo dia guardam horas diferentes', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);
    final morning = DateTime(2026, 9, 20, 10, 15);
    final evening = DateTime(2026, 9, 20, 18, 40);
    final draft = DailyRoutineState(
      date: DateTime(2026, 9, 20),
      mainFocusAnchor: 'Escrever',
      microHabits: const ['Água'],
    );

    await repo.appendSnapshot(
      RoutineSnapshot.capture(id: 'a', savedAt: morning, draft: draft),
    );
    await repo.appendSnapshot(
      RoutineSnapshot.capture(
        id: 'b',
        savedAt: evening,
        draft: draft.copyWith(mainFocusAnchor: 'Fechar o dia'),
      ),
    );

    final day = repo.getSnapshotsForDate(DateTime(2026, 9, 20));
    expect(day.map((item) => item.savedAt), [morning, evening]);
    expect(day.last.mainFocusAnchor, 'Fechar o dia');
  });

  test('export da rotina leva âncora e hora e esconde a pauta', () {
    final l10n = lookupAppLocalizations(const Locale('pt'));
    final savedAt = DateTime(2026, 9, 20, 10, 15);
    final lines = routineExportLines(
      snapshots: [
        RoutineSnapshot(
          id: 's',
          savedAt: savedAt,
          mainFocusAnchor: 'Escrever projeto',
          waterGlasses: 2,
          therapistNotes: 'nota íntima',
          eveningReflection: 'fechei tarde',
        ),
      ],
      now: DateTime(2026, 9, 21),
      periodDays: 7,
      hideIntimateNotes: true,
    );

    final message = WhatsappTextFormatter.formatSummary(
      patientName: 'Marcelo P.',
      sleepRecords: const [],
      moodEntries: const [],
      l10n: l10n,
      routineLines: lines,
    );

    expect(lines.single.therapistNotes, isNull);
    expect(lines.single.eveningReflection, isNull);
    expect(lines.single.anchor, 'Escrever projeto');
    expect(message, contains('Escrever projeto'));
    expect(message, contains('10:15'));
    expect(message, isNot(contains('nota íntima')));
  });
}
