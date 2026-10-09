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
  test('mental flow não inventa percentual 85', () {
    final mood = MoodEntry(
      id: '1',
      timestamp: DateTime(2026, 10, 8, 10),
      valence: 5,
      energy: EnergyLevel.balanced,
      focus: FocusState.focused,
    );
    final sleep = SleepRecord(
      date: DateTime(2026, 10, 8),
      bedtime: DateTime(2026, 10, 7, 23),
      wakeTime: DateTime(2026, 10, 8, 7),
      totalSleep: const Duration(hours: 8),
      remSleep: const Duration(hours: 2),
      deepSleep: const Duration(hours: 1),
    );
    final insights = CorrelationEngine.analyze(
      sleepRecords: [sleep],
      moodEntries: [mood],
      copy: _Copy(),
    );
    final flow = insights.where((i) => i.title == 'mt');
    expect(flow, isNotEmpty);
    expect(flow.first.correlationPercentage, 0.0);
  });

  test('HRV usa índice por dia civil', () {
    final mood = MoodEntry(
      id: '1',
      timestamp: DateTime(2026, 10, 8, 14),
      valence: 2,
      energy: EnergyLevel.drained,
      focus: FocusState.paralyzed,
      emotionLabels: const {'stressed'},
    );
    final recovery = DailyRecoverySnapshot(
      date: DateTime(2026, 10, 8),
      hrvMs: 20,
    );
    final insights = CorrelationEngine.analyze(
      sleepRecords: const [],
      moodEntries: [mood],
      recoverySnapshots: [recovery],
      copy: _Copy(),
    );
    expect(insights.any((i) => i.title == 'ht'), isTrue);
  });
}
