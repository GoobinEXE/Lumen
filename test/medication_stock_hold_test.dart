import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adiar ou pular não baixa o estoque; tomar desce uma unidade', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = MedicationRepository(prefs);
    final day = DateTime(2026, 10, 5, 12);

    await repo.saveMedication(
      const Medication(
        id: 'lis',
        name: 'Lis',
        dosage: '30mg',
        scheduledTimes: ['08:00', '14:00'],
        remainingStock: 6,
        refillWarningThreshold: 5,
      ),
    );

    final logs = await repo.getLogsForDate(day);
    final morning = logs.firstWhere((log) => log.scheduledTime.hour == 8);
    final afternoon = logs.firstWhere((log) => log.scheduledTime.hour == 14);

    await repo.snoozeLog(morning.id, 20);
    await repo.skipLog(afternoon.id, 'voluntary');

    final held = (await repo.getMedications()).single;
    expect(held.remainingStock, 6);
    expect(held.needsRefillWarning, isFalse);

    await repo.markAsTaken(morning.id, DateTime(2026, 10, 5, 8, 12));

    final afterTake = (await repo.getMedications()).single;
    expect(afterTake.remainingStock, 5);
    expect(afterTake.needsRefillWarning, isTrue);

    final taken = await repo.logById(morning.id);
    final skipped = await repo.logById(afternoon.id);
    expect(taken!.isTaken, isTrue);
    expect(skipped!.skipped, isTrue);
    expect(skipped.isTaken, isFalse);
  });
}
