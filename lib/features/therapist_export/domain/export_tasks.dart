import '../../tasks/domain/task_item.dart';
import '../../tasks/domain/task_period.dart';

/// Estado da tarefa dentro da janela exportada.
enum TaskExportStatus { completed, open }

/// Linha de tarefa que PDF, WhatsApp e texto clínico descrevem do mesmo jeito.
///
/// Domínio puro: sem import de Flutter nem de l10n. As strings de título vêm
/// do próprio [TaskItem]; cabeçalho e marcadores entram como parâmetros.
class TaskExportLine {
  const TaskExportLine({
    required this.title,
    required this.status,
    this.timeOfDay,
    this.recurrence,
  });

  final String title;
  final TaskExportStatus status;
  final String? timeOfDay;
  final TaskRecurrence? recurrence;
}

/// Linhas de tarefas do período: concluídas no intervalo + abertas com janela
/// vigente dentro do intervalo. Sem histórico persistido, "concluída" usa a
/// janela corrente ([TaskPeriod.isCompletedInCurrentPeriod]).
List<TaskExportLine> taskExportLines({
  required List<TaskItem> tasks,
  required DateTime now,
  required int periodDays,
}) {
  final start = now.subtract(Duration(days: periodDays));
  final completed = <TaskExportLine>[];
  final open = <TaskExportLine>[];

  for (final task in tasks) {
    if (!task.active) continue;
    if (TaskPeriod.isCompletedInCurrentPeriod(task, now)) {
      completed.add(
        TaskExportLine(
          title: task.title.trim(),
          status: TaskExportStatus.completed,
          timeOfDay: task.timeOfDay,
          recurrence: task.recurrence,
        ),
      );
    } else if (_appliesInWindow(task, start, now)) {
      open.add(
        TaskExportLine(
          title: task.title.trim(),
          status: TaskExportStatus.open,
          timeOfDay: task.timeOfDay,
          recurrence: task.recurrence,
        ),
      );
    }
  }

  completed.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  open.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  return [...completed, ...open];
}

/// Monta o bloco de texto das tarefas. Cabeçalho, vazio e marcadores chegam
/// já localizados (UI/i18n depois); os marcadores são símbolos neutros por
/// padrão, sem copy fixa.
List<String> describeTaskExportLines({
  required List<TaskExportLine> lines,
  required String heading,
  required String none,
  String completedMarker = '☑',
  String openMarker = '☐',
}) {
  if (lines.isEmpty) {
    return [heading, none];
  }
  return [
    heading,
    for (final line in lines)
      '${line.status == TaskExportStatus.completed ? completedMarker : openMarker} ${line.title}',
  ];
}

bool _appliesInWindow(TaskItem task, DateTime start, DateTime end) {
  var day = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  while (!day.isAfter(last)) {
    if (TaskPeriod.appliesOn(task, day)) return true;
    day = day.add(const Duration(days: 1));
  }
  return false;
}
