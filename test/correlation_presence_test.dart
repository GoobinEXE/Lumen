import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/localization/correlation_copy.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
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
  }) {
    return MoodEntry(
      id: id,
      timestamp: timestamp,
      valence: valence,
      energy: energy,
      focus: focus,
    );
  }

  List<CorrelationInsight> analyze({
    List<SleepRecord> sleep = const [],
    List<MoodEntry> moods = const [],
  }) {
    return CorrelationEngine.analyze(
      sleepRecords: sleep,
      moodEntries: moods,
      copy: copy,
    );
  }

  bool titled(List<CorrelationInsight> insights, String title) {
    return insights.any((insight) => insight.title == title);
  }

  test('sono sem humor não pede para conectar o Health', () {
    final insights = analyze(
      sleep: [
        sleepOn(DateTime(2026, 9, 20), rem: const Duration(minutes: 40)),
      ],
    );

    expect(insights.single.description, copy.insightCollectingDescGeneric);
  });

  test('foco sem sono também não vira fluxo mental', () {
    final insights = analyze(
      moods: [
        mood(
          id: 'solo',
          timestamp: DateTime(2026, 9, 20, 9),
          focus: FocusState.focused,
          valence: 5,
        ),
      ],
    );

    expect(insights.single.description, copy.insightCollectingDescGeneric);
    expect(titled(insights, copy.insightMentalFlowTitle), isFalse);
  });

  test('foco estável com REM suficiente entra no fluxo e não no alerta', () {
    final wake = DateTime(2026, 9, 20);
    final insights = analyze(
      sleep: [sleepOn(wake, rem: const Duration(minutes: 80))],
      moods: [
        mood(
          id: 'ok',
          timestamp: wake.add(const Duration(hours: 8)),
          focus: FocusState.focused,
          valence: 3,
        ),
      ],
    );

    expect(insights.single.title, copy.insightMentalFlowTitle);
    expect(insights.single.correlationPercentage, 85);
    expect(titled(insights, copy.insightRemParalysisTitle), isFalse);
  });

  test('dois de três dias difíceis arredondam o alerta para 67%', () {
    final wake = DateTime(2026, 9, 20);
    final insights = analyze(
      sleep: [sleepOn(wake, rem: const Duration(minutes: 40))],
      moods: [
        mood(
          id: 'in',
          timestamp: wake.add(const Duration(hours: 1)),
          focus: FocusState.paralyzed,
          valence: 2,
        ),
        mood(
          id: 'also',
          timestamp: wake.add(const Duration(hours: 10)),
          focus: FocusState.focused,
          energy: EnergyLevel.drained,
          valence: 2,
        ),
        mood(
          id: 'before',
          timestamp: wake.subtract(const Duration(hours: 2)),
          focus: FocusState.paralyzed,
          valence: 2,
        ),
      ],
    );

    final rem = insights.singleWhere(
      (insight) => insight.title == copy.insightRemParalysisTitle,
    );
    expect(rem.description, contains('67%'));
    expect(rem.correlationPercentage, closeTo(200 / 3, 0.001));
  });
}
