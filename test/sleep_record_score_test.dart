import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';

SleepRecord night({
  required Duration totalSleep,
  Duration remSleep = Duration.zero,
  Duration deepSleep = Duration.zero,
}) {
  final wake = DateTime(2026, 9, 20, 7);
  return SleepRecord(
    date: DateTime(2026, 9, 20),
    bedtime: wake.subtract(totalSleep),
    wakeTime: wake,
    totalSleep: totalSleep,
    remSleep: remSleep,
    deepSleep: deepSleep,
  );
}

void main() {
  group('limites de déficit e nota', () {
    test('6 h e 75 min de REM ainda não são déficit', () {
      final edge = night(
        totalSleep: const Duration(hours: 6),
        remSleep: const Duration(minutes: 75),
      );

      expect(edge.hasSleepDeficit, isFalse);
      expect(edge.hasRemDeficit, isFalse);
      expect(edge.qualityScore, 65);
    });

    test('um minuto abaixo dos cortes marca déficit e derruba a nota', () {
      final short = night(
        totalSleep: const Duration(hours: 5, minutes: 59),
        remSleep: const Duration(minutes: 74),
      );

      expect(short.hasSleepDeficit, isTrue);
      expect(short.hasRemDeficit, isTrue);
      expect(short.qualityScore, 30);
    });

    test('7 h e 9 h ganham a faixa cheia; 9 h 1 min volta para a faixa do meio', () {
      expect(night(totalSleep: const Duration(hours: 7)).qualityScore, 80);
      expect(night(totalSleep: const Duration(hours: 9)).qualityScore, 80);
      expect(
        night(totalSleep: const Duration(hours: 9, minutes: 1)).qualityScore,
        65,
      );
    });

    test('sono restaurador soma 10 a partir de 100 min e 20 a partir de 150', () {
      final hundred = night(
        totalSleep: const Duration(hours: 8),
        remSleep: const Duration(minutes: 100),
      );
      final justUnder = night(
        totalSleep: const Duration(hours: 8),
        remSleep: const Duration(minutes: 99),
      );
      final full = night(
        totalSleep: const Duration(hours: 8),
        remSleep: const Duration(minutes: 60),
        deepSleep: const Duration(minutes: 90),
      );

      expect(hundred.qualityScore, 90);
      expect(justUnder.qualityScore, 80);
      expect(full.qualityScore, 100);
    });

    test('mapa sem estágios zera as durações', () {
      final restored = SleepRecord.fromMap({
        'date': '2026-09-20T00:00:00.000',
        'bedtime': '2026-09-19T23:00:00.000',
        'wakeTime': '2026-09-20T07:00:00.000',
      });

      expect(restored.totalSleep, Duration.zero);
      expect(restored.remSleep, Duration.zero);
      expect(restored.hasSleepDeficit, isTrue);
      expect(restored.qualityScore, 30);
    });
  });

  group('duração legível', () {
    test('omite a parte que está zerada', () {
      expect(SleepRecord.formatDuration(const Duration(minutes: 25)), '25m');
      expect(SleepRecord.formatDuration(const Duration(hours: 7)), '7h');
      expect(
        SleepRecord.formatDuration(const Duration(hours: 7, minutes: 25)),
        '7h 25m',
      );
      expect(SleepRecord.formatDuration(Duration.zero), '0m');
    });
  });

  group('noite agregada', () {
    test('amostra que termina às 18 h cai no dia seguinte', () {
      expect(
        SleepNight.wakeDay(DateTime(2026, 10, 1, 18)),
        DateTime(2026, 10, 2),
      );
      expect(
        SleepNight.wakeDay(DateTime(2026, 10, 1, 17, 59)),
        DateTime(2026, 10, 1),
      );
    });

    test('estágio não soma o bloco adormecido e intervalo invertido some', () {
      final nights = SleepNight.aggregate([
        SleepInterval(
          kind: SleepIntervalKind.deep,
          start: DateTime(2026, 10, 1, 1),
          end: DateTime(2026, 10, 1, 2),
        ),
        SleepInterval(
          kind: SleepIntervalKind.asleep,
          start: DateTime(2026, 10, 1, 0),
          end: DateTime(2026, 10, 1, 6),
        ),
        SleepInterval(
          kind: SleepIntervalKind.awake,
          start: DateTime(2026, 10, 1, 3),
          end: DateTime(2026, 10, 1, 3, 20),
        ),
        SleepInterval(
          kind: SleepIntervalKind.rem,
          start: DateTime(2026, 10, 1, 5),
          end: DateTime(2026, 10, 1, 4),
        ),
      ]);

      expect(nights, hasLength(1));
      expect(nights.single.totalSleep, const Duration(hours: 1));
      expect(nights.single.deepSleep, const Duration(hours: 1));
      expect(nights.single.remSleep, Duration.zero);
      expect(nights.single.awakeDuration, const Duration(minutes: 20));
    });

    test('duas madrugadas viram duas noites, da mais recente para a antiga', () {
      final nights = SleepNight.aggregate([
        SleepInterval(
          kind: SleepIntervalKind.asleep,
          start: DateTime(2026, 10, 1, 23),
          end: DateTime(2026, 10, 2, 6),
        ),
        SleepInterval(
          kind: SleepIntervalKind.asleep,
          start: DateTime(2026, 10, 2, 23),
          end: DateTime(2026, 10, 3, 6),
        ),
      ]);

      expect(nights.map((item) => item.date), [
        DateTime(2026, 10, 3),
        DateTime(2026, 10, 2),
      ]);
    });
  });
}
