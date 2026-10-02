/// Faixa estimada entre a dose e o fim da janela.
class EfficacyWindow {
  const EfficacyWindow({
    required this.takenAt,
    required this.peakStart,
    required this.peakEnd,
    required this.crashTime,
  });

  final DateTime takenAt;
  final DateTime peakStart;
  final DateTime peakEnd;
  final DateTime crashTime;

  /// Pico fica entre a tomada e o fim da janela, com início antes do fim.
  /// Janelas longas seguem o platô das 2 h até 4 h antes do término.
  factory EfficacyWindow.ofDose({
    required DateTime takenAt,
    required int durationHours,
  }) {
    final hours = durationHours < 1 ? 1 : durationHours;
    final crashTime = takenAt.add(Duration(hours: hours));
    final span = crashTime.difference(takenAt);
    var peakStart = takenAt.add(const Duration(hours: 2));
    if (!peakStart.isBefore(crashTime)) {
      peakStart = takenAt.add(Duration(microseconds: span.inMicroseconds ~/ 3));
    }

    var peakEnd = takenAt.add(Duration(hours: hours - 4));
    final endIsInside =
        peakEnd.isAfter(peakStart) &&
        (peakEnd.isBefore(crashTime) || peakEnd.isAtSameMomentAs(crashTime));
    if (!endIsInside) {
      final rest = crashTime.difference(peakStart);
      peakEnd = peakStart.add(Duration(microseconds: rest.inMicroseconds ~/ 2));
      if (!peakEnd.isAfter(peakStart)) peakEnd = crashTime;
    }

    return EfficacyWindow(
      takenAt: takenAt,
      peakStart: peakStart,
      peakEnd: peakEnd,
      crashTime: crashTime,
    );
  }

  bool isInPeak(DateTime now) =>
      now.isAfter(peakStart) && now.isBefore(peakEnd);
}
