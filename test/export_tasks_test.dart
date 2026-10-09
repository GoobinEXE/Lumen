import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:noa/features/therapist_export/domain/export_tasks.dart';

void main() {
  final now = DateTime(2026, 10, 7, 9);

  TaskItem daily(String id, String title) =>
      TaskItem(id: id, title: title, recurrence: TaskRecurrence.daily);

  group('taskExportLines', () {
    test('separa concluídas no período das abertas com janela vigente', () {
      final doneKey = TaskPeriod.window(
        recurrence: TaskRecurrence.daily,
        now: now,
      ).periodKey;

      final tasks = [
        daily('a', 'Beber água').copyWith(completedPeriodKey: doneKey),
        daily('b', 'Caminhar'),
        daily('c', 'Inativa').copyWith(active: false),
      ];

      final lines = taskExportLines(
        tasks: tasks,
        now: now,
        periodDays: 7,
      );

      expect(lines, hasLength(2));
      // Concluídas vêm primeiro.
      expect(lines.first.title, 'Beber água');
      expect(lines.first.status, TaskExportStatus.completed);
      expect(lines.last.title, 'Caminhar');
      expect(lines.last.status, TaskExportStatus.open);
      // Tarefa inativa não entra.
      expect(lines.any((l) => l.title == 'Inativa'), isFalse);
    });

    test('tarefa pontual fora do intervalo não entra como aberta', () {
      final old = TaskItem(
        id: 'd',
        title: 'Consulta antiga',
        recurrence: TaskRecurrence.once,
        onceDate: DateTime(2026, 9, 1),
      );

      final lines = taskExportLines(
        tasks: [old],
        now: now,
        periodDays: 7,
      );

      expect(lines, isEmpty);
    });

    test('tarefa pontual dentro do intervalo entra como aberta', () {
      final soon = TaskItem(
        id: 'e',
        title: 'Entregar relatório',
        recurrence: TaskRecurrence.once,
        onceDate: DateTime(2026, 10, 5),
      );

      final lines = taskExportLines(
        tasks: [soon],
        now: now,
        periodDays: 7,
      );

      expect(lines, hasLength(1));
      expect(lines.single.status, TaskExportStatus.open);
    });

    test('tarefa mensal fora do dia do mês não entra como aberta', () {
      // now = 2026-10-07; o período de 7 dias cobre 30/09 a 07/10, então um
      // dia do mês fora dessa faixa (ex.: 25) nunca aparece na janela.
      final midMonth = TaskItem(
        id: 'f',
        title: 'Pagar aluguel',
        recurrence: TaskRecurrence.monthly,
        dayOfMonth: 25,
      );

      final lines = taskExportLines(
        tasks: [midMonth],
        now: now,
        periodDays: 7,
      );

      expect(lines, isEmpty);
    });

    test('tarefa mensal com dia dentro do período entra como aberta', () {
      final earlyMonth = TaskItem(
        id: 'g',
        title: 'Fisioterapia',
        recurrence: TaskRecurrence.monthly,
        dayOfMonth: 5, // 05/10 cai dentro da janela de 7 dias de 30/09–07/10.
      );

      final lines = taskExportLines(
        tasks: [earlyMonth],
        now: now,
        periodDays: 7,
      );

      expect(lines, hasLength(1));
      expect(lines.single.status, TaskExportStatus.open);
    });

    test('tarefa concluída e aberta no mesmo período mantêm concluídas primeiro', () {
      final doneKey = TaskPeriod.window(
        recurrence: TaskRecurrence.once,
        now: now,
        onceDate: DateTime(2026, 10, 5),
      ).periodKey;

      final doneOnce = TaskItem(
        id: 'h',
        title: 'Pagar boleto',
        recurrence: TaskRecurrence.once,
        onceDate: DateTime(2026, 10, 5),
        completedPeriodKey: doneKey,
      );

      final lines = taskExportLines(
        tasks: [doneOnce],
        now: now,
        periodDays: 7,
      );

      expect(lines, hasLength(1));
      expect(lines.single.status, TaskExportStatus.completed);
    });
  });

  group('describeTaskExportLines', () {
    test('vazio devolve cabeçalho + texto de nenhuma', () {
      final rows = describeTaskExportLines(
        lines: const [],
        heading: 'Tarefas',
        none: 'Nenhuma',
      );
      expect(rows, ['Tarefas', 'Nenhuma']);
    });

    test('monta cabeçalho e marcadores por status', () {
      final rows = describeTaskExportLines(
        lines: const [
          TaskExportLine(title: 'Feita', status: TaskExportStatus.completed),
          TaskExportLine(title: 'Aberta', status: TaskExportStatus.open),
        ],
        heading: 'Tarefas',
        none: 'Nenhuma',
        completedMarker: '[x]',
        openMarker: '[ ]',
      );
      expect(rows, ['Tarefas', '[x] Feita', '[ ] Aberta']);
    });
  });
}
