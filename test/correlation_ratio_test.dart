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

MoodEntry _mood({
  required String id,
  required DateTime day,
  required FocusState focus,
  required int valence,
}) {
  return MoodEntry(
    id: id,
    timestamp: day,
    valence: valence,
    energy: EnergyLevel.balanced,
    focus: focus,
  );
}

void main() {
  test('luz só conta dia com snapshot; movimento dilui dia sem dado', () {
    final moods = [
      _mood(
        id: '1',
        day: DateTime(2026, 10, 1, 12),
        focus: FocusState.scattered,
        valence: 1,
      ),
      _mood(
        id: '2',
        day: DateTime(2026, 10, 2, 12),
        focus: FocusState.scattered,
        valence: 1,
      ),
      _mood(
        id: '3',
        day: DateTime(2026, 10, 3, 12),
        focus: FocusState.scattered,
        valence: 1,
      ),
      _mood(
        id: '4',
        day: DateTime(2026, 10, 4, 12),
        focus: FocusState.focused,
        valence: 5,
      ),
    ];
    final recovery = [
      DailyRecoverySnapshot(
        date: DateTime(2026, 10, 1),
        steps: 1000,
        timeInDaylightMinutes: 10,
      ),
      DailyRecoverySnapshot(
        date: DateTime(2026, 10, 2),
        steps: 8000,
        timeInDaylightMinutes: 40,
      ),
      DailyRecoverySnapshot(
        date: DateTime(2026, 10, 4),
        steps: 100,
        timeInDaylightMinutes: 5,
      ),
    ];

    final insights = CorrelationEngine.analyze(
      sleepRecords: const [],
      moodEntries: moods,
      recoverySnapshots: recovery,
      copy: _Copy(),
    );

    final movement = insights.singleWhere((insight) => insight.title == 'mot');
    final daylight = insights.singleWhere((insight) => insight.title == 'dt');

    // 1 de 3 dias difíceis de movimento tem poucos passos (o dia sem snapshot conta).
    expect(movement.correlationPercentage, closeTo(100 / 3, 0.001));
    expect(movement.description, 'mod33');
    // Luz ignora o dia sem snapshot: 1 de 2. O dia focado não entra no denominador.
    expect(daylight.correlationPercentage, 50);
    expect(daylight.description, 'dd50');
  });
}
