import 'dart:convert';

import 'task_item.dart';

const taskReminderKind = 'task';
const taskSnoozeKind = 'task_snooze';
const taskActionComplete = 'task_complete';
const taskActionSnooze = 'task_snooze';

/// Teto de avisos pendentes do iOS. O sistema fica com os 64 que disparam
/// primeiro e descarta o resto, sem avisar o app.
const iosPendingNotificationLimit = 64;

/// Lugares guardados para a dose quando a agenda de remédio ainda não foi
/// gravada — os dois syncs sobem juntos na abertura.
const medicationNotificationReserve = 16;

/// Quantos avisos de tarefa ainda cabem sem empurrar o alarme do remédio
/// para fora da fila do aparelho.
int taskNotificationBudget({required int medicationPending}) {
  final pending = medicationPending < 0 ? 0 : medicationPending;
  final reserved = pending < medicationNotificationReserve
      ? medicationNotificationReserve
      : pending;
  final room = iosPendingNotificationLimit - reserved;
  if (room < 0) return 0;
  return room;
}

/// Reparte [budget] em rodízio. O primeiro toque de cada tarefa entra antes
/// do nagging seguinte, para o aviso das 9h não engolir o das 21h.
List<T> takeRoundRobin<T>(List<List<T>> groups, int budget) {
  if (budget <= 0 || groups.isEmpty) return <T>[];
  final picked = <T>[];
  var depth = 0;
  while (picked.length < budget) {
    var grew = false;
    for (final group in groups) {
      if (picked.length >= budget) break;
      if (depth < group.length) {
        picked.add(group[depth]);
        grew = true;
      }
    }
    if (!grew) break;
    depth++;
  }
  return picked;
}

enum TaskReminderLaunchIntent { ignore, openRoutine, complete, snooze }

String taskReminderCategoryId(String languageCode) =>
    'task_reminder_$languageCode';

int taskNotificationId({
  required String taskId,
  required String periodKey,
  required int slot,
}) {
  return _stableId('task|$taskId|$periodKey|$slot');
}

int _stableId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  if (hash == 0) return 1;
  return hash;
}

TaskReminderLaunchIntent taskReminderLaunchIntent({
  required bool dismissed,
  required bool selectedAction,
  String? actionId,
  String? payload,
}) {
  if (dismissed) return TaskReminderLaunchIntent.ignore;
  final action = actionId;
  final hasAction = action != null && action.isNotEmpty;
  if (selectedAction && !hasAction) return TaskReminderLaunchIntent.ignore;

  final decoded = TaskReminderPayload.decode(payload);
  if (decoded == null) return TaskReminderLaunchIntent.ignore;
  if (!hasAction) return TaskReminderLaunchIntent.openRoutine;
  if (action == taskActionComplete) return TaskReminderLaunchIntent.complete;
  if (action == taskActionSnooze) return TaskReminderLaunchIntent.snooze;
  return TaskReminderLaunchIntent.ignore;
}

class TaskReminderPayload {
  const TaskReminderPayload({
    required this.kind,
    required this.taskId,
    required this.title,
    required this.periodKey,
    this.alertStyle = TaskAlertStyle.notification,
    this.minutes,
  });

  final String kind;
  final String taskId;
  final String title;
  final String periodKey;
  final TaskAlertStyle alertStyle;
  final int? minutes;

  String encode() {
    return jsonEncode({
      'kind': kind,
      'taskId': taskId,
      'title': title,
      'periodKey': periodKey,
      'alertStyle': alertStyle.name,
      if (minutes != null) 'minutes': minutes,
    });
  }

  static TaskReminderPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final kind = map['kind'] as String?;
      final taskId = map['taskId'] as String?;
      final title = map['title'] as String?;
      final periodKey = map['periodKey'] as String?;
      if (kind == null ||
          taskId == null ||
          title == null ||
          periodKey == null) {
        return null;
      }
      if (kind != taskReminderKind && kind != taskSnoozeKind) return null;
      return TaskReminderPayload(
        kind: kind,
        taskId: taskId,
        title: title,
        periodKey: periodKey,
        alertStyle: TaskItem.alertStyleFrom(map['alertStyle'] as String?),
        minutes: map['minutes'] is int ? map['minutes'] as int : null,
      );
    } catch (_) {
      return null;
    }
  }
}
