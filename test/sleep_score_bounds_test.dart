import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

void main() {
  SleepRecord night({
    required Duration totalSleep,
    Duration deepSleep = Duration.zero,
    Duration remSleep = Duration.zero,
  }) {
    return SleepRecord(
      date: DateTime(2026, 10, 8),
      bedtime: DateTime(2026, 10, 7, 23),
      wakeTime: DateTime(2026, 10, 8, 8),
      totalSleep: totalSleep,
      deepSleep: deepSleep,
      remSleep: remSleep,
    );
  }

  test('9 h ainda é a faixa ideal e 9 h 1 min cai para a do meio', () {
    expect(night(totalSleep: const Duration(hours: 9)).qualityScore, 80);
    expect(
      night(totalSleep: const Duration(hours: 9, minutes: 1)).qualityScore,
      65,
    );
  });

  test('6 h fecha o déficit e 100 min de sono restaurador entra na nota', () {
    final sixHours = night(totalSleep: const Duration(hours: 6));
    expect(sixHours.hasSleepDeficit, isFalse);
    expect(sixHours.qualityScore, 65);

    final enough = night(
      totalSleep: const Duration(hours: 8),
      deepSleep: const Duration(minutes: 40),
      remSleep: const Duration(minutes: 60),
    );
    final short = night(
      totalSleep: const Duration(hours: 8),
      deepSleep: const Duration(minutes: 40),
      remSleep: const Duration(minutes: 59),
    );

    expect(enough.qualityScore, 90);
    expect(short.qualityScore, 80);
  });

  test('duração do sono omite a parte zerada', () {
    expect(SleepRecord.formatDuration(const Duration(minutes: 25)), '25m');
    expect(SleepRecord.formatDuration(const Duration(hours: 7)), '7h');
    expect(
      SleepRecord.formatDuration(const Duration(hours: 7, minutes: 5)),
      '7h 5m',
    );
  });
}
