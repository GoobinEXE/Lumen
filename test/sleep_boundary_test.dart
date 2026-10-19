import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

SleepRecord nightOf(Duration total) {
  return SleepRecord(
    date: DateTime(2026, 10, 8),
    bedtime: DateTime(2026, 10, 7, 23),
    wakeTime: DateTime(2026, 10, 8, 7),
    totalSleep: total,
  );
}

void main() {
  test('6 h 59 continua abaixo do ideal e 7 h entra na faixa', () {
    final almost = nightOf(const Duration(hours: 6, minutes: 59));
    final seven = nightOf(const Duration(hours: 7));

    expect(almost.hasSleepDeficit, isFalse);
    expect(almost.qualityScore, 65);
    expect(seven.hasSleepDeficit, isFalse);
    expect(seven.qualityScore, 80);
  });

  test('29 de fevereiro junta a noite que termina às 22 h com a manhã', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2024, 2, 28, 21),
        end: DateTime(2024, 2, 28, 22, 30),
      ),
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2024, 2, 29, 5),
        end: DateTime(2024, 2, 29, 6, 30),
      ),
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2024, 2, 28, 16),
        end: DateTime(2024, 2, 28, 17, 59),
      ),
    ]);

    expect(nights, hasLength(2));
    expect(nights.first.date, DateTime(2024, 2, 29));
    expect(nights.first.bedtime, DateTime(2024, 2, 28, 21));
    expect(nights.first.wakeTime, DateTime(2024, 2, 29, 6, 30));
    expect(nights.first.totalSleep, const Duration(hours: 3));
    expect(nights.last.date, DateTime(2024, 2, 28));
    expect(nights.last.totalSleep, const Duration(hours: 1, minutes: 59));
  });

  test('ano comum manda o fim das 22 h de 28/fev para 1º de março', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2023, 2, 28, 21),
        end: DateTime(2023, 2, 28, 22, 30),
      ),
    ]);

    expect(nights.single.date, DateTime(2023, 3, 1));
    expect(nights.single.bedtime, DateTime(2023, 2, 28, 21));
  });
}
