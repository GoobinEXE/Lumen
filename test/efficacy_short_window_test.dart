import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/efficacy_window.dart';

void main() {
  final taken = DateTime(2026, 10, 1, 8);

  test('duração abaixo de 1 h vira janela de 1 h com pico dentro', () {
    for (final hours in [0, -4]) {
      final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: hours);

      expect(window.crashTime, taken.add(const Duration(hours: 1)));
      expect(window.peakStart.isAfter(window.takenAt), isTrue);
      expect(window.peakEnd.isAfter(window.peakStart), isTrue);
      expect(window.peakEnd.isBefore(window.crashTime), isTrue);
    }
  });

  test('janela de 5 h recalcula o fim do pico quando ele cairia antes do início', () {
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 5);

    expect(window.peakStart, taken.add(const Duration(hours: 2)));
    expect(window.peakEnd, taken.add(const Duration(hours: 3, minutes: 30)));
    expect(window.crashTime, taken.add(const Duration(hours: 5)));
  });

  test('o pico não inclui o instante de entrada nem o de saída', () {
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 12);

    expect(window.isInPeak(window.peakStart), isFalse);
    expect(window.isInPeak(window.peakEnd), isFalse);
    expect(window.isInPeak(window.takenAt), isFalse);
    expect(window.isInPeak(window.crashTime), isFalse);
    expect(
      window.isInPeak(window.peakStart.add(const Duration(minutes: 1))),
      isTrue,
    );
  });
}
