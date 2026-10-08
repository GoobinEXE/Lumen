import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/localization/correlation_copy.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/l10n/app_localizations.dart';

void main() {
  final copy = L10nCorrelationCopy(lookupAppLocalizations(const Locale('pt')));
  final day = DateTime(2026, 10, 8);

  SleepRecord shortRemNight() {
    return SleepRecord(
      date: day,
      bedtime: DateTime(2026, 10, 7, 23),
      wakeTime: DateTime(2026, 10, 8, 6),
      totalSleep: const Duration(hours: 5),
      remSleep: const Duration(minutes: 40),
    );
  }

  List<CorrelationInsight> analyze({
    List<SleepRecord> sleep = const [],
    required List<MoodEntry> moods,
    List<DailyRecoverySnapshot> recovery = const [],
  }) {
    return CorrelationEngine.analyze(
      sleepRecords: sleep,
      moodEntries: moods,
      recoverySnapshots: recovery,
      copy: copy,
    );
  }

  test('exaustão sem paralisia ainda entra no alerta de REM', () {
    final insights = analyze(
      sleep: [shortRemNight()],
      moods: [
        MoodEntry(
          id: 'm-1',
          timestamp: day.add(const Duration(hours: 10)),
          valence: 3,
          energy: EnergyLevel.drained,
          focus: FocusState.scattered,
        ),
      ],
    );

    expect(insights, hasLength(1));
    expect(insights.single.title, contains('REM'));
    expect(insights.single.correlationPercentage, 100);
  });

  test('a palavra estressado sozinha liga o alerta de HRV', () {
    final stressed = analyze(
      moods: [
        MoodEntry(
          id: 'm-1',
          timestamp: day.add(const Duration(hours: 15)),
          valence: 3,
          energy: EnergyLevel.balanced,
          focus: FocusState.focused,
          emotionLabels: const {'stressed'},
        ),
      ],
      recovery: [
        DailyRecoverySnapshot(date: day, hrvMs: 39, steps: 8000),
      ],
    );
    final calm = analyze(
      moods: [
        MoodEntry(
          id: 'm-2',
          timestamp: day.add(const Duration(hours: 15)),
          valence: 3,
          energy: EnergyLevel.balanced,
          focus: FocusState.focused,
          emotionLabels: const {'happy'},
        ),
      ],
      recovery: [
        DailyRecoverySnapshot(date: day, hrvMs: 39, steps: 8000),
      ],
    );

    expect(stressed.single.title, contains('HRV'));
    expect(stressed.single.correlationPercentage, 100);
    expect(calm.single.title, 'Coletando Padrões');
  });

  test('fones a 80 dB contam como ruído e 79 dB não', () {
    MoodEntry overloaded() {
      return MoodEntry(
        id: 'm-1',
        timestamp: day.add(const Duration(hours: 18)),
        valence: 3,
        energy: EnergyLevel.balanced,
        focus: FocusState.focused,
        sensoryOverload: true,
      );
    }

    final loud = analyze(
      moods: [overloaded()],
      recovery: [
        DailyRecoverySnapshot(date: day, avgHeadphoneDb: 80, steps: 8000),
      ],
    );
    final quiet = analyze(
      moods: [overloaded()],
      recovery: [
        DailyRecoverySnapshot(date: day, avgHeadphoneDb: 79, steps: 8000),
      ],
    );

    expect(loud.any((insight) => insight.title.contains('Ruído')), isTrue);
    expect(quiet.any((insight) => insight.title.contains('Ruído')), isFalse);
  });

  test('hiperfoco com humor neutro não vira janela de fluidez', () {
    final insights = analyze(
      sleep: [
        SleepRecord(
          date: day,
          bedtime: DateTime(2026, 10, 7, 23),
          wakeTime: DateTime(2026, 10, 8, 7),
          totalSleep: const Duration(hours: 8),
          remSleep: const Duration(minutes: 90),
        ),
      ],
      moods: [
        MoodEntry(
          id: 'm-1',
          timestamp: day.add(const Duration(hours: 11)),
          valence: 3,
          energy: EnergyLevel.balanced,
          focus: FocusState.hyperfocus,
        ),
      ],
    );

    expect(insights.single.title, 'Coletando Padrões');
    expect(
      insights.any((insight) => insight.title.contains('Fluidez')),
      isFalse,
    );
  });
}
