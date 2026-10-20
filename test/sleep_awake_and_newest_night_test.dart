import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

void main() {
  test('tempo acordado fica no registro e não entra no total de sono', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.awake,
        start: DateTime(2026, 10, 2, 0, 50),
        end: DateTime(2026, 10, 2, 1, 30),
      ),
      SleepInterval(
        kind: SleepIntervalKind.rem,
        start: DateTime(2026, 10, 1, 23, 30),
        end: DateTime(2026, 10, 2, 0, 50),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.date, DateTime(2026, 10, 2));
    expect(nights.single.bedtime, DateTime(2026, 10, 1, 23, 30));
    expect(nights.single.wakeTime, DateTime(2026, 10, 2, 1, 30));
    expect(nights.single.totalSleep, const Duration(minutes: 80));
    expect(nights.single.remSleep, const Duration(minutes: 80));
    expect(nights.single.awakeDuration, const Duration(minutes: 40));
    expect(nights.single.hasSleepDeficit, isTrue);
    expect(nights.single.hasRemDeficit, isFalse);
  });

  test('a noite mais nova da lista decide o alerta de REM', () {
    const copy = _FixedCopy();
    final mood = MoodEntry(
      id: 'travado',
      timestamp: DateTime(2026, 10, 2, 10),
      valence: 2,
      energy: EnergyLevel.balanced,
      focus: FocusState.paralyzed,
    );

    final quiet = CorrelationEngine.analyze(
      sleepRecords: [
        _night(DateTime(2026, 10, 2), 80),
        _night(DateTime(2026, 10, 1, 8), 40),
      ],
      moodEntries: [mood],
      copy: copy,
    );
    expect(quiet.map((insight) => insight.title), ['collecting']);
    expect(quiet.single.description, 'generic');

    final recentDeficit = CorrelationEngine.analyze(
      sleepRecords: [
        _night(DateTime(2026, 10, 2), 40),
        _night(DateTime(2026, 10, 1, 8), 90),
      ],
      moodEntries: [mood],
      copy: copy,
    );
    expect(recentDeficit.map((insight) => insight.title), ['rem']);
    expect(recentDeficit.single.description, 'rem:100');
    expect(recentDeficit.single.correlationPercentage, 100);
  });
}

SleepRecord _night(DateTime date, int remMinutes) {
  return SleepRecord(
    date: date,
    bedtime: date.subtract(const Duration(hours: 8)),
    wakeTime: date,
    totalSleep: const Duration(hours: 7),
    remSleep: Duration(minutes: remMinutes),
  );
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
  String insightDaylightDesc(String percent) => 'light:$percent';

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
