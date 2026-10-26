import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'aviso das 20:00 não reaproveita a tomada nem a pulada e o estoque zerado não fica negativo',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = MedicationRepository(prefs);
      await repo.saveMedication(
        const Medication(
          id: 'med-1',
          name: 'Lisdexanfetamina',
          dosage: '30mg',
          scheduledTimes: ['08:00', '14:00'],
          totalStock: 1,
          remainingStock: 1,
          refillWarningThreshold: 0,
        ),
      );

      final day = DateTime(2026, 10, 1, 12);
      final seeded = await repo.getLogsForDate(day);
      final morning = seeded.firstWhere((log) => log.scheduledTime.hour == 8);
      final afternoon = seeded.firstWhere(
        (log) => log.scheduledTime.hour == 14,
      );
      final takenAt = DateTime(2026, 10, 1, 8, 5);
      await repo.markAsTaken(morning.id, takenAt);
      await repo.skipLog(afternoon.id, 'voluntary');

      final medsAfterMorning = await repo.getMedications();
      expect(medsAfterMorning.single.remainingStock, 0);

      final evening = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Lisdexanfetamina 30mg',
        scheduled: DateTime(2026, 10, 1, 20),
      );

      expect(evening.id, isNot(morning.id));
      expect(evening.id, isNot(afternoon.id));
      expect(evening.scheduledTime, DateTime(2026, 10, 1, 20));
      expect(evening.isPending, isTrue);

      final eveningTakenAt = DateTime(2026, 10, 1, 20, 2);
      await repo.markAsTaken(evening.id, eveningTakenAt);

      final storedEvening = await repo.logById(evening.id);
      final storedMorning = await repo.logById(morning.id);
      final storedAfternoon = await repo.logById(afternoon.id);
      final meds = await repo.getMedications();

      expect(storedEvening!.isTaken, isTrue);
      expect(storedEvening.takenAt, eveningTakenAt);
      expect(storedEvening.skipped, isFalse);
      expect(storedMorning!.scheduledTime, DateTime(2026, 10, 1, 8));
      expect(storedMorning.takenAt, takenAt);
      expect(storedMorning.skipped, isFalse);
      expect(storedAfternoon!.scheduledTime, DateTime(2026, 10, 1, 14));
      expect(storedAfternoon.skipped, isTrue);
      expect(storedAfternoon.skipReason, 'voluntary');
      expect(storedAfternoon.isTaken, isFalse);
      expect(meds.single.remainingStock, 0);
      expect((await repo.getAllLogs()).map((log) => log.id).toSet(), {
        morning.id,
        afternoon.id,
        evening.id,
      });
    },
  );
}
