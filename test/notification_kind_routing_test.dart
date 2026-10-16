import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/notifications/local_notifications_host.dart';
import 'package:noa/features/medications/service/reminder_schedule.dart';
import 'package:noa/features/tasks/domain/task_reminder_schedule.dart';

void main() {
  test('o kind separa dose, adiamento de dose, tarefa e adiamento de tarefa', () {
    final dose = ReminderPayload(
      kind: medicationDoseKind,
      medicationId: 'med-1',
      name: 'Lisdexanfetamina',
      time: '08:00',
    ).encode();
    final doseSnooze = ReminderPayload(
      kind: medicationSnoozeKind,
      medicationId: 'med-1',
      name: 'Lisdexanfetamina',
      time: '08:00',
      logId: 'log-1',
      minutes: 15,
    ).encode();
    final task = TaskReminderPayload(
      kind: taskReminderKind,
      taskId: 'task-1',
      title: 'Ler o livro',
      periodKey: '2026-10-03',
    ).encode();
    final taskSnooze = TaskReminderPayload(
      kind: taskSnoozeKind,
      taskId: 'task-1',
      title: 'Ler o livro',
      periodKey: '2026-10-03',
      minutes: 10,
    ).encode();

    expect(LocalNotificationsHost.kindFromPayload(dose), medicationDoseKind);
    expect(
      LocalNotificationsHost.kindFromPayload(doseSnooze),
      medicationSnoozeKind,
    );
    expect(LocalNotificationsHost.kindFromPayload(task), taskReminderKind);
    expect(
      LocalNotificationsHost.kindFromPayload(taskSnooze),
      taskSnoozeKind,
    );
  });

  test('payload vazio, quebrado ou sem kind de texto não roteia', () {
    expect(LocalNotificationsHost.kindFromPayload(null), isNull);
    expect(LocalNotificationsHost.kindFromPayload(''), isNull);
    expect(LocalNotificationsHost.kindFromPayload('   '), isNull);
    expect(LocalNotificationsHost.kindFromPayload('{'), isNull);
    expect(LocalNotificationsHost.kindFromPayload('[]'), isNull);
    expect(LocalNotificationsHost.kindFromPayload('"dose"'), isNull);
    expect(LocalNotificationsHost.kindFromPayload('{"kind":1}'), isNull);
    expect(LocalNotificationsHost.kindFromPayload('{"name":"Lis"}'), isNull);
  });
}
