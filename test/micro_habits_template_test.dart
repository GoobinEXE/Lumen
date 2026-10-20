import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/micro_habits_prefs.dart';
import 'package:noa/features/routine_mood/data/routine_repository.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/tasks/data/task_repository.dart';
import 'package:noa/l10n/app_localizations_pt.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = AppLocalizationsPt();

  test('salvar a rotina substitui o template de hábitos por inteiro', () async {
    SharedPreferences.setMockInitialValues({
      microHabitsTemplateKey: jsonEncode(['Sol', 'Água', 'Alongar']),
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);

    await repo.appendSnapshot(
      RoutineSnapshot(
        id: 'snap-1',
        savedAt: DateTime(2026, 10, 20, 21),
        microHabits: const ['Água'],
      ),
    );

    expect(getMicroHabitsTemplate(prefs, l10n), ['Água']);

    await repo.appendSnapshot(
      RoutineSnapshot(
        id: 'snap-2',
        savedAt: DateTime(2026, 10, 20, 22),
        microHabits: const [],
      ),
    );

    expect(prefs.getString(microHabitsTemplateKey), '[]');
    expect(getMicroHabitsTemplate(prefs, l10n), isEmpty);
  });

  test('template ilegível volta ao padrão e o seed usa os títulos recebidos', () async {
    SharedPreferences.setMockInitialValues({
      microHabitsTemplateKey: '{não é lista',
    });
    final prefs = await SharedPreferences.getInstance();

    expect(
      getMicroHabitsTemplate(prefs, l10n),
      defaultMicroHabits(l10n),
    );

    final tasks = await TaskRepository(prefs).loadOrSeed(const ['Sol', 'Água']);
    expect(tasks.map((task) => task.title), ['Sol', 'Água']);
  });
}
