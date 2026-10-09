import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:noa/features/tasks/domain/task_quiet_hours.dart';
import 'package:noa/features/tasks/domain/task_reminder_schedule.dart';

void main() {
  group('TaskPeriod.window', () {
    test('daily usa o dia civil e não empilha ontem', () {
      final now = DateTime(2026, 10, 3, 15);
      final window = TaskPeriod.window(
        recurrence: TaskRecurrence.daily,
        now: now,
      );
      expect(window.periodKey, '2026-10-03');
      expect(window.start, DateTime(2026, 10, 3));
      expect(window.end, DateTime(2026, 10, 4));
    });

    test('weekly é seg–dom e muda a chave na segunda', () {
      final thursday = DateTime(2026, 10, 1, 12); // quinta
      final sunday = DateTime(2026, 10, 4, 20);
      final monday = DateTime(2026, 10, 5, 8);

      final weekA = TaskPeriod.window(
        recurrence: TaskRecurrence.weekly,
        now: thursday,
      );
      final weekSunday = TaskPeriod.window(
        recurrence: TaskRecurrence.weekly,
        now: sunday,
      );
      final weekB = TaskPeriod.window(
        recurrence: TaskRecurrence.weekly,
        now: monday,
      );

      expect(weekA.periodKey, weekSunday.periodKey);
      expect(weekA.periodKey, isNot(weekB.periodKey));
      expect(weekA.start.weekday, DateTime.monday);
      expect(weekB.start, DateTime(2026, 10, 5));
    });

    test('once fica no dia pontual', () {
      final window = TaskPeriod.window(
        recurrence: TaskRecurrence.once,
        now: DateTime(2026, 10, 3, 9),
        onceDate: DateTime(2026, 10, 7),
      );
      expect(window.periodKey, '2026-10-07');
      expect(window.contains(DateTime(2026, 10, 7, 18)), isTrue);
      expect(window.contains(DateTime(2026, 10, 8)), isFalse);
    });

    test('monthly usa o mês civil', () {
      final window = TaskPeriod.window(
        recurrence: TaskRecurrence.monthly,
        now: DateTime(2026, 10, 31, 23),
      );
      expect(window.periodKey, '2026-10');
      expect(window.end, DateTime(2026, 11, 1));
    });
  });

  group('TaskPeriod.upcomingFires', () {
    const quiet = TaskQuietHours.defaults();

    test('nagging a cada 5 min após o horário', () {
      final task = TaskItem(
        id: 't1',
        title: 'Ler o livro',
        timeOfDay: '09:00',
        naggingIntervalMinutes: 5,
      );
      final fires = TaskPeriod.upcomingFires(
        task: task,
        now: DateTime(2026, 10, 3, 9, 2),
        quietHours: quiet,
        maxCount: 3,
      );
      expect(fires, [
        DateTime(2026, 10, 3, 9, 5),
        DateTime(2026, 10, 3, 9, 10),
        DateTime(2026, 10, 3, 9, 15),
      ]);
    });

    test('não agenda dentro do quiet hours', () {
      // Semanal: o silêncio empurra pro sábado 07:00, ainda na janela.
      final task = const TaskItem(
        id: 't1',
        title: 'Ler o livro',
        timeOfDay: '18:00',
        recurrence: TaskRecurrence.weekly,
        weekdays: [DateTime.monday],
        naggingIntervalMinutes: 5,
      );
      final fires = TaskPeriod.upcomingFires(
        task: task,
        now: DateTime(2026, 10, 2, 22, 30), // sexta à noite
        quietHours: quiet,
        maxCount: 2,
      );
      expect(fires, isNotEmpty);
      for (final fire in fires) {
        expect(quiet.contains(fire), isFalse);
      }
      expect(fires.first, DateTime(2026, 10, 3, 7));
    });

    test('concluída na janela não gera toque', () {
      final now = DateTime(2026, 10, 3, 10);
      final period = TaskPeriod.window(
        recurrence: TaskRecurrence.daily,
        now: now,
      );
      final task = TaskItem(
        id: 't1',
        title: 'Ler',
        timeOfDay: '09:00',
        completedPeriodKey: period.periodKey,
      );
      expect(
        TaskPeriod.upcomingFires(task: task, now: now, quietHours: quiet),
        isEmpty,
      );
    });

    test('weekly não carrega a semana seguinte', () {
      final task = const TaskItem(
        id: 'book',
        title: 'Ler o livro',
        timeOfDay: '18:00',
        recurrence: TaskRecurrence.weekly,
        weekdays: [DateTime.monday],
      );
      final sunday = DateTime(2026, 10, 4, 19);
      final fires = TaskPeriod.upcomingFires(
        task: task,
        now: sunday,
        quietHours: quiet,
        maxCount: 5,
      );
      final period = TaskPeriod.window(
        recurrence: TaskRecurrence.weekly,
        now: sunday,
      );
      expect(fires.every(period.contains), isTrue);
      expect(fires.every((f) => f.isBefore(DateTime(2026, 10, 5))), isTrue);
    });
  });

  group('taskReminderLaunchIntent', () {
    final payload = TaskReminderPayload(
      kind: taskReminderKind,
      taskId: 't1',
      title: 'Ler',
      periodKey: '2026-10-03',
    ).encode();

    test('toque no corpo abre rotina', () {
      expect(
        taskReminderLaunchIntent(
          dismissed: false,
          selectedAction: false,
          payload: payload,
        ),
        TaskReminderLaunchIntent.openRoutine,
      );
    });

    test('Concluir e Adiar', () {
      expect(
        taskReminderLaunchIntent(
          dismissed: false,
          selectedAction: true,
          actionId: taskActionComplete,
          payload: payload,
        ),
        TaskReminderLaunchIntent.complete,
      );
      expect(
        taskReminderLaunchIntent(
          dismissed: false,
          selectedAction: true,
          actionId: taskActionSnooze,
          payload: payload,
        ),
        TaskReminderLaunchIntent.snooze,
      );
    });

    test('dispensar, ação vazia, ação estranha e payload podre não gravam', () {
      expect(
        taskReminderLaunchIntent(
          dismissed: true,
          selectedAction: true,
          actionId: taskActionComplete,
          payload: payload,
        ),
        TaskReminderLaunchIntent.ignore,
      );
      expect(
        taskReminderLaunchIntent(
          dismissed: false,
          selectedAction: true,
          payload: payload,
        ),
        TaskReminderLaunchIntent.ignore,
      );
      expect(
        taskReminderLaunchIntent(
          dismissed: false,
          selectedAction: true,
          actionId: '',
          payload: payload,
        ),
        TaskReminderLaunchIntent.ignore,
      );
      expect(
        taskReminderLaunchIntent(
          dismissed: false,
          selectedAction: true,
          actionId: 'task_delete',
          payload: payload,
        ),
        TaskReminderLaunchIntent.ignore,
      );
      expect(
        taskReminderLaunchIntent(
          dismissed: false,
          selectedAction: false,
          payload: '{',
        ),
        TaskReminderLaunchIntent.ignore,
      );
      expect(
        taskReminderLaunchIntent(dismissed: false, selectedAction: false),
        TaskReminderLaunchIntent.ignore,
      );
    });
  });

  group('TaskReminderPayload', () {
    test('kind errado e minuto fracionário não viram aviso de tarefa', () {
      expect(
        TaskReminderPayload.decode(
          '{"kind":"med","taskId":"t1","title":"Ler","periodKey":"2026-10-03"}',
        ),
        isNull,
      );

      final decoded = TaskReminderPayload.decode(
        '{"kind":"task","taskId":"t1","title":"Ler","periodKey":"2026-10-03",'
        '"alertStyle":"sirene","minutes":10.5}',
      );
      expect(decoded, isNotNull);
      expect(decoded!.alertStyle, TaskAlertStyle.notification);
      expect(decoded.minutes, isNull);

      final snooze = TaskReminderPayload(
        kind: taskSnoozeKind,
        taskId: 't1',
        title: 'Ler',
        periodKey: '2026-10-03',
        minutes: 10,
      );
      final restored = TaskReminderPayload.decode(snooze.encode());
      expect(restored!.kind, taskSnoozeKind);
      expect(restored.minutes, 10);
    });

    test('id da notificação é estável, muda com o slot e não é zero', () {
      final first = taskNotificationId(
        taskId: 't1',
        periodKey: '2026-10-03',
        slot: 0,
      );
      final again = taskNotificationId(
        taskId: 't1',
        periodKey: '2026-10-03',
        slot: 0,
      );
      final nextSlot = taskNotificationId(
        taskId: 't1',
        periodKey: '2026-10-03',
        slot: 1,
      );

      expect(first, again);
      expect(first, isNot(nextSlot));
      expect(first, isNot(0));
      expect(first, greaterThan(0));
    });
  });

  group('TaskQuietHours', () {
    test('22:00–07:00 cobre a madrugada', () {
      const quiet = TaskQuietHours.defaults();
      expect(quiet.contains(DateTime(2026, 10, 3, 23)), isTrue);
      expect(quiet.contains(DateTime(2026, 10, 4, 3)), isTrue);
      expect(quiet.contains(DateTime(2026, 10, 4, 7)), isFalse);
      expect(quiet.contains(DateTime(2026, 10, 3, 21, 59)), isFalse);
    });

    test('silêncio diurno solta no fim e início igual ao fim não cala', () {
      const daytime = TaskQuietHours(
        startHour: 9,
        startMinute: 0,
        endHour: 12,
        endMinute: 30,
      );
      expect(daytime.spansMidnight, isFalse);
      expect(daytime.contains(DateTime(2026, 10, 3, 9)), isTrue);
      expect(daytime.contains(DateTime(2026, 10, 3, 12, 29)), isTrue);
      expect(daytime.contains(DateTime(2026, 10, 3, 12, 30)), isFalse);
      expect(
        daytime.nextAllowed(DateTime(2026, 10, 3, 10, 15)),
        DateTime(2026, 10, 3, 12, 30),
      );
      expect(
        daytime.nextAllowed(DateTime(2026, 10, 3, 13)),
        DateTime(2026, 10, 3, 13),
      );

      const same = TaskQuietHours(
        startHour: 8,
        startMinute: 0,
        endHour: 8,
        endMinute: 0,
      );
      expect(same.contains(DateTime(2026, 10, 3, 8)), isFalse);

      const night = TaskQuietHours.defaults();
      expect(
        night.nextAllowed(DateTime(2026, 10, 3, 23, 30)),
        DateTime(2026, 10, 4, 7),
      );
      expect(
        night.nextAllowed(DateTime(2026, 10, 4, 2)),
        DateTime(2026, 10, 4, 7),
      );
      expect(
        night.nextAllowed(DateTime(2026, 10, 4, 7)),
        DateTime(2026, 10, 4, 7),
      );
    });

    test('mapa incompleto volta para 22:00–07:00', () {
      final quiet = TaskQuietHours.fromMap(const {});
      expect(quiet.startHour, 22);
      expect(quiet.startMinute, 0);
      expect(quiet.endHour, 7);
      expect(quiet.endMinute, 0);
    });
  });

  group('TaskPeriod.appliesOn', () {
    test('daily vale todo dia', () {
      final task = TaskItem(
        id: 'd',
        title: 'Água',
        recurrence: TaskRecurrence.daily,
      );
      expect(TaskPeriod.appliesOn(task, DateTime(2026, 10, 6)), isTrue);
    });

    test('once só no dia pontual', () {
      final task = TaskItem(
        id: 'o',
        title: 'Dentista',
        recurrence: TaskRecurrence.once,
        onceDate: DateTime(2026, 10, 8),
      );
      expect(TaskPeriod.appliesOn(task, DateTime(2026, 10, 6)), isFalse);
      expect(TaskPeriod.appliesOn(task, DateTime(2026, 10, 8, 15)), isTrue);
    });

    test('weekly só nos weekdays escolhidos', () {
      final task = TaskItem(
        id: 'w',
        title: 'Treino',
        recurrence: TaskRecurrence.weekly,
        weekdays: const [1, 3, 5],
      );
      expect(TaskPeriod.appliesOn(task, DateTime(2026, 10, 5)), isTrue); // seg
      expect(TaskPeriod.appliesOn(task, DateTime(2026, 10, 6)), isFalse); // ter
    });

    test('mensal no dia 31 cai no último dia de fevereiro', () {
      final task = TaskItem(
        id: 'bill',
        title: 'Conta',
        timeOfDay: '09:00',
        recurrence: TaskRecurrence.monthly,
        dayOfMonth: 31,
      );
      expect(TaskPeriod.appliesOn(task, DateTime(2026, 2, 28)), isTrue);
      expect(TaskPeriod.appliesOn(task, DateTime(2026, 2, 27)), isFalse);
      expect(TaskPeriod.appliesOn(task, DateTime(2024, 2, 29)), isTrue);
      expect(
        TaskPeriod.anchorFireAt(task, DateTime(2026, 2, 1)),
        DateTime(2026, 2, 28, 9),
      );
    });

    test('pausada não entra no dia', () {
      final task = TaskItem(id: 'off', title: 'Água', active: false);
      expect(TaskPeriod.appliesOn(task, DateTime(2026, 10, 6)), isFalse);
    });
  });

  group('TaskPeriod.window biweekly e semana ISO', () {
    test('bloco de 14 dias muda na fronteira, inclusive antes da âncora', () {
      final epoch = TaskPeriod.biweeklyEpoch;
      final lastOfPrevious = DateTime(2023, 12, 17);
      final firstOfPrevious = DateTime(2023, 12, 4);
      final firstNegative = DateTime(2023, 12, 18);
      final lastOfEpoch = DateTime(2024, 1, 14);
      final nextBlock = DateTime(2024, 1, 15);

      final previous = TaskPeriod.window(
        recurrence: TaskRecurrence.biweekly,
        now: lastOfPrevious,
      );
      final previousStart = TaskPeriod.window(
        recurrence: TaskRecurrence.biweekly,
        now: firstOfPrevious,
      );
      final negative = TaskPeriod.window(
        recurrence: TaskRecurrence.biweekly,
        now: firstNegative,
      );
      final opening = TaskPeriod.window(
        recurrence: TaskRecurrence.biweekly,
        now: epoch,
      );
      final closing = TaskPeriod.window(
        recurrence: TaskRecurrence.biweekly,
        now: lastOfEpoch,
      );
      final following = TaskPeriod.window(
        recurrence: TaskRecurrence.biweekly,
        now: nextBlock,
      );

      expect(previous.periodKey, 'B2023-12-04');
      expect(previousStart.periodKey, previous.periodKey);
      expect(previous.end, firstNegative);
      expect(negative.periodKey, 'B2023-12-18');
      expect(negative.end, epoch);
      expect(opening.periodKey, 'B2024-01-01');
      expect(closing.periodKey, opening.periodKey);
      expect(opening.end, nextBlock);
      expect(following.periodKey, 'B2024-01-15');
      expect(following.start, nextBlock);
    });

    test('semana que cruza o ano fica na semana ISO do ano novo', () {
      final lateDecember = TaskPeriod.window(
        recurrence: TaskRecurrence.weekly,
        now: DateTime(2025, 12, 31),
      );
      final januaryFourth = TaskPeriod.window(
        recurrence: TaskRecurrence.weekly,
        now: DateTime(2026, 1, 4),
      );
      final nextMonday = TaskPeriod.window(
        recurrence: TaskRecurrence.weekly,
        now: DateTime(2026, 1, 5),
      );
      final october = TaskPeriod.window(
        recurrence: TaskRecurrence.weekly,
        now: DateTime(2026, 10, 5),
      );

      expect(lateDecember.periodKey, '2026-W01');
      expect(januaryFourth.periodKey, lateDecember.periodKey);
      expect(januaryFourth.end, DateTime(2026, 1, 5));
      expect(nextMonday.periodKey, '2026-W02');
      expect(october.periodKey, '2026-W41');
    });
  });

  group('TaskPeriod.upcomingFires bordas', () {
    const quiet = TaskQuietHours.defaults();

    test('adiada espera o snooze e intervalo 0 vira 1 minuto', () {
      final snoozed = TaskItem(
        id: 't1',
        title: 'Ler',
        timeOfDay: '09:00',
        naggingIntervalMinutes: 5,
        snoozedUntil: DateTime(2026, 10, 3, 9, 20),
      );
      expect(
        TaskPeriod.upcomingFires(
          task: snoozed,
          now: DateTime(2026, 10, 3, 9, 2),
          quietHours: quiet,
          maxCount: 1,
        ),
        [DateTime(2026, 10, 3, 9, 20)],
      );

      final tight = TaskItem(
        id: 't2',
        title: 'Ler',
        timeOfDay: '09:00',
        naggingIntervalMinutes: 0,
      );
      expect(
        TaskPeriod.upcomingFires(
          task: tight,
          now: DateTime(2026, 10, 3, 9, 2),
          quietHours: quiet,
          maxCount: 2,
        ),
        [DateTime(2026, 10, 3, 9, 3), DateTime(2026, 10, 3, 9, 4)],
      );
    });

    test('horário ilegível e tarefa pausada não agendam', () {
      final badTime = TaskItem(id: 'bad', title: 'Ler', timeOfDay: '99:00');
      final paused = TaskItem(
        id: 'off',
        title: 'Ler',
        timeOfDay: '09:00',
        active: false,
      );
      expect(TaskPeriod.parseTimeOfDay('24:00'), isNull);
      expect(TaskPeriod.parseTimeOfDay('8'), isNull);
      expect(TaskPeriod.parseTimeOfDay('ab:cd'), isNull);
      expect(TaskPeriod.parseTimeOfDay('08:60'), isNull);
      expect(TaskPeriod.parseTimeOfDay('08:05'), (8, 5));
      expect(
        TaskPeriod.upcomingFires(
          task: badTime,
          now: DateTime(2026, 10, 3, 8),
          quietHours: quiet,
        ),
        isEmpty,
      );
      expect(
        TaskPeriod.upcomingFires(
          task: paused,
          now: DateTime(2026, 10, 3, 8),
          quietHours: quiet,
        ),
        isEmpty,
      );
    });

    test(
      'recorrência desconhecida vira diária e horário em branco não agenda',
      () {
        final task = TaskItem.fromMap(const {
          'id': 'x',
          'title': 'Água',
          'recurrence': 'yearly',
          'timeOfDay': '   ',
          'alertStyle': 'sirene',
        });
        expect(task.recurrence, TaskRecurrence.daily);
        expect(task.alertStyle, TaskAlertStyle.notification);
        expect(task.hasReminder, isFalse);
      },
    );
  });
}
