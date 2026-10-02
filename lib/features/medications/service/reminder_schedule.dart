import 'dart:convert';

/// Próximo instante local em que um horário de dose deve tocar.
DateTime? nextDoseOccurrence({
  required DateTime now,
  required int weekday,
  required int hour,
  required int minute,
}) {
  if (weekday < DateTime.monday || weekday > DateTime.sunday) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

  final start = DateTime(now.year, now.month, now.day);
  for (var offset = 0; offset <= 7; offset++) {
    final day = start.add(Duration(days: offset));
    if (day.weekday != weekday) continue;
    final at = DateTime(day.year, day.month, day.day, hour, minute);
    if (at.isAfter(now)) return at;
  }
  return null;
}

class DoseOccurrence {
  const DoseOccurrence({
    required this.time,
    required this.weekday,
    required this.at,
  });

  final String time;
  final int weekday;
  final DateTime at;
}

/// Um alarme por horário e dia da semana, só em dias futuros em relação a [now].
List<DoseOccurrence> upcomingDoseOccurrences({
  required DateTime now,
  required List<String> scheduledTimes,
  required List<int> daysOfWeek,
}) {
  final results = <DoseOccurrence>[];
  for (final raw in scheduledTimes) {
    final parts = raw.split(':');
    final hour = int.tryParse(parts.isEmpty ? '' : parts[0]);
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '');
    if (hour == null || minute == null) continue;
    final time =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    for (final weekday in daysOfWeek) {
      final at = nextDoseOccurrence(
        now: now,
        weekday: weekday,
        hour: hour,
        minute: minute,
      );
      if (at == null) continue;
      results.add(DoseOccurrence(time: time, weekday: weekday, at: at));
    }
  }
  return results;
}

int doseNotificationId({
  required String medicationId,
  required String time,
  required int weekday,
}) {
  return _stableId('dose|$medicationId|$time|$weekday');
}

int snoozeNotificationId(String logId) => _stableId('snooze|$logId');

int _stableId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  if (hash == 0) return 1;
  return hash;
}

const medicationDoseKind = 'dose';
const medicationSnoozeKind = 'snooze';
const medicationActionTaken = 'taken';
const medicationActionSnooze = 'snooze';

enum ReminderLaunchIntent { ignore, openMedications, taken, snooze }

/// O que fazer com a notificação que abriu o app ou foi tocada.
ReminderLaunchIntent reminderLaunchIntent({
  required bool dismissed,
  required bool selectedAction,
  String? actionId,
  String? payload,
}) {
  if (dismissed) return ReminderLaunchIntent.ignore;
  final action = actionId;
  final hasAction = action != null && action.isNotEmpty;
  if (selectedAction && !hasAction) return ReminderLaunchIntent.ignore;

  final decoded = ReminderPayload.decode(payload);
  if (!hasAction) {
    return decoded == null
        ? ReminderLaunchIntent.ignore
        : ReminderLaunchIntent.openMedications;
  }
  if (decoded == null) return ReminderLaunchIntent.ignore;
  if (action == medicationActionTaken) return ReminderLaunchIntent.taken;
  if (action == medicationActionSnooze) return ReminderLaunchIntent.snooze;
  return ReminderLaunchIntent.ignore;
}

String medicationDoseCategoryId(String languageCode) =>
    'medication_dose_$languageCode';

class ReminderPayload {
  const ReminderPayload({
    required this.kind,
    required this.medicationId,
    required this.name,
    required this.time,
    this.logId,
    this.minutes,
  });

  final String kind;
  final String medicationId;
  final String name;
  final String time;
  final String? logId;
  final int? minutes;

  String encode() {
    return jsonEncode({
      'kind': kind,
      'medicationId': medicationId,
      'name': name,
      'time': time,
      if (logId != null) 'logId': logId,
      if (minutes != null) 'minutes': minutes,
    });
  }

  static ReminderPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final medicationId = map['medicationId'] as String?;
      final name = map['name'] as String?;
      final time = map['time'] as String?;
      final kind = map['kind'] as String?;
      if (medicationId == null ||
          name == null ||
          time == null ||
          kind == null) {
        return null;
      }
      return ReminderPayload(
        kind: kind,
        medicationId: medicationId,
        name: name,
        time: time,
        logId: map['logId'] as String?,
        minutes: map['minutes'] is int ? map['minutes'] as int : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Horário da dose que a ação da notificação representa.
///
/// O alarme semanal só carrega a hora, não a data. Confirmar de madrugada
/// uma dose da noite anterior não pode marcar o horário de hoje, que ainda
/// não chegou. Um aviso que toca pouco antes da hora continua no mesmo dia.
DateTime scheduledDoseInstant(String time, [DateTime? now]) {
  final clock = now ?? DateTime.now();
  final parts = time.split(':');
  final hour = int.tryParse(parts.isEmpty ? '' : parts[0]) ?? 8;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  final todayAt = DateTime(clock.year, clock.month, clock.day, hour, minute);
  if (!clock.isBefore(todayAt)) return todayAt;

  final yesterdayAt = DateTime(
    clock.year,
    clock.month,
    clock.day - 1,
    hour,
    minute,
  );
  final untilToday = todayAt.difference(clock);
  final sinceYesterday = clock.difference(yesterdayAt);
  if (sinceYesterday <= untilToday) return yesterdayAt;
  return todayAt;
}
