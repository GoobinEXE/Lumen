import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/efficacy_window.dart';
import 'package:noa/features/medications/domain/medication.dart';

void main() {
  test('janela padrão de 10 h pico das 2 h às 6 h e a borda fica fora', () {
    final taken = DateTime(2026, 10, 1, 8);
    expect(
      const Medication(
        id: 'm',
        name: 'Lisdexanfetamina',
        dosage: '30mg',
        scheduledTimes: ['08:00'],
      ).durationHours,
      10,
    );

    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 10);

    expect(window.peakStart, taken.add(const Duration(hours: 2)));
    expect(window.peakEnd, taken.add(const Duration(hours: 6)));
    expect(window.crashTime, taken.add(const Duration(hours: 10)));
    expect(window.isInPeak(taken.add(const Duration(hours: 2))), isFalse);
    expect(
      window.isInPeak(taken.add(const Duration(hours: 2, minutes: 1))),
      isTrue,
    );
    expect(
      window.isInPeak(taken.add(const Duration(hours: 5, minutes: 59))),
      isTrue,
    );
    expect(window.isInPeak(taken.add(const Duration(hours: 6))), isFalse);
    expect(window.isInPeak(window.crashTime), isFalse);
  });

  test('janela de 8 h fecha o pico 4 h antes do crash', () {
    final taken = DateTime(2026, 10, 1, 8);
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 8);

    expect(window.peakStart, taken.add(const Duration(hours: 2)));
    expect(window.peakEnd, taken.add(const Duration(hours: 4)));
    expect(window.crashTime, taken.add(const Duration(hours: 8)));
    expect(
      window.crashTime.difference(window.peakEnd),
      const Duration(hours: 4),
    );
  });
}
