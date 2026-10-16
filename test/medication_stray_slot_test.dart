import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';

void main() {
  test(
    'dose do Saúde fora do horário e tomada extra ficam; pendente solta sai',
    () {
      final day = DateTime(2026, 10, 8);
      final med = Medication(
        id: 'm1',
        name: 'Lis',
        dosage: '30mg',
        scheduledTimes: const ['08:00', '14:00'],
      );
      final logs = [
        MedicationLog(
          id: 'morning',
          medicationId: 'm1',
          medicationName: 'Lis 30mg',
          scheduledTime: DateTime(2026, 10, 8, 8),
          takenAt: DateTime(2026, 10, 8, 8, 4),
        ),
        MedicationLog(
          id: 'afternoon',
          medicationId: 'm1',
          medicationName: 'nome antigo',
          scheduledTime: DateTime(2026, 10, 8, 14),
        ),
        MedicationLog(
          id: 'apple',
          medicationId: 'm1',
          medicationName: 'Lis 30mg',
          scheduledTime: DateTime(2026, 10, 8, 11, 30),
          source: MedicationLogSource.appleHealth,
        ),
        MedicationLog(
          id: 'stray-pending',
          medicationId: 'm1',
          medicationName: 'Lis 30mg',
          scheduledTime: DateTime(2026, 10, 8, 9),
        ),
        MedicationLog(
          id: 'extra-taken',
          medicationId: 'm1',
          medicationName: 'Lis 30mg',
          scheduledTime: DateTime(2026, 10, 8, 19),
          takenAt: DateTime(2026, 10, 8, 19, 5),
        ),
      ];

      final result = MedicationRepository.alignDayLogs(day, [med], logs);

      expect(result.map((log) => log.id).toSet(), {
        'morning',
        'afternoon',
        'apple',
        'extra-taken',
      });

      final apple = result.singleWhere((log) => log.id == 'apple');
      expect(apple.scheduledTime, DateTime(2026, 10, 8, 11, 30));
      expect(apple.source, MedicationLogSource.appleHealth);
      expect(apple.isTaken, isFalse);

      final extra = result.singleWhere((log) => log.id == 'extra-taken');
      expect(extra.scheduledTime, DateTime(2026, 10, 8, 19));
      expect(extra.takenAt, DateTime(2026, 10, 8, 19, 5));

      final afternoon = result.singleWhere((log) => log.id == 'afternoon');
      expect(afternoon.medicationName, 'Lis 30mg');
      expect(afternoon.isPending, isTrue);
      expect(afternoon.scheduledTime, DateTime(2026, 10, 8, 14));
    },
  );
}
