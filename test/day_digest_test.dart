import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/calendar/domain/day_digest.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/routine_mood/data/mood_repository.dart';
import 'package:noa/features/routine_mood/data/routine_repository.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final day = DateTime(2026, 10, 6);

  test('isEmpty quando não há registros', () {
    final digest = DayDigest(
      day: day,
      checkIns: const [],
      snapshots: const [],
      medicationLogs: const [],
      completedTaskTitles: const [],
    );
    expect(digest.isEmpty, isTrue);
    expect(digest.latestStateOfMind, isNull);
  });

  test('agrega check-in, SoM da rotina e doses', () {
    final checkIn = MoodEntry(
      id: 'm1',
      timestamp: DateTime(2026, 10, 6, 9),
      valence: 3,
      energy: EnergyLevel.balanced,
      focus: FocusState.focused,
      tookMedication: false,
      sensoryOverload: false,
      note: 'café demais',
      emotionLabels: const {'anxious'},
    );
    final som = StateOfMindEntry(
      valence: 0.2,
      labels: const {'calm'},
      timestamp: DateTime(2026, 10, 6, 20),
    );
    final snapshot = RoutineSnapshot(
      id: 's1',
      savedAt: DateTime(2026, 10, 6, 21),
      mainFocusAnchor: 'Terminar o rascunho',
      waterGlasses: 2,
      completedHabits: const {'Ler'},
      tookPrescribedMedication: true,
      eveningReflection: 'Foi ok',
      therapistNotes: 'Falar do sono',
      stateOfMind: som,
    );
    final log = MedicationLog(
      id: 'l1',
      medicationId: 'med',
      medicationName: 'Lisdex',
      scheduledTime: DateTime(2026, 10, 6, 8),
      takenAt: DateTime(2026, 10, 6, 8, 5),
    );

    final digest = DayDigest(
      day: day,
      checkIns: [checkIn],
      snapshots: [snapshot],
      medicationLogs: [log],
      completedTaskTitles: const ['Ler'],
    );

    expect(digest.isEmpty, isFalse);
    expect(digest.checkIns.single.emotionLabels, contains('anxious'));
    expect(digest.checkIns.single.note, 'café demais');
    expect(digest.latestStateOfMind?.labels, contains('calm'));
    expect(digest.snapshots.single.therapistNotes, 'Falar do sono');
    expect(digest.medicationLogs.single.isTaken, isTrue);
    expect(digest.completedTaskTitles, ['Ler']);
  });

  test('latestStateOfMind pega o SoM mais recente', () {
    final older = StateOfMindEntry(
      labels: const {'sad'},
      timestamp: DateTime(2026, 10, 6, 10),
    );
    final newer = StateOfMindEntry(
      labels: const {'happy'},
      timestamp: DateTime(2026, 10, 6, 18),
    );
    final digest = DayDigest(
      day: day,
      checkIns: const [],
      snapshots: [
        RoutineSnapshot(
          id: 'a',
          savedAt: DateTime(2026, 10, 6, 10),
          mainFocusAnchor: '',
          waterGlasses: 0,
          completedHabits: const {},
          tookPrescribedMedication: false,
          eveningReflection: '',
          stateOfMind: older,
        ),
        RoutineSnapshot(
          id: 'b',
          savedAt: DateTime(2026, 10, 6, 18),
          mainFocusAnchor: '',
          waterGlasses: 0,
          completedHabits: const {},
          tookPrescribedMedication: false,
          eveningReflection: '',
          stateOfMind: newer,
        ),
      ],
      medicationLogs: const [],
      completedTaskTitles: const [],
    );
    expect(digest.latestStateOfMind?.labels, contains('happy'));
  });

  group('DayDigest após RoutineRepository.mergeTodayStateOfMind', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'latestStateOfMind reflete o SoM fundido, sem passar por MoodEntry',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final routineRepo = RoutineRepository(prefs);
        final when = DateTime(2026, 10, 7, 9);
        final entry = StateOfMindEntry(
          valence: 0.4,
          labels: const {'calm'},
          timestamp: when,
        );

        await routineRepo.mergeTodayStateOfMind(entry);

        final digest = DayDigest(
          day: DayDigest.civilDay(when),
          checkIns: const [], // Caminho rápido sem MoodEntry — snapshot-only.
          snapshots: routineRepo.getSnapshotsForDate(when),
          medicationLogs: const [],
          completedTaskTitles: const [],
        );

        expect(digest.isEmpty, isFalse);
        expect(digest.checkIns, isEmpty);
        expect(digest.latestStateOfMind, isNotNull);
        expect(digest.latestStateOfMind?.labels, contains('calm'));
        expect(digest.latestStateOfMind?.valence, 0.4);
      },
    );

    test(
      'segundo merge no mesmo dia atualiza o SoM mais recente do digest',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final routineRepo = RoutineRepository(prefs);
        final day = DateTime(2026, 10, 7, 9);

        await routineRepo.mergeTodayStateOfMind(
          StateOfMindEntry(
            valence: -0.3,
            labels: const {'tired'},
            timestamp: day,
          ),
        );
        await routineRepo.mergeTodayStateOfMind(
          StateOfMindEntry(
            valence: 0.7,
            labels: const {'happy'},
            timestamp: day.add(const Duration(hours: 6)),
          ),
        );

        final digest = DayDigest(
          day: DayDigest.civilDay(day),
          checkIns: const [],
          snapshots: routineRepo.getSnapshotsForDate(day),
          medicationLogs: const [],
          completedTaskTitles: const [],
        );

        // Mesmo snapshot do dia foi atualizado in-place; não multiplica.
        expect(digest.snapshots, hasLength(1));
        expect(digest.latestStateOfMind?.labels, contains('happy'));
        expect(digest.latestStateOfMind?.valence, 0.7);
      },
    );
  });

  group('Caminho rápido: addEntry (MoodEntry) + mergeTodayStateOfMind', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'o mesmo check-in aparece em checkIns e vira o SoM canônico do dia',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final moodRepo = MoodRepository(prefs);
        final routineRepo = RoutineRepository(prefs);
        final savedAt = DateTime(2026, 10, 7, 14);

        // Mesmo contrato do quick_checkin_modal: um timestamp, dois destinos.
        final checkIn = MoodEntry(
          id: 'quick-1',
          timestamp: savedAt,
          valence: 4,
          energy: EnergyLevel.energized,
          focus: FocusState.focused,
          emotionLabels: const {'happy'},
        );
        await moodRepo.addEntry(checkIn);
        await routineRepo.mergeTodayStateOfMind(
          StateOfMindEntry(
            valence: 1.0,
            labels: const {'happy'},
            timestamp: savedAt,
          ),
        );

        final allMood = await moodRepo.getAllEntries();
        final digest = DayDigest(
          day: DayDigest.civilDay(savedAt),
          checkIns: allMood
              .where((e) => DayDigest.sameCivilDay(e.timestamp, savedAt))
              .toList(),
          snapshots: routineRepo.getSnapshotsForDate(savedAt),
          medicationLogs: const [],
          completedTaskTitles: const [],
        );

        expect(digest.checkIns, hasLength(1));
        expect(digest.checkIns.single.emotionLabels, contains('happy'));
        // SoM continua vindo do snapshot (snapshot-only), não do MoodEntry.
        expect(digest.latestStateOfMind, isNotNull);
        expect(digest.latestStateOfMind?.labels, contains('happy'));
        expect(digest.latestStateOfMind?.valence, 1.0);
      },
    );
  });
}
