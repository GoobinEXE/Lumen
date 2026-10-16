import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:noa/features/tasks/domain/task_quiet_hours.dart';

void main() {
  const quiet = TaskQuietHours.defaults();

  test('adiar para dentro do silêncio não toca de madrugada nem vaza o dia', () {
    final task = TaskItem(
      id: 't1',
      title: 'Ler o livro',
      timeOfDay: '21:00',
      naggingIntervalMinutes: 5,
      snoozedUntil: DateTime(2026, 10, 3, 23),
    );

    final fires = TaskPeriod.upcomingFires(
      task: task,
      now: DateTime(2026, 10, 3, 21, 30),
      quietHours: quiet,
    );

    expect(fires, isEmpty);
    expect(quiet.contains(DateTime(2026, 10, 3, 23)), isTrue);
  });

  test('adiar para antes do silêncio ainda toca nesse horário', () {
    final task = TaskItem(
      id: 't1',
      title: 'Ler o livro',
      timeOfDay: '21:00',
      naggingIntervalMinutes: 5,
      snoozedUntil: DateTime(2026, 10, 3, 21, 40),
    );

    final fires = TaskPeriod.upcomingFires(
      task: task,
      now: DateTime(2026, 10, 3, 21, 10),
      quietHours: quiet,
      maxCount: 2,
    );

    expect(fires.first, DateTime(2026, 10, 3, 21, 40));
    expect(fires, [
      DateTime(2026, 10, 3, 21, 40),
      DateTime(2026, 10, 3, 21, 45),
    ]);
    expect(fires.every((fire) => quiet.contains(fire)), isFalse);
  });
}
