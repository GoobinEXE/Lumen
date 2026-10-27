import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/sleep_analytics/domain/correlation_engine.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';

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
  test('dia com snapshot sem luz dilui o percentual de luz', () {
    MoodEntry low(String id, DateTime day) {
      return MoodEntry(
        id: id,
        timestamp: day,
        valence: 1,
        energy: EnergyLevel.balanced,
        focus: FocusState.scattered,
        emotionLabels: const {},
      );
    }

    final insights = CorrelationEngine.analyze(
      sleepRecords: const [],
      moodEntries: [
        low('a', DateTime(2026, 10, 1, 12)),
        low('b', DateTime(2026, 10, 2, 12)),
        low('c', DateTime(2026, 10, 3, 12)),
      ],
      recoverySnapshots: [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 1),
          timeInDaylightMinutes: 10,
          steps: 5000,
        ),
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 2),
          steps: 6000,
        ),
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 3),
          steps: 7000,
        ),
      ],
      copy: _Copy(),
    );

    final daylight = insights.where((insight) => insight.title == 'dt');
    expect(daylight, hasLength(1));
    expect(daylight.single.correlationPercentage, closeTo(100 / 3, 0.001));
    expect(daylight.single.description, 'dd33');
    expect(insights.where((insight) => insight.title == 'ht'), isEmpty);
    expect(insights.where((insight) => insight.title == 'mot'), isEmpty);
  });
}
