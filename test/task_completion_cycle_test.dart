import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/data/task_repository.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskItem', () {
    test('recorrência e alerta desconhecidos caem no padrão', () {
      final task = TaskItem.fromMap({
        'id': 't1',
        'title': 'Água',
        'recurrence': 'yearly',
        'alertStyle': 'siren',
        'naggingIntervalMinutes': 7.9,
      });

      expect(task.recurrence, TaskRecurrence.daily);
      expect(task.alertStyle, TaskAlertStyle.notification);
      expect(task.naggingIntervalMinutes, 7);
      expect(task.weekdays, [1, 2, 3, 4, 5, 6, 7]);
      expect(task.dayOfMonth, 1);
      expect(task.active, isTrue);
      expect(task.hasReminder, isFalse);
    });

    test('horário em branco ou tarefa pausada não lembra', () {
      expect(
        const TaskItem(id: 'a', title: 'Ler', timeOfDay: '   ').hasReminder,
        isFalse,
      );
      expect(
        const TaskItem(
          id: 'b',
          title: 'Ler',
          timeOfDay: '08:00',
          active: false,
        ).hasReminder,
        isFalse,
      );
      expect(
        const TaskItem(id: 'c', title: 'Ler', timeOfDay: '08:00').hasReminder,
        isTrue,
      );
    });

    test('round-trip tira a hora de onceDate e guarda o adiamento', () {
      final original = TaskItem(
        id: 't1',
        title: 'Dentista',
        timeOfDay: '15:00',
        recurrence: TaskRecurrence.once,
        alertStyle: TaskAlertStyle.alarm,
        onceDate: DateTime(2026, 10, 8, 15, 30),
        completedPeriodKey: '2026-10-08',
        snoozedUntil: DateTime(2026, 10, 8, 16),
        weekdays: const [2, 4],
        dayOfMonth: 8,
        active: false,
      );

      final restored = TaskItem.fromMap(original.toMap());

      expect(restored.onceDate, DateTime(2026, 10, 8));
      expect(restored.snoozedUntil, DateTime(2026, 10, 8, 16));
      expect(restored.completedPeriodKey, '2026-10-08');
      expect(restored.alertStyle, TaskAlertStyle.alarm);
      expect(restored.weekdays, [2, 4]);
      expect(restored.dayOfMonth, 8);
      expect(restored.active, isFalse);
      expect(restored.recurrence, TaskRecurrence.once);
    });

    test('copyWith limpa horário, data pontual e adiamento', () {
      final task = TaskItem(
        id: 't1',
        title: 'Ler',
        timeOfDay: '09:00',
        onceDate: DateTime(2026, 10, 8),
        completedPeriodKey: '2026-10-08',
        snoozedUntil: DateTime(2026, 10, 8, 10),
      );

      final cleared = task.copyWith(
        clearTimeOfDay: true,
        clearOnceDate: true,
        clearCompletedPeriodKey: true,
        clearSnoozedUntil: true,
      );

      expect(cleared.timeOfDay, isNull);
      expect(cleared.onceDate, isNull);
      expect(cleared.completedPeriodKey, isNull);
      expect(cleared.snoozedUntil, isNull);
      expect(cleared.title, 'Ler');
    });
  });

  group('TaskRepository conclusão', () {
    test('concluir limpa o adiamento e desfazer abre de novo', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = TaskRepository(prefs);
      final now = DateTime(2026, 10, 7, 18);
      final task = TaskItem(
        id: 'book',
        title: 'Ler o livro',
        timeOfDay: '18:00',
        recurrence: TaskRecurrence.weekly,
        weekdays: const [DateTime.wednesday],
        snoozedUntil: DateTime(2026, 10, 7, 19),
      );
      await repo.upsert(task);

      final done = await repo.markComplete(task.id, now);
      final period = TaskPeriod.window(
        recurrence: TaskRecurrence.weekly,
        now: now,
      );
      expect(done.completedPeriodKey, period.periodKey);
      expect(done.snoozedUntil, isNull);
      expect(TaskPeriod.isCompletedInCurrentPeriod(done, now), isTrue);

      final open = await repo.markIncomplete(task.id);
      expect(open.completedPeriodKey, isNull);
      expect(open.snoozedUntil, isNull);
      expect(TaskPeriod.isCompletedInCurrentPeriod(open, now), isFalse);
    });

    test('id inexistente não apaga a lista', () async {
      SharedPreferences.setMockInitialValues({tasksMigratedKey: true});
      final prefs = await SharedPreferences.getInstance();
      final repo = TaskRepository(prefs);
      await repo.upsert(const TaskItem(id: 'keep', title: 'Água'));

      expect(
        () => repo.markComplete('missing', DateTime(2026, 10, 7)),
        throwsStateError,
      );
      await repo.delete('missing');

      final left = await repo.getTasks();
      expect(left.map((task) => task.id), ['keep']);
    });

    test('apagar uma tarefa deixa a outra', () async {
      SharedPreferences.setMockInitialValues({tasksMigratedKey: true});
      final prefs = await SharedPreferences.getInstance();
      final repo = TaskRepository(prefs);
      await repo.upsert(const TaskItem(id: 'a', title: 'Água'));
      await repo.upsert(const TaskItem(id: 'b', title: 'Ler'));

      await repo.delete('a');

      final left = await repo.getTasks();
      expect(left.map((task) => task.id), ['b']);
    });

    test('seed ignora título em branco', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = TaskRepository(prefs);

      final seeded = await repo.loadOrSeed(const ['Água', '  ', '']);

      expect(seeded.map((task) => task.title), ['Água']);
    });

    test('item com weekday ilegível sai e o irmão fica', () async {
      final raw = jsonEncode([
        {'id': 'ok', 'title': 'Água', 'weekdays': [1, 3, 5]},
        {'id': 'bad', 'title': 'Quebrada', 'weekdays': ['seg']},
      ]);
      SharedPreferences.setMockInitialValues({
        tasksStorageKey: raw,
        tasksMigratedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = TaskRepository(prefs);

      final listed = await repo.getTasks();
      expect(listed.map((task) => task.id), ['ok']);
      expect(prefs.getString(tasksStorageKey), raw);

      await repo.upsert(const TaskItem(id: 'new', title: 'Ler'));
      final after = await repo.getTasks();
      expect(after.map((task) => task.id).toSet(), {'ok', 'new'});
    });
  });
}
