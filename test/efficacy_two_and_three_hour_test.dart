import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/efficacy_window.dart';

void main() {
  final taken = DateTime(2026, 10, 8, 8);

  test('janela de 2 h reparte o pico dentro da dose', () {
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 2);

    expect(window.crashTime, taken.add(const Duration(hours: 2)));
    expect(window.peakStart, taken.add(const Duration(minutes: 40)));
    expect(window.peakEnd, taken.add(const Duration(minutes: 80)));
    expect(window.isInPeak(taken.add(const Duration(minutes: 40))), isFalse);
    expect(window.isInPeak(taken.add(const Duration(minutes: 60))), isTrue);
    expect(window.isInPeak(taken.add(const Duration(minutes: 80))), isFalse);
  });

  test('janela de 3 h começa o pico às 2 h e termina às 2 h 30', () {
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 3);

    expect(window.crashTime, taken.add(const Duration(hours: 3)));
    expect(window.peakStart, taken.add(const Duration(hours: 2)));
    expect(window.peakEnd, taken.add(const Duration(minutes: 150)));
    expect(window.isInPeak(taken.add(const Duration(hours: 2))), isFalse);
    expect(window.isInPeak(taken.add(const Duration(minutes: 135))), isTrue);
    expect(window.isInPeak(taken.add(const Duration(minutes: 150))), isFalse);
  });
}
