import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:noa/features/tasks/domain/task_quiet_hours.dart';

void main() {
  const quiet = TaskQuietHours.defaults();
  const open = TaskQuietHours(
    startHour: 0,
    startMinute: 0,
    endHour: 0,
    endMinute: 0,
  );

  TaskItem daily(String time) {
    return TaskItem(
      id: 'daily',
      title: 'Fechar o dia',
      timeOfDay: time,
      recurrence: TaskRecurrence.daily,
      naggingIntervalMinutes: 5,
    );
  }

  test('tarefa diária às 22:00 não vaza para o dia seguinte', () {
    final atNight = TaskPeriod.upcomingFires(
      task: daily('22:00'),
      now: DateTime(2026, 10, 3, 21),
      quietHours: quiet,
      maxCount: 3,
    );
    final justBefore = TaskPeriod.upcomingFires(
      task: daily('21:59'),
      now: DateTime(2026, 10, 3, 21),
      quietHours: quiet,
      maxCount: 1,
    );
    final atWake = TaskPeriod.upcomingFires(
      task: daily('07:00'),
      now: DateTime(2026, 10, 3, 6, 30),
      quietHours: quiet,
      maxCount: 1,
    );

    expect(atNight, isEmpty);
    expect(justBefore, [DateTime(2026, 10, 3, 21, 59)]);
    expect(atWake, [DateTime(2026, 10, 3, 7)]);
  });

  test('tarefa pontual toca no dia marcado e cala no dia seguinte', () {
    final task = TaskItem(
      id: 'once',
      title: 'Dentista',
      timeOfDay: '15:30',
      recurrence: TaskRecurrence.once,
      onceDate: DateTime(2026, 10, 8),
      naggingIntervalMinutes: 5,
    );

    final before = TaskPeriod.upcomingFires(
      task: task,
      now: DateTime(2026, 10, 6, 9),
      quietHours: quiet,
      maxCount: 2,
    );
    final after = TaskPeriod.upcomingFires(
      task: task,
      now: DateTime(2026, 10, 9, 9),
      quietHours: quiet,
    );

    expect(before.first, DateTime(2026, 10, 8, 15, 30));
    expect(before.every((fire) => fire.day == 8), isTrue);
    expect(after, isEmpty);
  });

  test('quinzena anterior à âncora não agenda o bloco seguinte', () {
    final task = TaskItem(
      id: 'biweek',
      title: 'Revisar a semana',
      timeOfDay: '09:00',
      recurrence: TaskRecurrence.biweekly,
      weekdays: const [DateTime.sunday],
      naggingIntervalMinutes: 5,
    );
    final lastNight = DateTime(2023, 12, 17, 23, 50);
    final window = TaskPeriod.window(
      recurrence: TaskRecurrence.biweekly,
      now: lastNight,
    );
    final fires = TaskPeriod.upcomingFires(
      task: task,
      now: lastNight,
      quietHours: open,
      maxCount: 3,
    );
    final nextBlock = TaskPeriod.window(
      recurrence: TaskRecurrence.biweekly,
      now: DateTime(2023, 12, 18, 0, 10),
    );
    final nextFires = TaskPeriod.upcomingFires(
      task: task,
      now: DateTime(2023, 12, 18, 0, 10),
      quietHours: open,
      maxCount: 1,
    );

    expect(window.periodKey, 'B2023-12-04');
    expect(window.end, DateTime(2023, 12, 18));
    expect(fires, [DateTime(2023, 12, 17, 23, 55)]);
    expect(nextBlock.periodKey, 'B2023-12-18');
    expect(nextFires, [DateTime(2023, 12, 24, 9)]);
  });
}
