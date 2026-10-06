import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/service/reminder_schedule.dart';

void main() {
  test('dia ou horário impossível não agenda a dose', () {
    final now = DateTime(2026, 10, 5, 8);

    expect(
      nextDoseOccurrence(now: now, weekday: 0, hour: 8, minute: 0),
      isNull,
    );
    expect(
      nextDoseOccurrence(now: now, weekday: 8, hour: 8, minute: 0),
      isNull,
    );
    expect(
      nextDoseOccurrence(now: now, weekday: DateTime.monday, hour: 24, minute: 0),
      isNull,
    );
    expect(
      nextDoseOccurrence(now: now, weekday: DateTime.monday, hour: -1, minute: 0),
      isNull,
    );
    expect(
      nextDoseOccurrence(now: now, weekday: DateTime.monday, hour: 8, minute: 60),
      isNull,
    );
  });

  test('23h59 ainda gera o próximo instante válido', () {
    final at = nextDoseOccurrence(
      now: DateTime(2026, 10, 5, 8),
      weekday: DateTime.monday,
      hour: 23,
      minute: 59,
    );

    expect(at, DateTime(2026, 10, 5, 23, 59));
  });

  test('payload quebrado, ação vazia ou dismiss não grava a dose', () {
    expect(ReminderPayload.decode('{'), isNull);
    expect(ReminderPayload.decode(''), isNull);

    final minutesAsText = ReminderPayload.decode(
      '{"kind":"dose","medicationId":"a","name":"Venvanse","time":"08:00","minutes":"15","logId":"log-1"}',
    );
    expect(minutesAsText, isNotNull);
    expect(minutesAsText!.minutes, isNull);
    expect(minutesAsText.logId, 'log-1');

    expect(
      reminderLaunchIntent(
        dismissed: false,
        selectedAction: false,
        payload: '{',
      ),
      ReminderLaunchIntent.ignore,
    );
    expect(
      reminderLaunchIntent(
        dismissed: false,
        selectedAction: true,
        actionId: '',
        payload: minutesAsText.encode(),
      ),
      ReminderLaunchIntent.ignore,
    );
    expect(
      reminderLaunchIntent(
        dismissed: true,
        selectedAction: true,
        actionId: medicationActionTaken,
        payload: minutesAsText.encode(),
      ),
      ReminderLaunchIntent.ignore,
    );
  });
}
