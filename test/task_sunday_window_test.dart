import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:noa/features/tasks/domain/task_quiet_hours.dart';

void main() {
  const quietDay = TaskQuietHours(
    startHour: 13,
    startMinute: 0,
    endHour: 13,
    endMinute: 30,
  );

  TaskItem sundayTask() {
    return const TaskItem(
      id: 'dom',
      title: 'Fechar a semana',
      timeOfDay: '09:00',
      recurrence: TaskRecurrence.weekly,
      weekdays: [DateTime.sunday],
      naggingIntervalMinutes: 5,
    );
  }

  test('tarefa de domingo não toca na segunda e não vaza da semana', () {
    final onMonday = TaskPeriod.upcomingFires(
      task: sundayTask(),
      now: DateTime(2026, 10, 5, 8),
      quietHours: quietDay,
      maxCount: 2,
    );
    expect(onMonday, [
      DateTime(2026, 10, 11, 9),
      DateTime(2026, 10, 11, 9, 5),
    ]);

    final lateSunday = TaskPeriod.upcomingFires(
      task: sundayTask(),
      now: DateTime(2026, 10, 4, 23, 50),
      quietHours: quietDay,
      maxCount: 8,
    );
    expect(lateSunday, [DateTime(2026, 10, 4, 23, 55)]);
    expect(
      lateSunday.every((fire) => fire.day == 4 && fire.month == 10),
      isTrue,
    );
  });
}
