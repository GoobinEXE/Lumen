import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/efficacy_window.dart';

void main() {
  test('Ritalina de 4 h tem pico das 2 h às 3 h, bordas fora', () {
    final taken = DateTime(2026, 10, 1, 8);
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 4);

    expect(window.peakStart, taken.add(const Duration(hours: 2)));
    expect(window.peakEnd, taken.add(const Duration(hours: 3)));
    expect(window.crashTime, taken.add(const Duration(hours: 4)));
    expect(window.isInPeak(taken.add(const Duration(hours: 2))), isFalse);
    expect(
      window.isInPeak(taken.add(const Duration(hours: 2, seconds: 1))),
      isTrue,
    );
    expect(
      window.isInPeak(taken.add(const Duration(hours: 2, minutes: 30))),
      isTrue,
    );
    expect(window.isInPeak(taken.add(const Duration(hours: 3))), isFalse);
  });
}
