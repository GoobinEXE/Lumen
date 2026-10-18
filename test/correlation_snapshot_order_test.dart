import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

class _Copy implements CorrelationCopy {
  @override
  String get insightCollectingAdvice => 'a';
  @override
  String get insightCollectingDescGeneric => 'g';
  @override
  String get insightCollectingDescHealth => 'h';
  @override
  String get insightCollectingTitle => 't';
  @override
  String get insightDaylightAdvice => 'da';
  @override
  String insightDaylightDesc(String percent) => 'dd$percent';
  @override
  String get insightDaylightTitle => 'dt';
  @override
  String get insightHrvAdvice => 'ha';
  @override
  String insightHrvDesc(String percent) => 'hd$percent';
  @override
  String get insightHrvTitle => 'ht';
  @override
  String get insightMentalFlowAdvice => 'ma';
  @override
  String get insightMentalFlowDesc => 'md';
  @override
  String get insightMentalFlowTitle => 'mt';
  @override
  String get insightMovementAdvice => 'moa';
  @override
  String insightMovementDesc(String percent) => 'mod$percent';
  @override
  String get insightMovementTitle => 'mot';
  @override
  String get insightNoiseAdvice => 'na';
  @override
  String insightNoiseDesc(String percent) => 'nd$percent';
  @override
  String get insightNoiseTitle => 'nt';
  @override
  String get insightRemParalysisAdvice => 'ra';
  @override
  String insightRemParalysisDesc(String percent) => 'rd$percent';
  @override
  String get insightRemParalysisTitle => 'rt';
  @override
  String get insightSensoryAdvice => 'sa';
  @override
  String insightSensoryDesc(int count) => 'sd$count';
  @override
  String get insightSensoryTitle => 'st';
}

void main() {
  final copy = _Copy();

  SleepRecord night({
    required DateTime date,
    required int remMinutes,
  }) {
    return SleepRecord(
      date: date,
      bedtime: date.subtract(const Duration(hours: 8)),
      wakeTime: date,
      totalSleep: const Duration(hours: 7),
      remSleep: Duration(minutes: remMinutes),
    );
  }

  MoodEntry hardDay(DateTime timestamp) {
    return MoodEntry(
      id: 'm',
      timestamp: timestamp,
      valence: 2,
      energy: EnergyLevel.balanced,
      focus: FocusState.paralyzed,
    );
  }

  test('entre duas noites na janela de 30 h vale a mais nova', () {
    final older = night(
      date: DateTime(2026, 10, 2, 6),
      remMinutes: 40,
    );
    final newer = night(
      date: DateTime(2026, 10, 2, 20),
      remMinutes: 90,
    );
    final mood = hardDay(DateTime(2026, 10, 3, 1));

    final olderWinsIfFirstMatch = CorrelationEngine.analyze(
      sleepRecords: [older, newer],
      moodEntries: [mood],
      copy: copy,
    );
    expect(
      olderWinsIfFirstMatch.any((insight) => insight.title == 'rt'),
      isFalse,
    );

    final newerDeficit = CorrelationEngine.analyze(
      sleepRecords: [
        night(date: DateTime(2026, 10, 2, 6), remMinutes: 90),
        night(date: DateTime(2026, 10, 2, 20), remMinutes: 40),
      ],
      moodEntries: [mood],
      copy: copy,
    );
    final rem = newerDeficit.where((insight) => insight.title == 'rt');
    expect(rem, hasLength(1));
    expect(rem.single.correlationPercentage, 100);
  });

  test('no mesmo dia civil o último snapshot da lista decide o HRV', () {
    final mood = hardDay(DateTime(2026, 10, 8, 21));
    final low = DailyRecoverySnapshot(
      date: DateTime(2026, 10, 8, 18),
      hrvMs: 20,
    );
    final high = DailyRecoverySnapshot(
      date: DateTime(2026, 10, 8, 8),
      hrvMs: 55,
    );

    final lastIsHigh = CorrelationEngine.analyze(
      sleepRecords: const [],
      moodEntries: [mood],
      recoverySnapshots: [low, high],
      copy: copy,
    );
    expect(lastIsHigh.any((insight) => insight.title == 'ht'), isFalse);

    final lastIsLow = CorrelationEngine.analyze(
      sleepRecords: const [],
      moodEntries: [mood],
      recoverySnapshots: [high, low],
      copy: copy,
    );
    expect(lastIsLow.any((insight) => insight.title == 'ht'), isTrue);
  });
}
