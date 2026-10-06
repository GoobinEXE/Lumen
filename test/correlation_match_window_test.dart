import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

void main() {
  const copy = _FixedCopy();
  final wakeDay = DateTime(2026, 10, 1);

  SleepRecord night({int remMinutes = 40}) {
    return SleepRecord(
      date: wakeDay,
      bedtime: DateTime(2026, 9, 30, 23),
      wakeTime: DateTime(2026, 10, 1, 7),
      totalSleep: const Duration(hours: 7),
      remSleep: Duration(minutes: remMinutes),
    );
  }

  MoodEntry mood({
    required String id,
    required DateTime timestamp,
    int valence = 2,
    EnergyLevel energy = EnergyLevel.balanced,
    FocusState focus = FocusState.paralyzed,
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
    List<SleepRecord> sleepRecords = const [],
    required List<MoodEntry> moodEntries,
    List<DailyRecoverySnapshot> recoverySnapshots = const [],
  }) {
    return CorrelationEngine.analyze(
      sleepRecords: sleepRecords,
      moodEntries: moodEntries,
      recoverySnapshots: recoverySnapshots,
      copy: copy,
    );
  }

  test('paralisia até 30 h 59 min depois do dia do sono entra no REM', () {
    final insights = analyze(
      sleepRecords: [night()],
      moodEntries: [
        mood(
          id: 'dentro',
          timestamp: wakeDay.add(const Duration(hours: 30, minutes: 59)),
        ),
      ],
    );

    final rem = insights.singleWhere((insight) => insight.title == 'rem');
    expect(rem.correlationPercentage, 100);
    expect(rem.description, 'rem:100');
  });

  test('31 h depois ou antes do dia do sono não viram alerta de REM', () {
    for (final timestamp in [
      wakeDay.add(const Duration(hours: 31)),
      wakeDay.subtract(const Duration(hours: 1)),
    ]) {
      final insights = analyze(
        sleepRecords: [night()],
        moodEntries: [mood(id: 'fora', timestamp: timestamp)],
      );

      expect(insights.map((insight) => insight.title), ['collecting']);
      expect(insights.single.description, 'generic');
    }
  });

  test('sobrecarga sem noite de sono continua no resumo', () {
    final insights = analyze(
      moodEntries: [
        mood(
          id: 'barulho',
          timestamp: wakeDay.add(const Duration(hours: 15)),
          focus: FocusState.focused,
          valence: 3,
          sensoryOverload: true,
        ),
      ],
    );

    expect(insights.map((insight) => insight.title), ['sensory']);
    expect(insights.single.description, 'sensory:1');
  });

  test('valência 4 com foco disperso ainda marca fluxo, sem alerta de REM', () {
    final insights = analyze(
      sleepRecords: [night(remMinutes: 90)],
      moodEntries: [
        mood(
          id: 'bom',
          timestamp: wakeDay.add(const Duration(hours: 10)),
          valence: 4,
          focus: FocusState.scattered,
        ),
      ],
    );

    expect(insights.map((insight) => insight.title), ['flow']);
    expect(insights.single.correlationPercentage, 85);
  });

  test('triste com pouca luz conta, valência 3 sem rótulo não', () {
    final day = DateTime(2026, 10, 1, 14);
    final lowLight = DailyRecoverySnapshot(
      date: DateTime(2026, 10, 1),
      timeInDaylightMinutes: 10,
    );

    final sad = analyze(
      moodEntries: [
        mood(
          id: 'triste',
          timestamp: day,
          valence: 5,
          focus: FocusState.focused,
          emotionLabels: {'sad'},
        ),
      ],
      recoverySnapshots: [lowLight],
    );
    expect(sad.map((insight) => insight.title), contains('daylight'));
    expect(
      sad.singleWhere((insight) => insight.title == 'daylight').description,
      'daylight:100',
    );

    final neutral = analyze(
      moodEntries: [
        mood(
          id: 'neutro',
          timestamp: day,
          valence: 3,
          focus: FocusState.scattered,
        ),
      ],
      recoverySnapshots: [lowLight],
    );
    expect(neutral.map((insight) => insight.title), isNot(contains('daylight')));
  });

  test('HRV 40 e 4000 passos não disparam; o passo abaixo dispara movimento', () {
    final day = DateTime(2026, 10, 1, 14);
    final hard = mood(id: 'travado', timestamp: day);

    final atLimit = analyze(
      moodEntries: [hard],
      recoverySnapshots: [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 1),
          hrvMs: 40,
          steps: 4000,
        ),
      ],
    );
    expect(atLimit.map((insight) => insight.title), ['collecting']);

    final below = analyze(
      moodEntries: [hard],
      recoverySnapshots: [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 1),
          steps: 3999,
        ),
      ],
    );
    expect(below.map((insight) => insight.title), ['move']);
    expect(below.single.description, 'move:100');
  });

  test('ruído conta no mesmo dia e 70 dB de ambiente entram', () {
    final day = DateTime(2026, 10, 1, 14);
    final overloaded = mood(
      id: 'sensorial',
      timestamp: day,
      valence: 3,
      focus: FocusState.focused,
      sensoryOverload: true,
    );

    final sameDay = analyze(
      moodEntries: [overloaded],
      recoverySnapshots: [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 1, 23),
          avgEnvironmentalDb: 70,
          avgHeadphoneDb: 40,
        ),
      ],
    );
    expect(sameDay.map((insight) => insight.title), containsAll(['sensory', 'noise']));

    final otherDay = analyze(
      moodEntries: [overloaded],
      recoverySnapshots: [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 2),
          avgHeadphoneDb: 90,
        ),
      ],
    );
    expect(otherDay.map((insight) => insight.title), ['sensory']);
  });
}

class _FixedCopy implements CorrelationCopy {
  const _FixedCopy();

  @override
  String get insightCollectingAdvice => 'advice';

  @override
  String get insightCollectingDescGeneric => 'generic';

  @override
  String get insightCollectingDescHealth => 'health';

  @override
  String get insightCollectingTitle => 'collecting';

  @override
  String get insightDaylightAdvice => 'advice';

  @override
  String insightDaylightDesc(String percent) => 'daylight:$percent';

  @override
  String get insightDaylightTitle => 'daylight';

  @override
  String get insightHrvAdvice => 'advice';

  @override
  String insightHrvDesc(String percent) => 'hrv:$percent';

  @override
  String get insightHrvTitle => 'hrv';

  @override
  String get insightMentalFlowAdvice => 'advice';

  @override
  String get insightMentalFlowDesc => 'flow';

  @override
  String get insightMentalFlowTitle => 'flow';

  @override
  String get insightMovementAdvice => 'advice';

  @override
  String insightMovementDesc(String percent) => 'move:$percent';

  @override
  String get insightMovementTitle => 'move';

  @override
  String get insightNoiseAdvice => 'advice';

  @override
  String insightNoiseDesc(String percent) => 'noise:$percent';

  @override
  String get insightNoiseTitle => 'noise';

  @override
  String get insightRemParalysisAdvice => 'advice';

  @override
  String insightRemParalysisDesc(String percent) => 'rem:$percent';

  @override
  String get insightRemParalysisTitle => 'rem';

  @override
  String get insightSensoryAdvice => 'advice';

  @override
  String insightSensoryDesc(int count) => 'sensory:$count';

  @override
  String get insightSensoryTitle => 'sensory';
}
