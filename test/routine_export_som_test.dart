import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/therapist_export/service/routine_export_copy.dart';
import 'package:noa/features/therapist_export/service/whatsapp_text_formatter.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  test('export da rotina inclui labels do State of Mind', () {
    final l10n = lookupAppLocalizations(const Locale('pt'));
    final lines = routineExportLines(
      snapshots: [
        RoutineSnapshot(
          id: 's1',
          savedAt: DateTime(2026, 10, 6, 21),
          mainFocusAnchor: 'Foco',
          stateOfMind: StateOfMindEntry(
            labels: const {'calm', 'happy'},
            timestamp: DateTime(2026, 10, 6, 20),
          ),
        ),
      ],
      now: DateTime(2026, 10, 7),
      periodDays: 7,
      hideIntimateNotes: true,
    );

    expect(lines, hasLength(1));
    expect(lines.single.stateOfMind, isNotNull);

    final rows = describeRoutineExportLine(
      l10n: l10n,
      line: lines.single,
      dateFormat: DateFormat('dd/MM'),
      timeFormat: DateFormat('HH:mm'),
      languageCode: 'pt',
    );
    // `exportRoutineSom` passou a "Estado emocional" na etapa de copy da 0.4.
    expect(rows.any((r) => r.contains('Estado emocional')), isTrue);
  });

  test(
    'export com Foco do dia vazio usa a copy "Sem Foco do dia" (não "Sem âncora")',
    () {
      final l10n = lookupAppLocalizations(const Locale('pt'));
      final rows = describeRoutineExportLine(
        l10n: l10n,
        line: RoutineExportLine(
          savedAt: DateTime(2026, 10, 6, 21),
          anchor: '',
          waterGlasses: 0,
          completedHabits: const [],
          tookPrescribedMedication: false,
        ),
        dateFormat: DateFormat('dd/MM'),
        timeFormat: DateFormat('HH:mm'),
        languageCode: 'pt',
      );

      expect(rows.any((r) => r.contains('Sem Foco do dia')), isTrue);
      expect(rows.any((r) => r.contains('Sem âncora')), isFalse);
    },
  );

  group('routineExportLines oculta/revela notas íntimas', () {
    RoutineSnapshot snapshotWithNotes() => RoutineSnapshot(
      id: 's-intimo',
      savedAt: DateTime(2026, 10, 6, 21),
      mainFocusAnchor: 'Foco',
      eveningReflection: 'Fechei o dia exausto, mas terminei a tarefa.',
      therapistNotes: 'Falar sobre ansiedade antes de dormir.',
    );

    test('hideIntimateNotes true zera reflection e notes', () {
      final lines = routineExportLines(
        snapshots: [snapshotWithNotes()],
        now: DateTime(2026, 10, 7),
        periodDays: 7,
        hideIntimateNotes: true,
      );

      expect(lines, hasLength(1));
      expect(lines.single.eveningReflection, isNull);
      expect(lines.single.therapistNotes, isNull);
    });

    test('hideIntimateNotes false mantém reflection e notes do snapshot', () {
      final lines = routineExportLines(
        snapshots: [snapshotWithNotes()],
        now: DateTime(2026, 10, 7),
        periodDays: 7,
        hideIntimateNotes: false,
      );

      expect(lines, hasLength(1));
      expect(
        lines.single.eveningReflection,
        'Fechei o dia exausto, mas terminei a tarefa.',
      );
      expect(
        lines.single.therapistNotes,
        'Falar sobre ansiedade antes de dormir.',
      );
    });

    test('hideIntimateNotes false com snapshot sem notas continua null', () {
      final lines = routineExportLines(
        snapshots: [
          RoutineSnapshot(
            id: 's-sem-notas',
            savedAt: DateTime(2026, 10, 6, 21),
            mainFocusAnchor: 'Foco',
          ),
        ],
        now: DateTime(2026, 10, 7),
        periodDays: 7,
        hideIntimateNotes: false,
      );

      expect(lines.single.eveningReflection, isNull);
      expect(lines.single.therapistNotes, isNull);
    });
  });

  group('estado emocional do período fica legível com uma fonte só', () {
    test('só MoodEntry (sem SoM de rotina) aparece nas palavras do período', () {
      final l10n = lookupAppLocalizations(const Locale('pt'));
      final message = WhatsappTextFormatter.formatSummary(
        patientName: 'Marcelo P.',
        sleepRecords: const [],
        moodEntries: [
          MoodEntry(
            id: 'mood-1',
            timestamp: DateTime(2026, 10, 6, 9),
            valence: 3,
            energy: EnergyLevel.balanced,
            focus: FocusState.focused,
            emotionLabels: const {'grateful'},
          ),
        ],
        l10n: l10n,
        // Sem routineLines: a única fonte emocional é o MoodEntry.
      );

      expect(message, contains(l10n.waTopWordsHeader));
      expect(message, contains('Grato(a)'));
    });

    test('só SoM do snapshot (sem MoodEntry) aparece nas palavras do período', () {
      final l10n = lookupAppLocalizations(const Locale('pt'));
      final routineLines = routineExportLines(
        snapshots: [
          RoutineSnapshot(
            id: 's-som',
            savedAt: DateTime(2026, 10, 6, 21),
            mainFocusAnchor: 'Foco',
            stateOfMind: StateOfMindEntry(
              labels: const {'calm'},
              timestamp: DateTime(2026, 10, 6, 20),
            ),
          ),
        ],
        now: DateTime(2026, 10, 7),
        periodDays: 7,
        hideIntimateNotes: true,
      );

      final message = WhatsappTextFormatter.formatSummary(
        patientName: 'Marcelo P.',
        sleepRecords: const [],
        moodEntries: const [], // Nenhum check-in isolado nesse período.
        routineLines: routineLines,
        l10n: l10n,
      );

      expect(message, contains(l10n.waTopWordsHeader));
      expect(message, contains('Calmo(a)'));
    });
  });
}
