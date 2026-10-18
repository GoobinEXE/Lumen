import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';

void main() {
  test('cochilo da tarde não soma na noite nem atrasa o acordar', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 17, 23),
        end: DateTime(2026, 10, 18, 7),
      ),
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 18, 14),
        end: DateTime(2026, 10, 18, 15, 30),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.date, DateTime(2026, 10, 18));
    expect(nights.single.totalSleep, const Duration(hours: 8));
    expect(nights.single.bedtime, DateTime(2026, 10, 17, 23));
    expect(nights.single.wakeTime, DateTime(2026, 10, 18, 7));
    expect(nights.single.hasSleepDeficit, isFalse);
  });

  test('despertar de duas horas no meio da noite continua na mesma sessão', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 17, 23, 30),
        end: DateTime(2026, 10, 18, 2),
      ),
      SleepInterval(
        kind: SleepIntervalKind.deep,
        start: DateTime(2026, 10, 18, 2),
        end: DateTime(2026, 10, 18, 3),
      ),
      SleepInterval(
        kind: SleepIntervalKind.rem,
        start: DateTime(2026, 10, 18, 5),
        end: DateTime(2026, 10, 18, 6),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.totalSleep, const Duration(hours: 2));
    expect(nights.single.wakeTime, DateTime(2026, 10, 18, 6));
  });

  test('cochilo da tarde mais longo que a noite não esconde o déficit', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 18, 1),
        end: DateTime(2026, 10, 18, 6),
      ),
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 18, 12),
        end: DateTime(2026, 10, 18, 17, 30),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.totalSleep, const Duration(hours: 5));
    expect(nights.single.bedtime, DateTime(2026, 10, 18, 1));
    expect(nights.single.wakeTime, DateTime(2026, 10, 18, 6));
    expect(nights.single.hasSleepDeficit, isTrue);
  });

  test('dia só com cochilo da tarde ainda registra esse sono', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 18, 14),
        end: DateTime(2026, 10, 18, 15, 30),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.totalSleep, const Duration(hours: 1, minutes: 30));
    expect(nights.single.wakeTime, DateTime(2026, 10, 18, 15, 30));
  });
}
