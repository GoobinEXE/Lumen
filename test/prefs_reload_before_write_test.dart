import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/tasks/data/task_repository.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('editar tarefa não apaga conclusão gravada noutro isolate', () async {
    SharedPreferences.setMockInitialValues({tasksMigratedKey: true});
    final prefs = await SharedPreferences.getInstance();
    final repo = TaskRepository(prefs);
    const a = TaskItem(id: 'a', title: 'Água');
    const b = TaskItem(id: 'b', title: 'Ler');
    await repo.saveAll(const [a, b]);

    SharedPreferences.resetStatic();
    final external = await SharedPreferences.getInstance();
    await external.setString(
      tasksStorageKey,
      jsonEncode([
        const TaskItem(
          id: 'a',
          title: 'Água',
          completedPeriodKey: '2026-10-09',
        ).toMap(),
        b.toMap(),
      ]),
    );

    await repo.markComplete('b', DateTime(2026, 10, 9, 12));

    final tasks = await repo.getTasks();
    expect(
      tasks.firstWhere((task) => task.id == 'a').completedPeriodKey,
      '2026-10-09',
    );
    expect(
      tasks.firstWhere((task) => task.id == 'b').completedPeriodKey,
      '2026-10-09',
    );
  });

  test('pular uma dose não apaga a dose tomada noutro isolate', () async {
    final morning = MedicationLog(
      id: 'morning',
      medicationId: 'med-1',
      medicationName: 'Lisdexanfetamina 30 mg',
      scheduledTime: DateTime(2026, 10, 9, 8),
    );
    final night = MedicationLog(
      id: 'night',
      medicationId: 'med-1',
      medicationName: 'Lisdexanfetamina 30 mg',
      scheduledTime: DateTime(2026, 10, 9, 21),
    );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = MedicationRepository(prefs);
    await prefs.setString(
      'noa_medication_logs_v2',
      jsonEncode([morning.toMap(), night.toMap()]),
    );
    expect((await repo.logById(morning.id))!.isTaken, isFalse);

    SharedPreferences.resetStatic();
    final external = await SharedPreferences.getInstance();
    await external.setString(
      'noa_medication_logs_v2',
      jsonEncode([
        morning.copyWith(takenAt: DateTime(2026, 10, 9, 8, 5)).toMap(),
        night.toMap(),
      ]),
    );

    await repo.skipLog(night.id, 'voluntary');

    final logs = await repo.getAllLogs();
    final savedMorning = logs.firstWhere((log) => log.id == morning.id);
    final savedNight = logs.firstWhere((log) => log.id == night.id);
    expect(savedMorning.isTaken, isTrue);
    expect(savedMorning.takenAt, DateTime(2026, 10, 9, 8, 5));
    expect(savedNight.skipped, isTrue);
    expect(savedNight.skipReason, 'voluntary');
  });
}
