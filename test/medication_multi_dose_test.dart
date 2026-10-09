import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('remédio com 2+ horários no mesmo dia', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
    });

    test('gera dois DoseLogs com o mesmo medicationId e scheduledTime distinto', () async {
      final day = DateTime(2026, 10, 1, 15);
      await repo.saveMedication(
        const Medication(
          id: 'a',
          name: 'Venvanse',
          dosage: '30mg',
          scheduledTimes: ['08:00', '14:00'],
        ),
      );

      final logs = await repo.getLogsForDate(day);

      expect(logs, hasLength(2));
      expect(logs.every((log) => log.medicationId == 'a'), isTrue);
      expect(
        logs.map((log) => log.scheduledTime.hour).toSet(),
        {8, 14},
      );
      // ids distintos: não é o mesmo log duplicado.
      expect(logs.map((log) => log.id).toSet(), hasLength(2));
    });

    test(
      'tomar uma dose e pular a outra não clobbera o status uma da outra',
      () async {
        final day = DateTime(2026, 10, 1, 15);
        await repo.saveMedication(
          const Medication(
            id: 'a',
            name: 'Venvanse',
            dosage: '30mg',
            scheduledTimes: ['08:00', '14:00'],
          ),
        );

        final logs = await repo.getLogsForDate(day);
        final morning = logs.firstWhere((log) => log.scheduledTime.hour == 8);
        final afternoon = logs.firstWhere(
          (log) => log.scheduledTime.hour == 14,
        );

        final takenAt = DateTime(2026, 10, 1, 8, 5);
        await repo.markAsTaken(morning.id, takenAt);
        await repo.skipLog(afternoon.id, 'voluntary');

        final after = await repo.getLogsForDate(day);
        expect(after, hasLength(2));

        final afterMorning = after.firstWhere((log) => log.id == morning.id);
        final afterAfternoon = after.firstWhere(
          (log) => log.id == afternoon.id,
        );

        expect(afterMorning.isTaken, isTrue);
        expect(afterMorning.takenAt, takenAt);
        expect(afterMorning.skipped, isFalse);

        expect(afterAfternoon.skipped, isTrue);
        expect(afterAfternoon.skipReason, 'voluntary');
        expect(afterAfternoon.isTaken, isFalse);
      },
    );

    test(
      'status de slots distintos sobrevive a um novo realinhamento (resume)',
      () async {
        final day = DateTime(2026, 10, 1, 15);
        await repo.saveMedication(
          const Medication(
            id: 'a',
            name: 'Venvanse',
            dosage: '30mg',
            scheduledTimes: ['08:00', '14:00'],
          ),
        );

        final logs = await repo.getLogsForDate(day);
        final morning = logs.firstWhere((log) => log.scheduledTime.hour == 8);
        final afternoon = logs.firstWhere(
          (log) => log.scheduledTime.hour == 14,
        );

        await repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 5));
        await repo.skipLog(afternoon.id, 'voluntary');

        // Simula resume do app: chama getLogsForDate de novo, sem mudar o
        // cadastro — o realinhamento não pode trocar os status de lugar.
        final resumed = await repo.getLogsForDate(day);
        expect(resumed, hasLength(2));
        final resumedMorning = resumed.firstWhere(
          (log) => log.id == morning.id,
        );
        final resumedAfternoon = resumed.firstWhere(
          (log) => log.id == afternoon.id,
        );

        expect(resumedMorning.isTaken, isTrue);
        expect(resumedAfternoon.skipped, isTrue);
      },
    );

    test(
      'notificação da segunda dose não grava em cima da primeira já tomada',
      () async {
        final morning = DateTime(2026, 10, 1, 8);
        final evening = DateTime(2026, 10, 1, 20);
        await repo.saveMedication(
          const Medication(
            id: 'a',
            name: 'Venvanse',
            dosage: '30mg',
            scheduledTimes: ['08:00', '20:00'],
            remainingStock: 30,
          ),
        );

        // Caminho da notificação: a tela ainda não materializou os slots.
        final first = await repo.ensureDoseLog(
          medicationId: 'a',
          medicationName: 'Venvanse 30mg',
          scheduled: morning,
        );
        final morningTakenAt = DateTime(2026, 10, 1, 8, 2);
        await repo.markAsTaken(first.id, morningTakenAt);

        final second = await repo.ensureDoseLog(
          medicationId: 'a',
          medicationName: 'Venvanse 30mg',
          scheduled: evening,
        );
        expect(second.id, isNot(first.id));
        expect(second.scheduledTime.hour, 20);
        expect(second.isTaken, isFalse);

        final eveningTakenAt = DateTime(2026, 10, 1, 20, 1);
        await repo.markAsTaken(second.id, eveningTakenAt);

        final morningLog = await repo.logById(first.id);
        final eveningLog = await repo.logById(second.id);
        expect(morningLog!.isTaken, isTrue);
        expect(morningLog.takenAt, morningTakenAt);
        expect(morningLog.scheduledTime.hour, 8);
        expect(eveningLog!.isTaken, isTrue);
        expect(eveningLog.takenAt, eveningTakenAt);
        expect(eveningLog.scheduledTime.hour, 20);

        final meds = await repo.getMedications();
        expect(meds.single.remainingStock, 28);
      },
    );

    test('remédio de um horário ainda reusa o único log do dia', () async {
      await repo.saveMedication(
        const Medication(
          id: 'a',
          name: 'Venvanse',
          dosage: '30mg',
          scheduledTimes: ['08:00'],
        ),
      );
      final created = await repo.ensureDoseLog(
        medicationId: 'a',
        medicationName: 'Venvanse 30mg',
        scheduled: DateTime(2026, 10, 1, 8),
      );
      final again = await repo.ensureDoseLog(
        medicationId: 'a',
        medicationName: 'Venvanse 30mg',
        scheduled: DateTime(2026, 10, 1, 9, 30),
      );

      expect(again.id, created.id);
      expect(again.scheduledTime.hour, 8);
    });
  });
}
