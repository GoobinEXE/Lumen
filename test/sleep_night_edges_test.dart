import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';

void main() {
  SleepInterval sample({
    required SleepIntervalKind kind,
    required DateTime start,
    required DateTime end,
  }) {
    return SleepInterval(kind: kind, start: start, end: end);
  }

  test('amostra que termina às 18h cai no dia seguinte', () {
    final nights = SleepNight.aggregate([
      sample(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 1, 16),
        end: DateTime(2026, 10, 1, 18),
      ),
    ]);

    expect(nights.single.date, DateTime(2026, 10, 2));
    expect(nights.single.totalSleep, const Duration(hours: 2));
  });

  test('amostra que termina às 17h59 fica no mesmo dia', () {
    final nights = SleepNight.aggregate([
      sample(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 1, 16),
        end: DateTime(2026, 10, 1, 17, 59),
      ),
    ]);

    expect(nights.single.date, DateTime(2026, 10, 1));
  });

  test('31 de janeiro às 22h vira 1º de fevereiro', () {
    final nights = SleepNight.aggregate([
      sample(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 1, 31, 21),
        end: DateTime(2026, 1, 31, 22),
      ),
    ]);

    expect(nights.single.date, DateTime(2026, 2, 1));
  });

  test('intervalo invertido e noite só acordada não viram registro', () {
    final nights = SleepNight.aggregate([
      sample(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 1, 6),
        end: DateTime(2026, 10, 1, 2),
      ),
      sample(
        kind: SleepIntervalKind.awake,
        start: DateTime(2026, 10, 2, 3),
        end: DateTime(2026, 10, 2, 4),
      ),
    ]);

    expect(nights, isEmpty);
  });

  test('estágio não soma de novo o bloco genérico de adormecido', () {
    final nights = SleepNight.aggregate([
      sample(
        kind: SleepIntervalKind.deep,
        start: DateTime(2026, 10, 2, 1),
        end: DateTime(2026, 10, 2, 2),
      ),
      sample(
        kind: SleepIntervalKind.rem,
        start: DateTime(2026, 10, 2, 2),
        end: DateTime(2026, 10, 2, 2, 30),
      ),
      sample(
        kind: SleepIntervalKind.light,
        start: DateTime(2026, 10, 2, 2, 30),
        end: DateTime(2026, 10, 2, 3, 30),
      ),
      sample(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 2, 0),
        end: DateTime(2026, 10, 2, 8),
      ),
      sample(
        kind: SleepIntervalKind.awake,
        start: DateTime(2026, 10, 2, 3, 30),
        end: DateTime(2026, 10, 2, 3, 45),
      ),
    ]);

    expect(nights.single.totalSleep, const Duration(hours: 2, minutes: 30));
    expect(nights.single.deepSleep, const Duration(hours: 1));
    expect(nights.single.remSleep, const Duration(minutes: 30));
    expect(nights.single.lightSleep, const Duration(hours: 1));
    expect(nights.single.awakeDuration, const Duration(minutes: 15));
  });

  test('duas noites saem da mais nova para a mais antiga', () {
    final nights = SleepNight.aggregate([
      sample(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 1, 1),
        end: DateTime(2026, 10, 1, 6),
      ),
      sample(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 3, 1),
        end: DateTime(2026, 10, 3, 7),
      ),
    ]);

    expect(nights.map((night) => night.date), [
      DateTime(2026, 10, 3),
      DateTime(2026, 10, 1),
    ]);
  });
}
