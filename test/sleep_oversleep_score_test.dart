import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

void main() {
  SleepRecord night(
    Duration total, {
    Duration deep = Duration.zero,
    Duration rem = Duration.zero,
  }) {
    return SleepRecord(
      date: DateTime(2026, 10, 8),
      bedtime: DateTime(2026, 10, 7, 22),
      wakeTime: DateTime(2026, 10, 8, 8),
      totalSleep: total,
      deepSleep: deep,
      remSleep: rem,
    );
  }

  test('9 h com 150 min restauradores nota 100 e não é déficit', () {
    final record = night(
      const Duration(hours: 9),
      deep: const Duration(minutes: 80),
      rem: const Duration(minutes: 70),
    );

    expect(record.totalHours, 9);
    expect(record.hasSleepDeficit, isFalse);
    expect(record.qualityScore, 100);
  });

  test('9 h 1 min com os mesmos 150 min perde a faixa ideal e nota 85', () {
    final record = night(
      const Duration(hours: 9, minutes: 1),
      deep: const Duration(minutes: 80),
      rem: const Duration(minutes: 70),
    );

    expect(record.hasSleepDeficit, isFalse);
    expect(record.qualityScore, 85);
  });
}
