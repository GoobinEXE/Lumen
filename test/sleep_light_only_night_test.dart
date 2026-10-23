import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';

void main() {
  test('noite só de sono leve conta e o bloco genérico não entra', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.light,
        start: DateTime(2026, 10, 23, 1),
        end: DateTime(2026, 10, 23, 5),
      ),
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 10, 23, 0),
        end: DateTime(2026, 10, 23, 8),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.date, DateTime(2026, 10, 23));
    expect(nights.single.lightSleep, const Duration(hours: 4));
    expect(nights.single.totalSleep, const Duration(hours: 4));
    expect(nights.single.hasSleepDeficit, isTrue);
    expect(nights.single.deepSleep, Duration.zero);
    expect(nights.single.remSleep, Duration.zero);
  });

  test('sono leve de 7 h não é déficit e estágio de duração zero some', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.light,
        start: DateTime(2026, 10, 22, 23),
        end: DateTime(2026, 10, 23, 6),
      ),
      SleepInterval(
        kind: SleepIntervalKind.deep,
        start: DateTime(2026, 10, 23, 2),
        end: DateTime(2026, 10, 23, 2),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.totalSleep, const Duration(hours: 7));
    expect(nights.single.hasSleepDeficit, isFalse);
    expect(nights.single.deepSleep, Duration.zero);
    expect(nights.single.qualityScore, 80);
  });
}
