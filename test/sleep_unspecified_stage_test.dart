import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';

void main() {
  test('sono sem estágio entra no total junto com REM e profundo', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 27, 0),
        end: DateTime(2026, 10, 27, 4),
      ),
      SleepInterval(
        kind: SleepIntervalKind.rem,
        start: DateTime(2026, 10, 27, 4),
        end: DateTime(2026, 10, 27, 5, 30),
      ),
      SleepInterval(
        kind: SleepIntervalKind.deep,
        start: DateTime(2026, 10, 27, 5, 30),
        end: DateTime(2026, 10, 27, 6, 30),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.totalSleep, const Duration(hours: 6, minutes: 30));
    expect(nights.single.remSleep, const Duration(hours: 1, minutes: 30));
    expect(nights.single.deepSleep, const Duration(hours: 1));
    expect(nights.single.hasSleepDeficit, isFalse);
  });

  test('amostra genérica que cobre os estágios não dobra a noite', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 27, 1),
        end: DateTime(2026, 10, 27, 7),
      ),
      SleepInterval(
        kind: SleepIntervalKind.light,
        start: DateTime(2026, 10, 27, 1),
        end: DateTime(2026, 10, 27, 4),
      ),
      SleepInterval(
        kind: SleepIntervalKind.rem,
        start: DateTime(2026, 10, 27, 4),
        end: DateTime(2026, 10, 27, 5, 30),
      ),
      SleepInterval(
        kind: SleepIntervalKind.deep,
        start: DateTime(2026, 10, 27, 5, 30),
        end: DateTime(2026, 10, 27, 7),
      ),
      SleepInterval(
        kind: SleepIntervalKind.awake,
        start: DateTime(2026, 10, 27, 3),
        end: DateTime(2026, 10, 27, 3, 20),
      ),
    ]);

    expect(nights.single.totalSleep, const Duration(hours: 5, minutes: 40));
    expect(nights.single.hasSleepDeficit, isTrue);
    expect(nights.single.awakeDuration, const Duration(minutes: 20));
  });
}
