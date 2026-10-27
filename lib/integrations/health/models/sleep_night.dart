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
      var awake = Duration.zero;
      final asleepLike = <SleepInterval>[];
      final awakeSamples = <SleepInterval>[];
      var earliest = points.first.start;
      var latest = points.first.end;

      for (final sample in points) {
        if (sample.start.isBefore(earliest)) earliest = sample.start;
        if (sample.end.isAfter(latest)) latest = sample.end;
        switch (sample.kind) {
          case SleepIntervalKind.deep:
            deep += sample.duration;
            asleepLike.add(sample);
            break;
          case SleepIntervalKind.rem:
            rem += sample.duration;
            asleepLike.add(sample);
            break;
          case SleepIntervalKind.light:
            light += sample.duration;
            asleepLike.add(sample);
            break;
          case SleepIntervalKind.asleep:
            asleepLike.add(sample);
            break;
          case SleepIntervalKind.awake:
            awake += sample.duration;
            awakeSamples.add(sample);
            break;
        }
      }

      final total = _covered(_withoutAwake(asleepLike, awakeSamples));
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

  static Duration _covered(List<SleepInterval> samples) {
    if (samples.isEmpty) return Duration.zero;
    final sorted = [...samples]
      ..sort((a, b) {
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

  static List<SleepInterval> _withoutAwake(
    List<SleepInterval> sleep,
    List<SleepInterval> awake,
  ) {
    if (awake.isEmpty) return sleep;
    final result = <SleepInterval>[];
    for (final sample in sleep) {
      result.addAll(_cut(sample, awake));
    }
    return result;
  }

  static List<SleepInterval> _cut(
    SleepInterval sample,
    List<SleepInterval> awake,
  ) {
    var pieces = <SleepInterval>[sample];
    for (final hole in awake) {
      final next = <SleepInterval>[];
      for (final piece in pieces) {
        if (!hole.end.isAfter(piece.start) || !hole.start.isBefore(piece.end)) {
          next.add(piece);
          continue;
        }
        if (hole.start.isAfter(piece.start)) {
          next.add(
            SleepInterval(
              kind: piece.kind,
              start: piece.start,
              end: hole.start,
            ),
          );
        }
        if (hole.end.isBefore(piece.end)) {
          next.add(
            SleepInterval(kind: piece.kind, start: hole.end, end: piece.end),
          );
        }
      }
      pieces = next;
    }
    return pieces;
  }
}
