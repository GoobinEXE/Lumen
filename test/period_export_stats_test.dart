import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_export.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/therapist_export/domain/period_export_stats.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

void main() {
  test('sem noites a média é zero e valor nulo sai da média', () {
    final stats = PeriodExportStats.from(
      sleepRecords: const [],
      moodEntries: [
        _mood(
          id: 'm1',
          focus: FocusState.scattered,
          sensoryOverload: true,
          tookMedication: true,
          labels: const {'calm'},
          source: StateOfMindSource.appleHealth,
        ),
        _mood(
          id: 'm2',
          focus: FocusState.focused,
          source: StateOfMindSource.appleHealth,
        ),
      ],
      recoverySnapshots: [
        DailyRecoverySnapshot(date: _day, hrvMs: 40, steps: 1000),
        DailyRecoverySnapshot(date: _nextDay),
        DailyRecoverySnapshot(date: _thirdDay, hrvMs: 60),
      ],
    );

    expect(stats.avgSleepHours, 0);
    expect(stats.avgRemHours, 0);
    expect(stats.sleepNights, 0);
    expect(stats.deficitNights, 0);
    expect(stats.avgHrv, 50);
    expect(stats.avgSteps, 1000);
    expect(stats.avgRestingHeartRate, isNull);
    expect(stats.somFromAppleCount, 1);
    expect(stats.scatteredCount, 1);
    expect(stats.focusedCount, 1);
    expect(stats.sensoryCount, 1);
    expect(stats.medCount, 1);
  });

  test('6 h não é déficit, 5 h 59 é, e rótulo da rotina entra no ranking', () {
    final stats = PeriodExportStats.from(
      sleepRecords: [
        _night(const Duration(hours: 6)),
        _night(
          const Duration(hours: 5, minutes: 59),
          rem: const Duration(minutes: 90),
        ),
      ],
      moodEntries: [
        _mood(id: 'm1', focus: FocusState.paralyzed, labels: const {'calm'}),
        _mood(id: 'm2', focus: FocusState.hyperfocus),
      ],
      routineLines: [
        RoutineExportLine(
          savedAt: _day,
          anchor: 'foco',
          waterGlasses: 1,
          completedHabits: const [],
          tookPrescribedMedication: false,
          stateOfMind: StateOfMindEntry(
            timestamp: _day,
            labels: const {'calm', 'stressed'},
          ),
        ),
        RoutineExportLine(
          savedAt: _nextDay,
          anchor: '',
          waterGlasses: 0,
          completedHabits: [],
          tookPrescribedMedication: false,
        ),
      ],
      appleHealthSomCount: 2,
    );

    expect(stats.deficitNights, 1);
    expect(stats.sleepNights, 2);
    expect(stats.avgSleepHours, closeTo(5.991666, 0.001));
    expect(stats.avgRemHours, 0.75);
    expect(stats.paralyzedCount, 1);
    expect(stats.hyperfocusCount, 1);
    expect(stats.somFromAppleCount, 2);
    expect(stats.topEmotionLabels.first.key, 'calm');
    expect(stats.topEmotionLabels.first.value, 2);
    expect(stats.topEmotionLabels[1].key, 'stressed');
    expect(stats.topEmotionLabels[1].value, 1);
  });
}

final _day = DateTime(2026, 10, 1, 9);
final _nextDay = DateTime(2026, 10, 2);
final _thirdDay = DateTime(2026, 10, 3);

MoodEntry _mood({
  required String id,
  required FocusState focus,
  bool sensoryOverload = false,
  bool tookMedication = false,
  Set<String> labels = const {},
  StateOfMindSource source = StateOfMindSource.lumen,
}) {
  return MoodEntry(
    id: id,
    timestamp: _day,
    valence: 3,
    energy: EnergyLevel.balanced,
    focus: focus,
    sensoryOverload: sensoryOverload,
    tookMedication: tookMedication,
    emotionLabels: labels,
    emotionSource: source,
  );
}

SleepRecord _night(Duration total, {Duration rem = Duration.zero}) {
  return SleepRecord(
    date: _day,
    bedtime: DateTime(2026, 9, 30, 23),
    wakeTime: _day,
    totalSleep: total,
    remSleep: rem,
  );
}
