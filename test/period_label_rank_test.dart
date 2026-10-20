import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/therapist_export/domain/period_export_stats.dart';

void main() {
  MoodEntry mood(Set<String> labels) {
    return MoodEntry(
      id: 'mood',
      timestamp: DateTime(2026, 10, 20, 9),
      valence: 3,
      energy: EnergyLevel.balanced,
      focus: FocusState.focused,
      emotionLabels: labels,
    );
  }

  RoutineExportLine line(Set<String> labels) {
    return RoutineExportLine(
      savedAt: DateTime(2026, 10, 20, 21),
      anchor: 'Foco',
      waterGlasses: 0,
      completedHabits: const [],
      tookPrescribedMedication: false,
      stateOfMind: StateOfMindEntry(
        timestamp: DateTime(2026, 10, 20, 21),
        labels: labels,
      ),
    );
  }

  test('o mesmo rótulo no check-in e na rotina soma no ranking', () {
    final stats = PeriodExportStats.from(
      sleepRecords: const [],
      moodEntries: [mood({'calm', 'happy'})],
      routineLines: [line({'calm'})],
    );

    expect(stats.topEmotionLabels.map((entry) => entry.key).toList(), [
      'calm',
      'happy',
    ]);
    expect(stats.topEmotionLabels.first.value, 2);
    expect(stats.topEmotionLabels.last.value, 1);
  });

  test('empate de contagem conserva a ordem de aparição e não corta em 5', () {
    final stats = PeriodExportStats.from(
      sleepRecords: const [],
      moodEntries: [
        mood({
          'calm',
          'happy',
          'sad',
          'angry',
          'anxious',
          'grateful',
        }),
      ],
    );

    expect(stats.topEmotionLabels.map((entry) => entry.key).toList(), [
      'calm',
      'happy',
      'sad',
      'angry',
      'anxious',
      'grateful',
    ]);
    expect(stats.topEmotionLabels.every((entry) => entry.value == 1), isTrue);
  });
}
