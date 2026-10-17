import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';

void main() {
  test('amostras sobrepostas da mesma noite não dobram o sono', () {
    final night = DateTime(2026, 10, 17);
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.rem,
        start: DateTime(2026, 10, 17, 2),
        end: DateTime(2026, 10, 17, 3, 30),
      ),
      SleepInterval(
        kind: SleepIntervalKind.rem,
        start: DateTime(2026, 10, 17, 2),
        end: DateTime(2026, 10, 17, 3, 30),
      ),
      SleepInterval(
        kind: SleepIntervalKind.deep,
        start: DateTime(2026, 10, 17, 3),
        end: DateTime(2026, 10, 17, 4, 30),
      ),
      SleepInterval(
        kind: SleepIntervalKind.deep,
        start: DateTime(2026, 10, 17, 3, 15),
        end: DateTime(2026, 10, 17, 5),
      ),
      SleepInterval(
        kind: SleepIntervalKind.light,
        start: DateTime(2026, 10, 17, 5),
        end: DateTime(2026, 10, 17, 7),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.date, night);
    expect(nights.single.remSleep, const Duration(hours: 1, minutes: 30));
    expect(nights.single.deepSleep, const Duration(hours: 2));
    // REM 02:00–03:30 e profundo 03:00–05:00 compartilham 03:00–03:30.
    expect(nights.single.totalSleep, const Duration(hours: 5));
    expect(nights.single.hasSleepDeficit, isTrue);
  });

  test('estágios encostados continuam somando a noite inteira', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.light,
        start: DateTime(2026, 10, 17, 1),
        end: DateTime(2026, 10, 17, 3),
      ),
      SleepInterval(
        kind: SleepIntervalKind.deep,
        start: DateTime(2026, 10, 17, 3),
        end: DateTime(2026, 10, 17, 4),
      ),
      SleepInterval(
        kind: SleepIntervalKind.rem,
        start: DateTime(2026, 10, 17, 4),
        end: DateTime(2026, 10, 17, 5, 30),
      ),
    ]);

    expect(nights.single.totalSleep, const Duration(hours: 4, minutes: 30));
    expect(nights.single.lightSleep, const Duration(hours: 2));
    expect(nights.single.deepSleep, const Duration(hours: 1));
    expect(nights.single.remSleep, const Duration(hours: 1, minutes: 30));
  });
}
