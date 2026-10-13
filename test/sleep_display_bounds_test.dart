import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

void main() {
  SleepRecord night({
    required Duration total,
    Duration deep = Duration.zero,
    Duration rem = Duration.zero,
    int? heartRate,
  }) {
    return SleepRecord(
      date: DateTime(2026, 10, 13),
      bedtime: DateTime(2026, 10, 12, 23),
      wakeTime: DateTime(2026, 10, 13, 7),
      totalSleep: total,
      deepSleep: deep,
      remSleep: rem,
      averageHeartRate: heartRate,
    );
  }

  test('duração da noite aparece em horas e minutos', () {
    expect(SleepRecord.formatDuration(Duration.zero), '0m');
    expect(SleepRecord.formatDuration(const Duration(minutes: 25)), '25m');
    expect(SleepRecord.formatDuration(const Duration(hours: 2)), '2h');
    expect(
      SleepRecord.formatDuration(const Duration(hours: 7, minutes: 25)),
      '7h 25m',
    );
  });

  test('150 min restauradores no sono de 8 h chega a 100; 149 fica em 90', () {
    final ceiling = night(
      total: const Duration(hours: 8),
      deep: const Duration(minutes: 90),
      rem: const Duration(minutes: 60),
    );
    final justUnder = night(
      total: const Duration(hours: 8),
      deep: const Duration(minutes: 90),
      rem: const Duration(minutes: 59),
    );

    expect(ceiling.qualityScore, 100);
    expect(justUnder.qualityScore, 90);
  });

  test('noite curta com REM suficiente não sobe para a faixa das 7 h', () {
    final short = night(
      total: const Duration(hours: 5, minutes: 59),
      deep: const Duration(minutes: 70),
      rem: const Duration(minutes: 80),
    );

    expect(short.hasSleepDeficit, isTrue);
    expect(short.hasRemDeficit, isFalse);
    expect(short.qualityScore, 50);
  });

  test('JSON antigo sem batimento não inventa frequência cardíaca', () {
    final restored = SleepRecord.fromMap({
      'date': '2026-10-13T00:00:00.000',
      'bedtime': '2026-10-12T23:00:00.000',
      'wakeTime': '2026-10-13T07:00:00.000',
      'totalSleepMinutes': 480,
    });

    expect(restored.averageHeartRate, isNull);
    expect(restored.totalSleep, const Duration(hours: 8));

    final withRate = night(
      total: const Duration(hours: 8),
      heartRate: 61,
    );
    expect(SleepRecord.fromMap(withRate.toMap()).averageHeartRate, 61);
  });

  test('média de batimentos usa só a noite e arredonda uma vez', () {
    final start = DateTime(2026, 10, 12, 23);
    final end = DateTime(2026, 10, 13, 7);
    final bpm = SleepRecord.averageHeartRateBpm(
      samples: [
        HeartRateSample(
          at: start.subtract(const Duration(minutes: 1)),
          bpm: 120,
        ),
        HeartRateSample(at: start, bpm: 70),
        HeartRateSample(at: DateTime(2026, 10, 13, 3), bpm: null),
        HeartRateSample(at: end, bpm: 71),
        HeartRateSample(
          at: end.add(const Duration(milliseconds: 1)),
          bpm: 40,
        ),
      ],
      start: start,
      end: end,
    );

    // 70 e 71 entram; 70,5 arredonda para 71. 120 e 40 ficam fora da noite.
    expect(bpm, 71);
    expect(
      SleepRecord.averageHeartRateBpm(
        samples: const [],
        start: start,
        end: end,
      ),
      isNull,
    );
    expect(
      SleepRecord.averageHeartRateBpm(
        samples: [
          HeartRateSample(
            at: start.subtract(const Duration(seconds: 1)),
            bpm: 60,
          ),
        ],
        start: start,
        end: end,
      ),
      isNull,
    );
  });
}
