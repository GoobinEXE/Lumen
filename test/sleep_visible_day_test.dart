import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

void main() {
  test('cochilo depois das 18h não substitui a noite que já terminou', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 5, 23),
        end: DateTime(2026, 10, 6, 7),
      ),
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 6, 19),
        end: DateTime(2026, 10, 6, 19, 30),
      ),
    ]);

    final visible = SleepNight.recordedBy(nights, DateTime(2026, 10, 6, 20));

    expect(nights.map((night) => night.date), [
      DateTime(2026, 10, 7),
      DateTime(2026, 10, 6),
    ]);
    expect(visible, hasLength(1));
    expect(visible.single.date, DateTime(2026, 10, 6));
    expect(visible.single.totalSleep, const Duration(hours: 8));
    expect(visible.single.hasSleepDeficit, isFalse);
  });

  test('o dia seguinte passa a contar quando ele chega', () {
    final nap = SleepRecord(
      date: DateTime(2026, 10, 7),
      bedtime: DateTime(2026, 10, 6, 19),
      wakeTime: DateTime(2026, 10, 6, 19, 30),
      totalSleep: const Duration(minutes: 30),
    );
    final night = SleepRecord(
      date: DateTime(2026, 10, 6),
      bedtime: DateTime(2026, 10, 5, 23),
      wakeTime: DateTime(2026, 10, 6, 7),
      totalSleep: const Duration(hours: 8),
      remSleep: const Duration(hours: 1, minutes: 20),
    );

    final visible = SleepNight.recordedBy([
      nap,
      night,
    ], DateTime(2026, 10, 7, 8));

    expect(visible.map((record) => record.date), [
      DateTime(2026, 10, 7),
      DateTime(2026, 10, 6),
    ]);
  });
}
