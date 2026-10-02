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

  SleepRecord sleepOn(DateTime date, {required Duration rem}) {
    return SleepRecord(
      date: date,
      bedtime: date.subtract(const Duration(hours: 8)),
      wakeTime: date,
      totalSleep: const Duration(hours: 7),
      remSleep: rem,
    );
  }

  MoodEntry mood({
    required String id,
    required DateTime timestamp,
    FocusState focus = FocusState.focused,
    EnergyLevel energy = EnergyLevel.balanced,
    int valence = 3,
    bool sensoryOverload = false,
    Set<String> emotionLabels = const {},
  }) {
    return MoodEntry(
      id: id,
      timestamp: timestamp,
      valence: valence,
      energy: energy,
      focus: focus,
      sensoryOverload: sensoryOverload,
      emotionLabels: emotionLabels,
    );
  }

  List<CorrelationInsight> analyze({
    List<SleepRecord> sleep = const [],
    List<MoodEntry> moods = const [],
    List<DailyRecoverySnapshot> recovery = const [],
  }) {
    return CorrelationEngine.analyze(
      sleepRecords: sleep,
      moodEntries: moods,
      recoverySnapshots: recovery,
      copy: copy,
    );
  }

  bool titled(List<CorrelationInsight> insights, String title) {
    return insights.any((insight) => insight.title == title);
  }

  test('sem sono e sem humor pede mais dados do Health', () {
    final insights = analyze();

    expect(insights, hasLength(1));
    expect(insights.single.title, copy.insightCollectingTitle);
    expect(insights.single.description, copy.insightCollectingDescHealth);
  });

  test('REM entra na janela de 30 h e esgotamento também conta', () {
    final wake = DateTime(2026, 9, 20);
    final record = sleepOn(wake, rem: const Duration(minutes: 40));
    final insights = analyze(
      sleep: [record],
      moods: [
        mood(
          id: 'edge',
          timestamp: wake.add(const Duration(hours: 30)),
          focus: FocusState.focused,
          energy: EnergyLevel.drained,
          valence: 2,
        ),
        mood(
          id: 'outside',
          timestamp: wake.add(const Duration(hours: 31)),
          focus: FocusState.paralyzed,
        ),
      ],
    );

    final rem = insights.singleWhere(
      (insight) => insight.title == copy.insightRemParalysisTitle,
    );
    expect(rem.description, contains('50%'));
    expect(rem.correlationPercentage, 50);
  });

  test('humor antes do dia do sono ou REM suficiente não gera o alerta', () {
    final wake = DateTime(2026, 9, 20);
    final before = analyze(
      sleep: [sleepOn(wake, rem: const Duration(minutes: 40))],
      moods: [
        mood(
          id: 'before',
          timestamp: wake.subtract(const Duration(hours: 1)),
          focus: FocusState.paralyzed,
          valence: 2,
        ),
      ],
    );
    expect(titled(before, copy.insightRemParalysisTitle), isFalse);
    expect(before.single.description, copy.insightCollectingDescGeneric);

    final enoughRem = analyze(
      sleep: [sleepOn(wake, rem: const Duration(minutes: 75))],
      moods: [
        mood(
          id: 'ok',
          timestamp: wake.add(const Duration(hours: 8)),
          focus: FocusState.paralyzed,
          energy: EnergyLevel.drained,
          valence: 2,
        ),
      ],
    );
    expect(titled(enoughRem, copy.insightRemParalysisTitle), isFalse);
  });

  test('HRV baixa no mesmo dia entra; 40 ms ou outro dia ficam de fora', () {
    final day = DateTime(2026, 9, 20);
    final hard = mood(
      id: 'stressed',
      timestamp: day.add(const Duration(hours: 15)),
      emotionLabels: {'stressed'},
    );

    final low = analyze(
      moods: [hard],
      recovery: [
        DailyRecoverySnapshot(date: day, hrvMs: 39.9, steps: 1000),
      ],
    );
    expect(titled(low, copy.insightHrvTitle), isTrue);
    expect(titled(low, copy.insightMovementTitle), isFalse);

    final boundary = analyze(
      moods: [hard],
      recovery: [
        DailyRecoverySnapshot(date: day, hrvMs: 40, steps: 1000),
      ],
    );
    expect(titled(boundary, copy.insightHrvTitle), isFalse);

    final otherDay = analyze(
      moods: [hard],
      recovery: [
        DailyRecoverySnapshot(
          date: day.add(const Duration(days: 1)),
          hrvMs: 20,
          steps: 1000,
        ),
      ],
    );
    expect(titled(otherDay, copy.insightHrvTitle), isFalse);
    expect(titled(otherDay, copy.insightMovementTitle), isFalse);
  });

  test('passos, luz e ruído usam o corte exato do dia', () {
    final day = DateTime(2026, 9, 21);
    final scattered = mood(
      id: 'scattered',
      timestamp: day.add(const Duration(hours: 11)),
      focus: FocusState.scattered,
      valence: 2,
      sensoryOverload: true,
    );

    final under = analyze(
      moods: [scattered],
      recovery: [
        DailyRecoverySnapshot(
          date: day,
          steps: 3999,
          timeInDaylightMinutes: 19.9,
          avgEnvironmentalDb: 69.9,
          avgHeadphoneDb: 80,
        ),
      ],
    );
    expect(titled(under, copy.insightMovementTitle), isTrue);
    expect(titled(under, copy.insightDaylightTitle), isTrue);
    expect(titled(under, copy.insightNoiseTitle), isTrue);
    expect(
      under
          .singleWhere((insight) => insight.title == copy.insightNoiseTitle)
          .description,
      contains('100%'),
    );

    final atCut = analyze(
      moods: [
        mood(
          id: 'ok-day',
          timestamp: day.add(const Duration(hours: 11)),
          focus: FocusState.scattered,
          valence: 2,
          sensoryOverload: true,
        ),
      ],
      recovery: [
        DailyRecoverySnapshot(
          date: day,
          steps: 4000,
          timeInDaylightMinutes: 20,
          avgEnvironmentalDb: 69.9,
          avgHeadphoneDb: 79.9,
        ),
      ],
    );
    expect(titled(atCut, copy.insightMovementTitle), isFalse);
    expect(titled(atCut, copy.insightDaylightTitle), isFalse);
    expect(titled(atCut, copy.insightNoiseTitle), isFalse);
  });
}
