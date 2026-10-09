import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';

void main() {
  test('alignDayLogs cria slots faltantes sem duplicar minuto', () {
    final day = DateTime(2026, 10, 8);
    final med = Medication(
      id: 'm1',
      name: 'Lis',
      dosage: '30mg',
      shapeIcon: 'capsule',
      scheduledTimes: const ['08:00', '08:00', '14:00'],
      daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    );
    final existing = [
      MedicationLog(
        id: 'l1',
        medicationId: 'm1',
        medicationName: 'Lis 30mg',
        scheduledTime: DateTime(2026, 10, 8, 8),
        takenAt: DateTime(2026, 10, 8, 8, 5),
      ),
    ];
    final result = MedicationRepository.alignDayLogs(day, [med], existing);
    final minutes = result.map((l) => '${l.scheduledTime.hour}:${l.scheduledTime.minute}').toSet();
    expect(minutes, {'8:0', '14:0'});
    expect(result.where((l) => l.id == 'l1').single.isTaken, isTrue);
  });
}
