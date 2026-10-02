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
      var deep = Duration.zero;
      var rem = Duration.zero;
      var light = Duration.zero;
      var asleep = Duration.zero;
      var awake = Duration.zero;
      var earliest = points.first.start;
      var latest = points.first.end;

      for (final sample in points) {
        if (sample.start.isBefore(earliest)) earliest = sample.start;
        if (sample.end.isAfter(latest)) latest = sample.end;
        switch (sample.kind) {
          case SleepIntervalKind.deep:
            deep += sample.duration;
            break;
          case SleepIntervalKind.rem:
            rem += sample.duration;
            break;
          case SleepIntervalKind.light:
            light += sample.duration;
            break;
          case SleepIntervalKind.asleep:
            asleep += sample.duration;
            break;
          case SleepIntervalKind.awake:
            awake += sample.duration;
            break;
        }
      }

      final hasStages =
          deep > Duration.zero || rem > Duration.zero || light > Duration.zero;
      final total = hasStages ? deep + rem + light : asleep;
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
}
