import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/routine_mood/data/mood_repository.dart';
import 'package:noa/features/routine_mood/data/routine_repository.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/therapist_export/data/therapist_contact_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'uma nova abertura lê humor, medicação, rotina e telefone já salvos',
    () async {
      final mood = MoodEntry(
        id: 'mood-1',
        timestamp: DateTime(2026, 10, 1, 9),
        valence: 4,
        energy: EnergyLevel.balanced,
        focus: FocusState.focused,
      );
      final med = Medication(
        id: 'med-1',
        name: 'Lisdexanfetamina',
        dosage: '30 mg',
        scheduledTimes: const ['08:00'],
      );
      final log = MedicationLog(
        id: 'log-1',
        medicationId: 'med-1',
        medicationName: 'Lisdexanfetamina 30 mg',
        scheduledTime: DateTime(2026, 10, 1, 8),
        takenAt: DateTime(2026, 10, 1, 8, 5),
      );
      final snapshot = RoutineSnapshot.capture(
        id: 'rot-1',
        savedAt: DateTime(2026, 10, 1, 10),
        draft: DailyRoutineState(
          date: DateTime(2026, 10, 1),
          mainFocusAnchor: 'Fechar o relatório',
          microHabits: const ['Água'],
        ),
      );

      SharedPreferences.setMockInitialValues({
        'noa_mood_entries_v2': jsonEncode([mood.toMap()]),
        'noa_medications_list_v2': jsonEncode([med.toMap()]),
        'noa_medication_logs_v2': jsonEncode([log.toMap()]),
        'noa_daily_routine_2026_10_1': jsonEncode([snapshot.toMap()]),
        TherapistContactRepository.legacyPhoneV1Key: '5511999999999',
        'noa_theme_mode': 'dark',
        'noa_health_sync_enabled': true,
        'noa_micro_habits_template': jsonEncode(['Água']),
        'noa_med_reminder_schedule_v1': '{"med-1":["08:00"]}',
      });

      final prefs = await SharedPreferences.getInstance();
      final moods = await MoodRepository(prefs).getAllEntries();
      final meds = await MedicationRepository(prefs).getMedications();
      final logs = await MedicationRepository(
        prefs,
      ).getLogsForDate(DateTime(2026, 10, 1));
      final day = RoutineRepository(
        prefs,
      ).getSnapshotsForDate(DateTime(2026, 10, 1));

      expect(moods.single.id, 'mood-1');
      expect(moods.single.valence, 4);
      expect(meds.single.name, 'Lisdexanfetamina');
      expect(logs.single.takenAt, DateTime(2026, 10, 1, 8, 5));
      expect(day.single.mainFocusAnchor, 'Fechar o relatório');
      final contactRepo = TherapistContactRepository(prefs);
      expect(contactRepo.readPhone(), '5511999999999');
      expect(
        prefs.getString(TherapistContactRepository.contactsKey),
        isNotNull,
      );
      expect(prefs.getString('noa_theme_mode'), 'dark');
      expect(prefs.getBool('noa_health_sync_enabled'), isTrue);
      expect(
        prefs.getString('noa_micro_habits_template'),
        jsonEncode(['Água']),
      );
      expect(prefs.getString('noa_med_reminder_schedule_v1'), isNotNull);
    },
  );

  test('json ilegível não é trocado por lista vazia no próximo save', () async {
    const brokenMood = '{nao-e-lista';
    const brokenMeds = '[';
    const brokenLogs = 'não-json';
    const brokenRoutine = '{"savedAt":';

    SharedPreferences.setMockInitialValues({
      'noa_mood_entries_v2': brokenMood,
      'noa_medications_list_v2': brokenMeds,
      'noa_medication_logs_v2': brokenLogs,
      'noa_daily_routine_2026_10_1': brokenRoutine,
    });
    final prefs = await SharedPreferences.getInstance();

    final moods = MoodRepository(prefs);
    await moods.addEntry(
      MoodEntry(
        id: 'novo',
        timestamp: DateTime(2026, 10, 2, 9),
        valence: 3,
        energy: EnergyLevel.low,
        focus: FocusState.scattered,
      ),
    );

    final meds = MedicationRepository(prefs);
    await meds.saveMedication(
      const Medication(
        id: 'med-novo',
        name: 'Outro',
        dosage: '10 mg',
        scheduledTimes: ['09:00'],
      ),
    );
    await meds.getLogsForDate(DateTime(2026, 10, 1));

    final routines = RoutineRepository(prefs);
    await routines.appendSnapshot(
      RoutineSnapshot.capture(
        id: 'novo-dia',
        savedAt: DateTime(2026, 10, 1, 11),
        draft: DailyRoutineState(
          date: DateTime(2026, 10, 1),
          mainFocusAnchor: 'Novo',
        ),
      ),
    );

    expect(prefs.getString('noa_mood_entries_v2'), brokenMood);
    expect(prefs.getString('noa_medications_list_v2'), brokenMeds);
    expect(prefs.getString('noa_medication_logs_v2'), brokenLogs);
    expect(prefs.getString('noa_daily_routine_2026_10_1'), brokenRoutine);
  });
}
