import 'dart:convert';

import 'task_item.dart';

const taskReminderKind = 'task';
const taskSnoozeKind = 'task_snooze';
const taskActionComplete = 'task_complete';
const taskActionSnooze = 'task_snooze';

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
