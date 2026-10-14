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

  test('dose tomada no horário que saiu ocupa o slot novo sem terceira linha', () {
    final day = DateTime(2026, 10, 8);
    final med = Medication(
      id: 'm1',
      name: 'Lis',
      dosage: '30mg',
      scheduledTimes: const ['08:00', '20:00'],
    );
    final takenAt = DateTime(2026, 10, 8, 14, 10);
    final existing = [
      MedicationLog(
        id: 'morning',
        medicationId: 'm1',
        medicationName: 'Lis 30mg',
        scheduledTime: DateTime(2026, 10, 8, 8),
      ),
      MedicationLog(
        id: 'afternoon',
        medicationId: 'm1',
        medicationName: 'Lis 30mg',
        scheduledTime: DateTime(2026, 10, 8, 14),
        takenAt: takenAt,
      ),
    ];

    final result = MedicationRepository.alignDayLogs(day, [med], existing);

    expect(result, hasLength(2));
    final morning = result.singleWhere((log) => log.id == 'morning');
    final moved = result.singleWhere((log) => log.id == 'afternoon');
    expect(morning.scheduledTime, DateTime(2026, 10, 8, 8));
    expect(morning.isTaken, isFalse);
    expect(moved.scheduledTime, DateTime(2026, 10, 8, 20));
    expect(moved.takenAt, takenAt);
    expect(moved.isTaken, isTrue);
  });
}
