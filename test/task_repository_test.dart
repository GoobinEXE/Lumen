import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/micro_habits_prefs.dart';
import 'package:noa/features/tasks/data/task_repository.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskRepository', () {
    test('migra template de micro-hábitos uma vez', () async {
      SharedPreferences.setMockInitialValues({
        microHabitsTemplateKey: jsonEncode(['Água', 'Ler o livro']),
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = TaskRepository(prefs);

      final first = await repo.loadOrSeed(const ['Default']);
      expect(first.map((t) => t.title), ['Água', 'Ler o livro']);

      prefs.setString(
        microHabitsTemplateKey,
        jsonEncode(['Outro']),
      );
      final second = await repo.loadOrSeed(const ['Default']);
      expect(second.map((t) => t.title), ['Água', 'Ler o livro']);
    });

    test('seed usa defaults quando não há template', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = TaskRepository(prefs);
      final tasks = await repo.loadOrSeed(const ['Sol', 'Água']);
      expect(tasks.map((t) => t.title), ['Sol', 'Água']);
      expect(tasks.every((t) => t.recurrence == TaskRecurrence.daily), isTrue);
    });

    test('concluir grava a periodKey vigente', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = TaskRepository(prefs);
      final tasks = await repo.loadOrSeed(const ['Ler']);
      final now = DateTime(2026, 10, 3, 12);
      await repo.markComplete(tasks.single.id, now);
      final updated = await repo.getById(tasks.single.id);
      final period = TaskPeriod.window(
        recurrence: TaskRecurrence.daily,
        now: now,
      );
      expect(updated!.completedPeriodKey, period.periodKey);
    });
  });
}
