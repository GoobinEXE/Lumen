import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/efficacy_window.dart';

void main() {
  test('janela de 6 h usa o meio do resto e a de 7 h volta ao platô', () {
    final taken = DateTime(2026, 10, 1, 8);
    final six = EfficacyWindow.ofDose(takenAt: taken, durationHours: 6);
    final seven = EfficacyWindow.ofDose(takenAt: taken, durationHours: 7);

    expect(six.peakStart, taken.add(const Duration(hours: 2)));
    expect(six.peakEnd, taken.add(const Duration(hours: 4)));
    expect(six.crashTime, taken.add(const Duration(hours: 6)));
    expect(six.isInPeak(taken.add(const Duration(hours: 3))), isTrue);
    expect(six.isInPeak(six.peakEnd), isFalse);

    expect(seven.peakStart, taken.add(const Duration(hours: 2)));
    expect(seven.peakEnd, taken.add(const Duration(hours: 3)));
    expect(seven.crashTime, taken.add(const Duration(hours: 7)));
    expect(seven.isInPeak(taken.add(const Duration(hours: 2, minutes: 30))), isTrue);
    expect(seven.isInPeak(seven.peakEnd), isFalse);
  });
}
