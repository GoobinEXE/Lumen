import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';

void main() {
  test('cochilo que acaba às 18h soma na noite e pode tirar o déficit', () {
    // Sozinho, o bloco da madrugada fica abaixo de 6 h. O cochilo que
    // termina às 18h cai no mesmo dia de acordar e entra na soma.
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 18, 17, 10),
        end: DateTime(2026, 10, 18, 18),
      ),
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 19, 0, 40),
        end: DateTime(2026, 10, 19, 6),
      ),
      SleepInterval(
        kind: SleepIntervalKind.awake,
        start: DateTime(2026, 10, 19, 6),
        end: DateTime(2026, 10, 19, 6, 30),
      ),
    ]);

    expect(nights, hasLength(1));
    final night = nights.single;
    expect(night.date, DateTime(2026, 10, 19));
    expect(night.bedtime, DateTime(2026, 10, 18, 17, 10));
    expect(night.wakeTime, DateTime(2026, 10, 19, 6, 30));
    expect(night.totalSleep, const Duration(hours: 6, minutes: 10));
    expect(night.awakeDuration, const Duration(minutes: 30));
    expect(night.hasSleepDeficit, isFalse);
  });

  test('cochilo que acaba às 17h59 fica no dia e a noite segue em déficit', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 18, 17, 10),
        end: DateTime(2026, 10, 18, 17, 59),
      ),
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 19, 0, 40),
        end: DateTime(2026, 10, 19, 6),
      ),
    ]);

    expect(nights, hasLength(2));
    expect(nights.first.date, DateTime(2026, 10, 19));
    expect(nights.first.bedtime, DateTime(2026, 10, 19, 0, 40));
    expect(nights.first.totalSleep, const Duration(hours: 5, minutes: 20));
    expect(nights.first.hasSleepDeficit, isTrue);
    expect(nights.last.date, DateTime(2026, 10, 18));
    expect(nights.last.totalSleep, const Duration(minutes: 49));
  });
}
