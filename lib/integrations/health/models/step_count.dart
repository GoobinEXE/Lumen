/// Trecho de passos de uma fonte (relógio, telefone ou app).
class StepContribution {
  const StepContribution({
    required this.sourceKey,
    required this.count,
    required this.start,
    required this.end,
  });

  /// Dispositivo ou app. Vazio agrupa amostras sem origem identificada.
  final String sourceKey;
  final double count;
  final DateTime start;
  final DateTime end;
}

/// Passos do dia sem contar duas vezes o mesmo passeio.
///
/// Relógio e telefone gravam o mesmo intervalo. Somar as fontes dobra o
/// total e esconde o dia parado. Cada fonte soma os próprios trechos; se
/// os intervalos se cruzam, fica a fonte com mais passos. Trechos que não
/// se cruzam (manhã no telefone, tarde no relógio) continuam somando.
int? dedupedStepCount(Iterable<StepContribution> samples) {
  final bySource = <String, _SourceRollup>{};
  for (final sample in samples) {
    if (sample.count <= 0 || !sample.count.isFinite) continue;
    final start = sample.start;
    final end = sample.end.isBefore(start) ? start : sample.end;
    bySource
        .putIfAbsent(sample.sourceKey.trim(), () => _SourceRollup())
        .add(count: sample.count, start: start, end: end);
  }
  if (bySource.isEmpty) return null;

  final sources = bySource.values.toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  final accepted = <_SourceRollup>[];
  for (final source in sources) {
    final overlaps = accepted.any((other) => source.overlaps(other));
    if (!overlaps) accepted.add(source);
  }

  var total = 0.0;
  for (final source in accepted) {
    total += source.count;
  }
  return total.round();
}

class _SourceRollup {
  double count = 0;
  DateTime? start;
  DateTime? end;

  void add({
    required double count,
    required DateTime start,
    required DateTime end,
  }) {
    this.count += count;
    final currentStart = this.start;
    final currentEnd = this.end;
    if (currentStart == null || start.isBefore(currentStart)) {
      this.start = start;
    }
    if (currentEnd == null || end.isAfter(currentEnd)) {
      this.end = end;
    }
  }

  bool overlaps(_SourceRollup other) {
    final aStart = start;
    final aEnd = end;
    final bStart = other.start;
    final bEnd = other.end;
    if (aStart == null || aEnd == null || bStart == null || bEnd == null) {
      return false;
    }
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }
}
