import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/therapist_export/domain/export_period.dart';
import 'package:noa/features/therapist_export/service/whatsapp_text_formatter.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  test('janela do resumo corta o que ficou para trás do início', () {
    final now = DateTime(2026, 10, 7, 15);
    final inside = now.subtract(const Duration(days: 7));
    final outside = inside.subtract(const Duration(minutes: 1));

    expect(
      isWithinExportPeriod(instant: inside, now: now, periodDays: 7),
      isTrue,
    );
    expect(
      isWithinExportPeriod(instant: outside, now: now, periodDays: 7),
      isFalse,
    );
    expect(isWithinExportPeriod(instant: now, now: now, periodDays: 7), isTrue);
  });

  test('resumo de 7 dias não conta check-in nem noite de fora da janela', () {
    final now = DateTime.now();
    final l10n = lookupAppLocalizations(const Locale('pt'));
    final message = WhatsappTextFormatter.formatSummary(
      patientName: 'Marcelo P.',
      sleepRecords: [
        SleepRecord(
          date: now,
          bedtime: now.subtract(const Duration(hours: 7)),
          wakeTime: now,
          totalSleep: const Duration(hours: 7),
          remSleep: const Duration(hours: 2),
        ),
        SleepRecord(
          date: now.subtract(const Duration(days: 40)),
          bedtime: now.subtract(const Duration(days: 40, hours: 5)),
          wakeTime: now.subtract(const Duration(days: 40)),
          totalSleep: const Duration(hours: 4),
          remSleep: const Duration(minutes: 20),
        ),
      ],
      moodEntries: [
        MoodEntry(
          id: 'hoje',
          timestamp: now,
          valence: 2,
          energy: EnergyLevel.low,
          focus: FocusState.paralyzed,
        ),
        MoodEntry(
          id: 'antigo',
          timestamp: now.subtract(const Duration(days: 40)),
          valence: 1,
          energy: EnergyLevel.drained,
          focus: FocusState.paralyzed,
          tookMedication: true,
        ),
      ],
      l10n: l10n,
      periodDays: 7,
    );

    expect(message, contains('- Paralisia/Travado: *1 relatos*'));
    expect(message, contains('- Medicacao Tomada: *0 de 1 registros*'));
    expect(message, contains('- Noites de deficit (<6h): *0* de 1 noites'));
    expect(message, isNot(contains('*2 relatos*')));
  });

  test('State of Mind da Apple fora da janela não entra na contagem', () {
    final now = DateTime(2026, 10, 7, 15);
    final days = appleHealthSomDaysInPeriod(
      now: now,
      periodDays: 7,
      snapshots: [
        RoutineSnapshot(
          id: 'recente',
          savedAt: now.subtract(const Duration(days: 1)),
          stateOfMind: StateOfMindEntry(
            timestamp: now.subtract(const Duration(days: 1)),
            source: StateOfMindSource.appleHealth,
          ),
        ),
        RoutineSnapshot(
          id: 'antigo',
          savedAt: now.subtract(const Duration(days: 20)),
          stateOfMind: StateOfMindEntry(
            timestamp: now.subtract(const Duration(days: 20)),
            source: StateOfMindSource.appleHealth,
          ),
        ),
      ],
    );

    expect(days, 1);
  });
}
