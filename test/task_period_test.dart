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
        TaskPeriod.upcomingFires(
          task: task,
          now: now,
          quietHours: quiet,
        ),
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
  });

  group('TaskQuietHours', () {
    test('22:00–07:00 cobre a madrugada', () {
      const quiet = TaskQuietHours.defaults();
      expect(quiet.contains(DateTime(2026, 10, 3, 23)), isTrue);
      expect(quiet.contains(DateTime(2026, 10, 4, 3)), isTrue);
      expect(quiet.contains(DateTime(2026, 10, 4, 7)), isFalse);
      expect(quiet.contains(DateTime(2026, 10, 3, 21, 59)), isFalse);
    });
  });

  group('TaskPeriod.appliesOn', () {
    test('daily vale todo dia', () {
      final task = TaskItem(id: 'd', title: 'Água', recurrence: TaskRecurrence.daily);
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
  });
}
