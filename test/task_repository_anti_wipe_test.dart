import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/data/task_repository.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('JSON de tarefas ilegível não é sobrescrito por save vazio', () async {
    SharedPreferences.setMockInitialValues({
      tasksStorageKey: '{not-json',
      tasksMigratedKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = TaskRepository(prefs);

    final listed = await repo.getTasks();
    expect(listed, isEmpty);

    await repo.saveAll(const []);
    expect(prefs.getString(tasksStorageKey), '{not-json');
  });

  test('upsert concorrente serializa e não perde o segundo write', () async {
    SharedPreferences.setMockInitialValues({
      tasksMigratedKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = TaskRepository(prefs);

    final a = TaskItem(id: '1', title: 'A');
    final b = TaskItem(id: '2', title: 'B');
    await Future.wait([repo.upsert(a), repo.upsert(b)]);
    final all = await repo.getTasks();
    expect(all.map((t) => t.id).toSet(), {'1', '2'});
  });
}
