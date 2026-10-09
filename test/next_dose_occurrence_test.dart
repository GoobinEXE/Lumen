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

    test(
      'remédio com 2 horários no mesmo dia gera 2 ocorrências por dia da semana',
      () {
        final fridayMorning = DateTime(2026, 9, 25, 7);
        expect(fridayMorning.weekday, DateTime.friday);

        final slots = upcomingDoseOccurrences(
          now: fridayMorning,
          scheduledTimes: const ['08:00', '14:00'],
          daysOfWeek: const [DateTime.friday],
        );

        expect(slots, hasLength(2));
        expect(
          slots.map((slot) => slot.time).toList(),
          ['08:00', '14:00'],
        );
        expect(
          slots.every((slot) => slot.weekday == DateTime.friday),
          isTrue,
        );
        expect(slots[0].at, DateTime(2026, 9, 25, 8));
        expect(slots[1].at, DateTime(2026, 9, 25, 14));
      },
    );

    test(
      '3 horários em 2 dias da semana geram 6 ocorrências, sem duplicar',
      () {
        final mondayMorning = DateTime(2026, 9, 21, 6);
        expect(mondayMorning.weekday, DateTime.monday);

        final slots = upcomingDoseOccurrences(
          now: mondayMorning,
          scheduledTimes: const ['08:00', '14:00', '20:00'],
          daysOfWeek: const [DateTime.monday, DateTime.thursday],
        );

        expect(slots, hasLength(6));
        final uniqueMoments = slots.map((slot) => slot.at).toSet();
        expect(uniqueMoments, hasLength(6));
      },
    );
  });

  group('doseNotificationId', () {
    test('é estável para o mesmo medicamento, horário e dia da semana', () {
      final first = doseNotificationId(
        medicationId: 'med-1',
        time: '08:00',
        weekday: DateTime.monday,
      );
      final second = doseNotificationId(
        medicationId: 'med-1',
        time: '08:00',
        weekday: DateTime.monday,
      );

      expect(first, second);
    });

    test(
      'é distinto para horários diferentes do mesmo medicamento, mesmo dia',
      () {
        final morning = doseNotificationId(
          medicationId: 'med-1',
          time: '08:00',
          weekday: DateTime.monday,
        );
        final afternoon = doseNotificationId(
          medicationId: 'med-1',
          time: '14:00',
          weekday: DateTime.monday,
        );

        expect(morning, isNot(afternoon));
      },
    );

    test(
      'é distinto para o mesmo horário em dias da semana diferentes',
      () {
        final monday = doseNotificationId(
          medicationId: 'med-1',
          time: '08:00',
          weekday: DateTime.monday,
        );
        final tuesday = doseNotificationId(
          medicationId: 'med-1',
          time: '08:00',
          weekday: DateTime.tuesday,
        );

        expect(monday, isNot(tuesday));
      },
    );

    test(
      'três horários do mesmo remédio em dois dias geram 6 ids distintos',
      () {
        final times = ['08:00', '14:00', '20:00'];
        final weekdays = [DateTime.monday, DateTime.thursday];
        final ids = <int>{
          for (final time in times)
            for (final weekday in weekdays)
              doseNotificationId(
                medicationId: 'med-1',
                time: time,
                weekday: weekday,
              ),
        };

        expect(ids, hasLength(6));
      },
    );

    test('é distinto entre medicamentos diferentes, mesmo horário e dia', () {
      final medA = doseNotificationId(
        medicationId: 'med-a',
        time: '08:00',
        weekday: DateTime.monday,
      );
      final medB = doseNotificationId(
        medicationId: 'med-b',
        time: '08:00',
        weekday: DateTime.monday,
      );

      expect(medA, isNot(medB));
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
