import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/service/reminder_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('upcomingDoseOccurrences', () {
    test('inclui o horário de hoje quando ainda não passou', () {
      final fridayMorning = DateTime(2026, 9, 25, 7);
      expect(fridayMorning.weekday, DateTime.friday);

      final slots = upcomingDoseOccurrences(
        now: fridayMorning,
        scheduledTimes: const ['08:00'],
        daysOfWeek: const [DateTime.friday],
      );

      expect(slots, hasLength(1));
      expect(slots.single.at, DateTime(2026, 9, 25, 8));
      expect(slots.single.weekday, DateTime.friday);
    });

    test('passa para a próxima semana se o horário de hoje já passou', () {
      final fridayLate = DateTime(2026, 9, 25, 9);
      final slots = upcomingDoseOccurrences(
        now: fridayLate,
        scheduledTimes: const ['08:00'],
        daysOfWeek: const [DateTime.friday],
      );

      expect(slots.single.at, DateTime(2026, 10, 2, 8));
    });

    test('ignora o dia de hoje quando ele não está na lista', () {
      final sunday = DateTime(2026, 9, 27, 10);
      expect(sunday.weekday, DateTime.sunday);

      final slots = upcomingDoseOccurrences(
        now: sunday,
        scheduledTimes: const ['08:00'],
        daysOfWeek: const [1, 2, 3, 4, 5],
      );

      expect(slots, hasLength(5));
      expect(slots.every((slot) => slot.at.weekday != DateTime.sunday), isTrue);
      expect(slots.first.at, DateTime(2026, 9, 28, 8));
      expect(slots.first.weekday, DateTime.monday);
    });
  });

  group('reminderLaunchIntent', () {
    final payload = ReminderPayload(
      kind: medicationDoseKind,
      medicationId: 'med-1',
      name: 'Lisdexanfetamina',
      time: '08:00',
    ).encode();

    test('toque no corpo abre remédios', () {
      expect(
        reminderLaunchIntent(
          dismissed: false,
          selectedAction: false,
          payload: payload,
        ),
        ReminderLaunchIntent.openMedications,
      );
    });

    test('Tomar grava a dose', () {
      expect(
        reminderLaunchIntent(
          dismissed: false,
          selectedAction: true,
          actionId: medicationActionTaken,
          payload: payload,
        ),
        ReminderLaunchIntent.taken,
      );
    });

    test('Adiar empurra a dose', () {
      expect(
        reminderLaunchIntent(
          dismissed: false,
          selectedAction: true,
          actionId: medicationActionSnooze,
          payload: payload,
        ),
        ReminderLaunchIntent.snooze,
      );
    });

    test('dispensar não abre nem grava', () {
      expect(
        reminderLaunchIntent(
          dismissed: true,
          selectedAction: false,
          payload: payload,
        ),
        ReminderLaunchIntent.ignore,
      );
    });
  });

  group('scheduledDoseInstant', () {
    test('confirmar de madrugada grava a dose da noite anterior', () {
      final afterMidnight = DateTime(2026, 10, 2, 0, 30);
      final scheduled = scheduledDoseInstant('22:00', afterMidnight);

      expect(scheduled, DateTime(2026, 10, 1, 22));
    });

    test('aviso adiantado no mesmo dia não cai na véspera', () {
      final justBefore = DateTime(2026, 10, 2, 7, 50);
      final scheduled = scheduledDoseInstant('08:00', justBefore);

      expect(scheduled, DateTime(2026, 10, 2, 8));
    });

    test('tomar depois do horário fica no mesmo dia', () {
      final later = DateTime(2026, 10, 2, 10);
      expect(scheduledDoseInstant('08:00', later), DateTime(2026, 10, 2, 8));
    });

    test(
      'no meio do caminho entre as duas ocorrências fica a que já passou',
      () {
        final midpoint = DateTime(2026, 10, 2, 10);
        expect(
          scheduledDoseInstant('22:00', midpoint),
          DateTime(2026, 10, 1, 22),
        );
      },
    );

    test('confirmar depois da meia-noite não marca a dose de hoje', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = MedicationRepository(prefs);
      await repo.saveMedication(
        const Medication(
          id: 'med-1',
          name: 'Venvanse',
          dosage: '30mg',
          scheduledTimes: ['22:00'],
          remainingStock: 10,
        ),
      );

      final confirmedAt = DateTime(2026, 10, 2, 0, 30);
      final scheduled = scheduledDoseInstant('22:00', confirmedAt);
      final log = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Venvanse 30mg',
        scheduled: scheduled,
      );
      await repo.markAsTaken(log.id, confirmedAt);

      final today = await repo.getLogsForDate(DateTime(2026, 10, 2, 9));
      final tonight = today.single;
      expect(tonight.scheduledTime, DateTime(2026, 10, 2, 22));
      expect(tonight.isTaken, isFalse);

      final recorded = await repo.logById(log.id);
      expect(recorded!.scheduledTime, DateTime(2026, 10, 1, 22));
      expect(recorded.isTaken, isTrue);
      expect((await repo.getMedications()).single.remainingStock, 9);
    });
  });
}
