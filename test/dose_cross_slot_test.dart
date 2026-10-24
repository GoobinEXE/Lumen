import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/medications/presentation/providers/medication_providers.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dois remédios no mesmo minuto não se apagam na mescla do Saúde', () {
    final morning = DateTime(2026, 10, 5, 8);
    final existing = [
      MedicationLog(
        id: 'local-a',
        medicationId: 'med-a',
        medicationName: 'Venvanse 30mg',
        scheduledTime: morning,
        takenAt: morning.add(const Duration(minutes: 2)),
      ),
    ];

    final merged = mergeDoseEventsIntoLogs(
      medicationId: 'med-b',
      medicationName: 'Ritalina 10mg',
      existing: existing,
      events: [
        HealthKitDoseEvent(
          appleConceptId: 'c-b',
          status: 'taken',
          loggedAt: DateTime(2026, 10, 5, 8, 0, 50),
        ),
      ],
    );

    expect(merged, hasLength(2));
    expect(merged.first.id, 'local-a');
    final imported = merged.last;
    expect(imported.medicationId, 'med-b');
    expect(imported.isTaken, isTrue);
    expect(imported.source, MedicationLogSource.appleHealth);
  });

  test('dois horários já tomados não absorvem o terceiro minuto', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = MedicationRepository(prefs);
    final day = DateTime(2026, 10, 1, 15);

    await repo.saveMedication(
      const Medication(
        id: 'a',
        name: 'Venvanse',
        dosage: '30mg',
        scheduledTimes: ['08:00', '14:00'],
        totalStock: 5,
        remainingStock: 5,
      ),
    );

    final slots = await repo.getLogsForDate(day);
    final morning = slots.firstWhere((log) => log.scheduledTime.hour == 8);
    final afternoon = slots.firstWhere((log) => log.scheduledTime.hour == 14);
    await repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 4));
    await repo.markAsTaken(afternoon.id, DateTime(2026, 10, 1, 14, 6));

    final created = await repo.ensureDoseLog(
      medicationId: 'a',
      medicationName: 'Venvanse 30mg',
      scheduled: DateTime(2026, 10, 1, 20),
    );

    expect(created.id, isNot(morning.id));
    expect(created.id, isNot(afternoon.id));
    expect(created.scheduledTime.hour, 20);
    expect(created.isTaken, isFalse);

    await repo.markAsTaken(created.id, DateTime(2026, 10, 1, 20, 3));

    final meds = await repo.getMedications();
    expect(meds.single.remainingStock, 2);
    expect(
      (await repo.logById(morning.id))!.takenAt,
      DateTime(2026, 10, 1, 8, 4),
    );
    expect((await repo.logById(created.id))!.isTaken, isTrue);
  });

  test(
    'adiar o horário que saiu não some quando o outro slot já está coberto',
    () {
      final day = DateTime(2026, 10, 5);
      final snoozeUntil = DateTime(2026, 10, 5, 23);
      final med = Medication(
        id: 'm1',
        name: 'Lis',
        dosage: '30mg',
        scheduledTimes: const ['08:00'],
      );
      final result = MedicationRepository.alignDayLogs(
        day,
        [med],
        [
          MedicationLog(
            id: 'morn',
            medicationId: 'm1',
            medicationName: 'Lis 30mg',
            scheduledTime: DateTime(2026, 10, 5, 8),
          ),
          MedicationLog(
            id: 'night',
            medicationId: 'm1',
            medicationName: 'Lis 30mg',
            scheduledTime: DateTime(2026, 10, 5, 21),
            snoozedUntil: snoozeUntil,
          ),
        ],
      );

      expect(result.map((log) => log.id).toSet(), {'morn', 'night'});
      final night = result.firstWhere((log) => log.id == 'night');
      expect(night.scheduledTime, DateTime(2026, 10, 5, 21));
      expect(night.snoozedUntil, snoozeUntil);
      expect(result.firstWhere((log) => log.id == 'morn').isPending, isTrue);
    },
  );
}
