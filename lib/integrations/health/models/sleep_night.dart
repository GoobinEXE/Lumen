import 'sleep_record.dart';

enum SleepIntervalKind { deep, rem, light, asleep, awake }

/// Trecho de sono vindo do app de saúde, sem tipo do SDK.
class SleepInterval {
  const SleepInterval({
    required this.kind,
    required this.start,
    required this.end,
  });

  final SleepIntervalKind kind;
  final DateTime start;
  final DateTime end;

  Duration get duration {
    final span = end.difference(start);
    if (span.isNegative) return Duration.zero;
    return span;
  }
}

/// Junta as amostras da mesma noite no dia em que a pessoa acorda.
class SleepNight {
  SleepNight._();

  /// Amostra que termina à noite entra no dia seguinte.
  /// A que termina de madrugada fica no próprio dia.
  static DateTime wakeDay(DateTime end) {
    if (end.hour >= 18) {
      final next = DateTime(
        end.year,
        end.month,
        end.day,
      ).add(const Duration(days: 1));
      return DateTime(next.year, next.month, next.day);
    }
    return DateTime(end.year, end.month, end.day);
  }

  static List<SleepRecord> aggregate(List<SleepInterval> samples) {
    final byDay = <DateTime, List<SleepInterval>>{};
    for (final sample in samples) {
      if (sample.duration == Duration.zero) continue;
      final day = wakeDay(sample.end);
      byDay.putIfAbsent(day, () => []).add(sample);
    }

    final records = <SleepRecord>[];
    for (final entry in byDay.entries) {
      final points = entry.value;
      final deepSamples = <SleepInterval>[];
      final remSamples = <SleepInterval>[];
      final lightSamples = <SleepInterval>[];
      final asleepSamples = <SleepInterval>[];
      final awakeSamples = <SleepInterval>[];
      var earliest = points.first.start;
      var latest = points.first.end;

      for (final sample in points) {
        if (sample.start.isBefore(earliest)) earliest = sample.start;
        if (sample.end.isAfter(latest)) latest = sample.end;
        switch (sample.kind) {
          case SleepIntervalKind.deep:
            deepSamples.add(sample);
            break;
          case SleepIntervalKind.rem:
            remSamples.add(sample);
            break;
          case SleepIntervalKind.light:
            lightSamples.add(sample);
            break;
          case SleepIntervalKind.asleep:
            asleepSamples.add(sample);
            break;
          case SleepIntervalKind.awake:
            awakeSamples.add(sample);
            break;
        }
      }

      // Relógio e telefone mandam a mesma noite. Somar as duas infla o total
      // e esconde déficit. A união conta cada minuto uma vez.
      final deep = _union(deepSamples);
      final rem = _union(remSamples);
      final light = _union(lightSamples);
      final asleep = _union(asleepSamples);
      final awake = _union(awakeSamples);
      final stageSamples = <SleepInterval>[
        ...deepSamples,
        ...remSamples,
        ...lightSamples,
      ];
      final total = stageSamples.isNotEmpty
          ? _union(stageSamples)
          : asleep;
      if (total <= Duration.zero) continue;

      records.add(
        SleepRecord(
          date: entry.key,
          bedtime: earliest,
          wakeTime: latest,
          totalSleep: total,
          deepSleep: deep,
          remSleep: rem,
          lightSleep: light,
          awakeDuration: awake,
        ),
      );
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// Duração coberta pelos intervalos, sem contar de novo o trecho repetido.
  static Duration _union(List<SleepInterval> samples) {
    if (samples.isEmpty) return Duration.zero;
    final sorted = [...samples]..sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      if (byStart != 0) return byStart;
      return a.end.compareTo(b.end);
    });
    var start = sorted.first.start;
    var end = sorted.first.end;
    var total = Duration.zero;
    for (final sample in sorted.skip(1)) {
      if (sample.start.isAfter(end)) {
        final span = end.difference(start);
        if (!span.isNegative) total += span;
        start = sample.start;
        end = sample.end;
      } else if (sample.end.isAfter(end)) {
        end = sample.end;
      }
    }
    final span = end.difference(start);
    if (!span.isNegative) total += span;
    return total;
  }
}
