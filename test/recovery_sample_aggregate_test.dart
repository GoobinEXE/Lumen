import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:noa/integrations/health/recovery_sample_aggregate.dart';

void main() {
  RecoverySample sample({
    required HealthDataType type,
    required DateTime start,
    DateTime? end,
    num? value,
  }) {
    return RecoverySample(
      type: type,
      start: start,
      end: end ?? start,
      value: value,
    );
  }

  test('lista vazia não inventa dia', () {
    expect(aggregateRecoverySamples(const []), isEmpty);
  });

  test('HRV do dia é a média, SDNN e RMSSD entram juntos', () {
    final day = DateTime(2026, 10, 5, 8);
    final snapshots = aggregateRecoverySamples([
      sample(
        type: HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        start: day,
        value: 30,
      ),
      sample(
        type: HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        start: day.add(const Duration(hours: 2)),
        value: 50,
      ),
    ]);

    expect(snapshots, hasLength(1));
    expect(snapshots.single.hrvMs, 40);
    expect(snapshots.single.date, DateTime(2026, 10, 5));
    expect(snapshots.single.steps, isNull);
    expect(snapshots.single.exerciseMinutes, isNull);
  });

  test('passos somam e só então arredondam', () {
    final day = DateTime(2026, 10, 5, 9);
    final snapshots = aggregateRecoverySamples([
      sample(type: HealthDataType.STEPS, start: day, value: 10.6),
      sample(
        type: HealthDataType.STEPS,
        start: day.add(const Duration(hours: 1)),
        value: 0.6,
      ),
    ]);

    expect(snapshots.single.steps, 11);
  });

  test('passo sem número não vira zero', () {
    final day = DateTime(2026, 10, 5, 9);
    final missing = aggregateRecoverySamples([
      sample(type: HealthDataType.STEPS, start: day),
    ]);
    expect(missing.single.steps, isNull);

    final recordedZero = aggregateRecoverySamples([
      sample(type: HealthDataType.STEPS, start: day, value: 0),
    ]);
    expect(recordedZero.single.steps, 0);
  });

  test('exercício soma tempo do relógio e ignora treino sem duração', () {
    final start = DateTime(2026, 10, 5, 18);
    final snapshots = aggregateRecoverySamples([
      sample(
        type: HealthDataType.EXERCISE_TIME,
        start: start,
        value: 20,
      ),
      sample(
        type: HealthDataType.WORKOUT,
        start: start,
        end: start.add(const Duration(seconds: 90)),
      ),
      sample(
        type: HealthDataType.WORKOUT,
        start: start,
        end: start,
      ),
      sample(
        type: HealthDataType.WORKOUT,
        start: start,
        end: start.subtract(const Duration(minutes: 5)),
      ),
    ]);

    expect(snapshots.single.exerciseMinutes, 21.5);
  });

  test('FC de repouso é média e o dia mais novo vem primeiro', () {
    final older = DateTime(2026, 10, 4, 7);
    final newer = DateTime(2026, 10, 6, 7);
    final snapshots = aggregateRecoverySamples([
      sample(
        type: HealthDataType.RESTING_HEART_RATE,
        start: older,
        value: 60,
      ),
      sample(
        type: HealthDataType.RESTING_HEART_RATE,
        start: older.add(const Duration(hours: 1)),
        value: 70,
      ),
      sample(
        type: HealthDataType.RESTING_HEART_RATE,
        start: newer,
        value: 55,
      ),
    ]);

    expect(snapshots.map((s) => s.date), [
      DateTime(2026, 10, 6),
      DateTime(2026, 10, 4),
    ]);
    expect(snapshots.first.restingHeartRate, 55);
    expect(snapshots.last.restingHeartRate, 65);
  });

  test('tipo fora da recuperação não vira passo nem exercício', () {
    final snapshots = aggregateRecoverySamples([
      sample(
        type: HealthDataType.HEART_RATE,
        start: DateTime(2026, 10, 5, 12),
        value: 80,
      ),
    ]);

    expect(snapshots.single.steps, isNull);
    expect(snapshots.single.exerciseMinutes, isNull);
    expect(snapshots.single.hrvMs, isNull);
    expect(snapshots.single.restingHeartRate, isNull);
  });
}
