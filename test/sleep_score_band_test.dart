import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

SleepRecord night({
  required Duration totalSleep,
  Duration remSleep = Duration.zero,
  Duration deepSleep = Duration.zero,
}) {
  return SleepRecord(
    date: DateTime(2026, 10, 2),
    bedtime: DateTime(2026, 10, 1, 23),
    wakeTime: DateTime(2026, 10, 2, 8),
    totalSleep: totalSleep,
    remSleep: remSleep,
    deepSleep: deepSleep,
  );
}

void main() {
  test('6 h com 150 min restauradores nota 85 e não é déficit', () {
    final record = night(
      totalSleep: const Duration(hours: 6),
      remSleep: const Duration(minutes: 100),
      deepSleep: const Duration(minutes: 50),
    );

    expect(record.hasSleepDeficit, isFalse);
    expect(record.hasRemDeficit, isFalse);
    expect(record.qualityScore, 85);
  });

  test('5 h com 100 min de REM nota 40 e o REM não entra em déficit', () {
    final record = night(
      totalSleep: const Duration(hours: 5),
      remSleep: const Duration(minutes: 100),
    );

    expect(record.hasSleepDeficit, isTrue);
    expect(record.hasRemDeficit, isFalse);
    expect(record.qualityScore, 40);
  });

  test('9 h e 59 s ainda conta como 9 h e nota 80', () {
    final record = night(totalSleep: const Duration(hours: 9, seconds: 59));

    expect(record.totalHours, 9);
    expect(record.hasSleepDeficit, isFalse);
    expect(record.qualityScore, 80);
  });

  test('noite sem sono nota 30', () {
    final record = night(totalSleep: Duration.zero);

    expect(record.hasSleepDeficit, isTrue);
    expect(record.hasRemDeficit, isTrue);
    expect(record.qualityScore, 30);
  });
}
