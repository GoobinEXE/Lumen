import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tomar a dose adiada solta o adiamento e desconta uma vez', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = MedicationRepository(prefs);
    await repo.saveMedication(
      const Medication(
        id: 'med-1',
        name: 'Lisdexanfetamina',
        dosage: '30mg',
        scheduledTimes: ['08:00'],
        remainingStock: 4,
      ),
    );
    final log = await repo.ensureDoseLog(
      medicationId: 'med-1',
      medicationName: 'Lisdexanfetamina 30mg',
      scheduled: DateTime(2026, 10, 1, 8),
    );
    await repo.snoozeLog(log.id, 15);
    expect((await repo.logById(log.id))!.isSnoozed, isTrue);

    final takenAt = DateTime(2026, 10, 1, 8, 20);
    await repo.markAsTaken(log.id, takenAt);
    await repo.markAsTaken(log.id, DateTime(2026, 10, 1, 9));

    final saved = await repo.logById(log.id);
    expect(saved!.isTaken, isTrue);
    expect(saved.takenAt, takenAt);
    expect(saved.snoozedUntil, isNull);
    expect(saved.isSnoozed, isFalse);
    expect(saved.isPending, isFalse);
    expect((await repo.getMedications()).single.remainingStock, 3);
  });
}
