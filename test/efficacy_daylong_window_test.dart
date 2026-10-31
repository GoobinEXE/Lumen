import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/efficacy_window.dart';

void main() {
  test('Atentah de 24 h segura o platô das 2 h até 4 h antes do fim', () {
    final taken = DateTime(2026, 10, 1, 8);
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 24);

    expect(window.peakStart, taken.add(const Duration(hours: 2)));
    expect(window.peakEnd, taken.add(const Duration(hours: 20)));
    expect(window.crashTime, taken.add(const Duration(hours: 24)));
    expect(window.isInPeak(taken), isFalse);
    expect(window.isInPeak(window.peakStart), isFalse);
    expect(
      window.isInPeak(window.peakStart.add(const Duration(seconds: 1))),
      isTrue,
    );
    expect(
      window.isInPeak(window.peakEnd.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(window.isInPeak(window.peakEnd), isFalse);
    expect(window.isInPeak(window.crashTime), isFalse);
  });
}
