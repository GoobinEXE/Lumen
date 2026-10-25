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

  test('dia fora da semana não abre slot e segura a dose já tomada', () {
    final saturday = DateTime(2026, 10, 10);
    final med = Medication(
      id: 'm1',
      name: 'Lis',
      dosage: '30mg',
      scheduledTimes: const ['08:00'],
      daysOfWeek: const [1, 2, 3, 4, 5],
    );
    final existing = [
      MedicationLog(
        id: 'pending',
        medicationId: 'm1',
        medicationName: 'Lis 30mg',
        scheduledTime: DateTime(2026, 10, 10, 8),
      ),
      MedicationLog(
        id: 'taken',
        medicationId: 'm1',
        medicationName: 'Lis 30mg',
        scheduledTime: DateTime(2026, 10, 10, 14),
        takenAt: DateTime(2026, 10, 10, 14, 10),
      ),
    ];

    final result = MedicationRepository.alignDayLogs(saturday, [med], existing);

    expect(result.map((log) => log.id), ['taken']);
    expect(result.single.isTaken, isTrue);
    expect(result.single.scheduledTime.hour, 14);

    final monday = MedicationRepository.alignDayLogs(
      DateTime(2026, 10, 5),
      [med],
      const [],
    );
    expect(monday, hasLength(1));
    expect(monday.single.scheduledTime, DateTime(2026, 10, 5, 8));
    expect(monday.single.isPending, isTrue);
  });

  test('lista de dias vazia não vira a semana inteira', () {
    final med = Medication(
      id: 'm1',
      name: 'Lis',
      dosage: '30mg',
      scheduledTimes: const ['08:00'],
      daysOfWeek: const [],
    );

    final result = MedicationRepository.alignDayLogs(
      DateTime(2026, 10, 5),
      [med],
      const [],
    );

    expect(result, isEmpty);
  });
}
