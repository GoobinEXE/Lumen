import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/data/task_repository.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('títulos concluídos respeitam a janela e ignoram tarefa pausada', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = TaskRepository(prefs);

    final tuesday = DateTime(2026, 10, 20, 18);
    final sunday = DateTime(2026, 10, 25, 11);
    final nextMonday = DateTime(2026, 10, 26, 9);
    final dailyKey = TaskPeriod.window(
      recurrence: TaskRecurrence.daily,
      now: tuesday,
    ).periodKey;
    final weeklyKey = TaskPeriod.window(
      recurrence: TaskRecurrence.weekly,
      now: tuesday,
    ).periodKey;
    final previousWeekKey = TaskPeriod.window(
      recurrence: TaskRecurrence.weekly,
      now: DateTime(2026, 10, 13, 18),
    ).periodKey;

    final tasks = [
      TaskItem(id: '1', title: 'Água', completedPeriodKey: dailyKey),
      TaskItem(id: '2', title: 'Água', completedPeriodKey: dailyKey),
      const TaskItem(
        id: '3',
        title: 'Pausada',
        active: false,
        completedPeriodKey: '2026-10-20',
      ),
      TaskItem(
        id: '4',
        title: 'Revisão',
        recurrence: TaskRecurrence.weekly,
        completedPeriodKey: weeklyKey,
      ),
      TaskItem(
        id: '5',
        title: 'Semana passada',
        recurrence: TaskRecurrence.weekly,
        completedPeriodKey: previousWeekKey,
      ),
      const TaskItem(
        id: '6',
        title: 'Ontem',
        completedPeriodKey: '2026-10-19',
      ),
    ];

    expect(repo.completedTitles(tasks, tuesday), {'Água', 'Revisão'});
    expect(repo.completedTitles(tasks, sunday), {'Revisão'});
    expect(repo.completedTitles(tasks, nextMonday), isEmpty);
    expect(repo.titles(tasks), [
      'Água',
      'Água',
      'Revisão',
      'Semana passada',
      'Ontem',
    ]);
  });
}
