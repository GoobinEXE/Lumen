import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/service/reminder_schedule.dart';

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
}
