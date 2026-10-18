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

  /// Intervalo maior que isso abre outra sessão (cochilo), fora da noite.
  static const Duration sessionGap = Duration(hours: 3);

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
      final night = _mainSession(entry.key, entry.value);
      if (night != null) records.add(night);
    }

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  /// A noite é a sessão mais longa que começa antes do meio-dia.
  /// Cochilo da tarde só vira o registro do dia quando não houve noite.
  static SleepRecord? _mainSession(DateTime day, List<SleepInterval> points) {
    final built = <SleepRecord>[];
    for (final session in _sessions(points)) {
      final record = _record(day, session);
      if (record != null) built.add(record);
    }
    if (built.isEmpty) return null;

    final nights = built
        .where((record) => _startsAsNight(day, record))
        .toList();
    final pool = nights.isNotEmpty ? nights : built;
    SleepRecord? best;
    for (final record in pool) {
      if (best == null ||
          record.totalSleep > best.totalSleep ||
          (record.totalSleep == best.totalSleep &&
              record.bedtime.isBefore(best.bedtime))) {
        best = record;
      }
    }
    return best;
  }

  static bool _startsAsNight(DateTime day, SleepRecord record) {
    if (record.bedtime.isBefore(day)) return true;
    return record.bedtime.hour < 12;
  }

  /// Sessões separadas quando o próximo trecho começa depois do intervalo.
  static List<List<SleepInterval>> _sessions(List<SleepInterval> points) {
    final sorted = [...points]..sort((a, b) => a.start.compareTo(b.start));
    final sessions = <List<SleepInterval>>[];
    var current = <SleepInterval>[];
    DateTime? sessionEnd;
    for (final sample in sorted) {
      if (sessionEnd != null &&
          sample.start.difference(sessionEnd) > sessionGap) {
        sessions.add(current);
        current = <SleepInterval>[];
        sessionEnd = null;
      }
      current.add(sample);
      if (sessionEnd == null || sample.end.isAfter(sessionEnd)) {
        sessionEnd = sample.end;
      }
    }
    if (current.isNotEmpty) sessions.add(current);
    return sessions;
  }

  static SleepRecord? _record(DateTime day, List<SleepInterval> points) {
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
    if (total <= Duration.zero) return null;

    return SleepRecord(
      date: day,
      bedtime: earliest,
      wakeTime: latest,
      totalSleep: total,
      deepSleep: deep,
      remSleep: rem,
      lightSleep: light,
      awakeDuration: awake,
    );
  }
}
