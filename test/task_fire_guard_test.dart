import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:noa/features/tasks/domain/task_quiet_hours.dart';

void main() {
  const quiet = TaskQuietHours.defaults();

  test('data pontual ilegível não esconde a tarefa nem o alarme do dia', () {
    final task = TaskItem.fromMap({
      'id': 'o',
      'title': 'Dentista',
      'timeOfDay': '09:00',
      'recurrence': 'once',
      'onceDate': 'amanha',
    });

    expect(task.onceDate, isNull);
    expect(TaskPeriod.appliesOn(task, DateTime(2026, 10, 6)), isTrue);
    expect(TaskPeriod.appliesOn(task, DateTime(2026, 11, 2)), isTrue);
    expect(
      TaskPeriod.upcomingFires(
        task: task,
        now: DateTime(2026, 10, 6, 8),
        quietHours: quiet,
        maxCount: 1,
      ),
      [DateTime(2026, 10, 6, 9)],
    );
  });

  test('tarefa antiga sem intervalo continua a cada 5 minutos', () {
    final task = TaskItem.fromMap({
      'id': 't',
      'title': 'Ler',
      'timeOfDay': '09:00',
      'recurrence': 'daily',
    });

    expect(task.naggingIntervalMinutes, 5);
    expect(task.alertStyle, TaskAlertStyle.notification);
    expect(task.active, isTrue);
    expect(
      TaskPeriod.upcomingFires(
        task: task,
        now: DateTime(2026, 10, 3, 9, 2),
        quietHours: quiet,
        maxCount: 2,
      ),
      [
        DateTime(2026, 10, 3, 9, 5),
        DateTime(2026, 10, 3, 9, 10),
      ],
    );
  });

  test('weekday e intervalo fracionários não derrubam a tarefa', () {
    final task = TaskItem.fromMap({
      'id': 'w',
      'title': 'Treino',
      'recurrence': 'weekly',
      'weekdays': [1.0, 3.0],
      'dayOfMonth': 15.9,
      'naggingIntervalMinutes': 5.9,
    });

    expect(task.weekdays, [1, 3]);
    expect(task.dayOfMonth, 15);
    expect(task.naggingIntervalMinutes, 5);
    expect(TaskPeriod.appliesOn(task, DateTime(2026, 10, 5)), isTrue);
    expect(TaskPeriod.appliesOn(task, DateTime(2026, 10, 6)), isFalse);
  });

  test('adiamento anterior ao próximo toque não puxa o alarme', () {
    final task = TaskItem(
      id: 't',
      title: 'Ler',
      timeOfDay: '09:00',
      naggingIntervalMinutes: 15,
      snoozedUntil: DateTime(2026, 10, 3, 10, 7),
    );
    final now = DateTime(2026, 10, 3, 10);

    expect(
      TaskPeriod.upcomingFires(
        task: task,
        now: now,
        quietHours: quiet,
        maxCount: 1,
      ),
      [DateTime(2026, 10, 3, 10, 15)],
    );

    expect(
      TaskPeriod.upcomingFires(
        task: task.copyWith(snoozedUntil: DateTime(2026, 10, 3, 9, 30)),
        now: now,
        quietHours: quiet,
        maxCount: 1,
      ),
      [DateTime(2026, 10, 3, 10, 15)],
    );
  });
}
