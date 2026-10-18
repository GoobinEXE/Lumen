import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/therapist_export/domain/period_export_stats.dart';
import 'package:noa/features/therapist_export/service/whatsapp_text_formatter.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  SleepRecord night({
    required int hours,
    required int remMinutes,
  }) {
    return SleepRecord(
      date: DateTime(2026, 10, 8),
      bedtime: DateTime(2026, 10, 7, 23),
      wakeTime: DateTime(2026, 10, 8, 7),
      totalSleep: Duration(hours: hours),
      remSleep: Duration(minutes: remMinutes),
    );
  }

  MoodEntry mood({
    required String id,
    required FocusState focus,
    bool sensory = false,
    bool med = false,
    Set<String> labels = const {},
    StateOfMindSource source = StateOfMindSource.lumen,
  }) {
    return MoodEntry(
      id: id,
      timestamp: DateTime(2026, 10, 8, 12),
      valence: 3,
      energy: EnergyLevel.balanced,
      focus: focus,
      sensoryOverload: sensory,
      tookMedication: med,
      emotionLabels: labels,
      emotionSource: source,
    );
  }

  test('foco, medicação e sono do período contam em baldes separados', () {
    final stats = PeriodExportStats.from(
      sleepRecords: [
        night(hours: 8, remMinutes: 90),
        night(hours: 4, remMinutes: 30),
      ],
      moodEntries: [
        mood(
          id: 'p',
          focus: FocusState.paralyzed,
          sensory: true,
          med: true,
          labels: const {'anxious'},
        ),
        mood(id: 'f', focus: FocusState.focused),
        mood(
          id: 'h',
          focus: FocusState.hyperfocus,
          labels: const {'anxious'},
        ),
        mood(
          id: 's',
          focus: FocusState.scattered,
          labels: const {'calm'},
          source: StateOfMindSource.appleHealth,
        ),
        mood(
          id: 'apple-empty',
          focus: FocusState.focused,
          source: StateOfMindSource.appleHealth,
        ),
      ],
      recoverySnapshots: [
        DailyRecoverySnapshot(date: DateTime(2026, 10, 7), steps: 0),
        DailyRecoverySnapshot(date: DateTime(2026, 10, 8), steps: 10),
      ],
      appleHealthSomCount: 2,
    );

    expect(stats.avgSleepHours, 6);
    expect(stats.avgRemHours, 1);
    expect(stats.sleepNights, 2);
    expect(stats.deficitNights, 1);
    expect(stats.paralyzedCount, 1);
    expect(stats.hyperfocusCount, 1);
    expect(stats.scatteredCount, 1);
    expect(stats.focusedCount, 2);
    expect(stats.sensoryCount, 1);
    expect(stats.medCount, 1);
    expect(stats.avgSteps, 5);
    expect(stats.avgExerciseMinutes, isNull);
    expect(stats.somFromAppleCount, 3);
    expect(stats.topEmotionLabels.map((e) => e.key).toList(), [
      'anxious',
      'calm',
    ]);
    expect(stats.topEmotionLabels.first.value, 2);
  });

  test('REM médio de 75 min fica adequado e 74 min entra no alerta', () {
    final l10n = lookupAppLocalizations(const Locale('pt'));

    String message(int remMinutes) {
      return WhatsappTextFormatter.formatSummary(
        patientName: 'Ana',
        sleepRecords: [night(hours: 8, remMinutes: remMinutes)],
        moodEntries: const [],
        l10n: l10n,
      );
    }

    expect(message(75), contains('adequado'));
    expect(message(75), isNot(contains('alerta de deficit')));
    expect(message(74), contains('alerta de deficit'));
  });
}
