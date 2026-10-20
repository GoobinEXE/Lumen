import 'task_item.dart';
import 'task_quiet_hours.dart';

/// Como o horário da tarefa volta a tocar com o app fechado.
enum TaskAnchorRepeat { once, daily, weekly, monthly }

/// Próximo toque do horário em si, fora do nagging de minutos.
///
/// Diária, semanal e mensal repetem no sistema. Quinzenal e pontual
/// agendam as próximas ocorrências uma a uma: o aparelho não tem
/// intervalo de 14 dias.
class TaskAnchorFire {
  const TaskAnchorFire({
    required this.at,
    required this.repeat,
    required this.slotKey,
  });

  final DateTime at;
  final TaskAnchorRepeat repeat;
  final String slotKey;
}

/// Janela vigente de uma tarefa — sem dívida do período anterior.
class TaskPeriodWindow {
  const TaskPeriodWindow({
    required this.start,
    required this.end,
    required this.periodKey,
  });

  final DateTime start;
  final DateTime end;
  final String periodKey;

  bool contains(DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);
}

class TaskPeriod {
  TaskPeriod._();

  /// Âncora fixa para blocos quinzenais (segunda-feira ISO).
  static final DateTime biweeklyEpoch = DateTime(2024, 1, 1);

  static TaskPeriodWindow window({
    required TaskRecurrence recurrence,
    required DateTime now,
    DateTime? onceDate,
  }) {
    final day = DateTime(now.year, now.month, now.day);
    switch (recurrence) {
      case TaskRecurrence.once:
        final anchor = onceDate == null
            ? day
            : DateTime(onceDate.year, onceDate.month, onceDate.day);
        return TaskPeriodWindow(
          start: anchor,
          end: anchor.add(const Duration(days: 1)),
          periodKey: _dayKey(anchor),
        );
      case TaskRecurrence.daily:
        return TaskPeriodWindow(
          start: day,
          end: day.add(const Duration(days: 1)),
          periodKey: _dayKey(day),
        );
      case TaskRecurrence.weekly:
        final start = _mondayOf(day);
        return TaskPeriodWindow(
          start: start,
          end: start.add(const Duration(days: 7)),
          periodKey: _weekKey(start),
        );
      case TaskRecurrence.biweekly:
        final start = _biweeklyStart(day);
        return TaskPeriodWindow(
          start: start,
          end: start.add(const Duration(days: 14)),
          periodKey: 'B${_dayKey(start)}',
        );
      case TaskRecurrence.monthly:
        final start = DateTime(day.year, day.month, 1);
        final end = DateTime(day.year, day.month + 1, 1);
        final key =
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}';
        return TaskPeriodWindow(start: start, end: end, periodKey: key);
    }
  }

  static bool isCompletedInCurrentPeriod(TaskItem task, DateTime now) {
    final current = window(
      recurrence: task.recurrence,
      now: now,
      onceDate: task.onceDate,
    );
    return task.completedPeriodKey == current.periodKey;
  }

  /// Tarefa ativa que vale para o dia civil (checklist do Dia / grupo "Para hoje").
  static bool appliesOn(TaskItem task, DateTime now) {
    if (!task.active) return false;
    final day = DateTime(now.year, now.month, now.day);
    switch (task.recurrence) {
      case TaskRecurrence.once:
        final once = task.onceDate;
        if (once == null) return true;
        return DateTime(once.year, once.month, once.day) == day;
      case TaskRecurrence.daily:
        return true;
      case TaskRecurrence.weekly:
      case TaskRecurrence.biweekly:
        final wanted = task.weekdays.isEmpty
            ? const {1, 2, 3, 4, 5, 6, 7}
            : task.weekdays.toSet();
        return wanted.contains(day.weekday);
      case TaskRecurrence.monthly:
        final last = _daysInMonth(DateTime(day.year, day.month, 1));
        final target = task.dayOfMonth.clamp(1, last);
        return day.day == target;
    }
  }

  /// Âncora do aviso dentro da janela (primeiro horário elegível).
  static DateTime? anchorFireAt(TaskItem task, DateTime now) {
    if (!task.hasReminder) return null;
    final parsed = parseTimeOfDay(task.timeOfDay!);
    if (parsed == null) return null;
    final period = window(
      recurrence: task.recurrence,
      now: now,
      onceDate: task.onceDate,
    );

    switch (task.recurrence) {
      case TaskRecurrence.once:
        return DateTime(
          period.start.year,
          period.start.month,
          period.start.day,
          parsed.$1,
          parsed.$2,
        );
      case TaskRecurrence.daily:
        return DateTime(
          period.start.year,
          period.start.month,
          period.start.day,
          parsed.$1,
          parsed.$2,
        );
      case TaskRecurrence.weekly:
      case TaskRecurrence.biweekly:
        return _firstWeekdayFire(
          period: period,
          weekdays: task.weekdays,
          hour: parsed.$1,
          minute: parsed.$2,
        );
      case TaskRecurrence.monthly:
        final day = task.dayOfMonth.clamp(1, _daysInMonth(period.start));
        return DateTime(
          period.start.year,
          period.start.month,
          day,
          parsed.$1,
          parsed.$2,
        );
    }
  }

  /// Horário que continua tocando sem abrir o app.
  ///
  /// O nagging ([upcomingFires]) mora só na janela vigente. Este toque é o
  /// relógio da tarefa: amanhã, a outra semana, o outro mês.
  static List<TaskAnchorFire> anchorFires({
    required TaskItem task,
    required DateTime now,
    required TaskQuietHours quietHours,
  }) {
    if (!task.hasReminder || !task.active) return const [];
    final parsed = parseTimeOfDay(task.timeOfDay!);
    if (parsed == null) return const [];
    final hour = parsed.$1;
    final minute = parsed.$2;
    final completed = isCompletedInCurrentPeriod(task, now);
    final current = window(
      recurrence: task.recurrence,
      now: now,
      onceDate: task.onceDate,
    );

    switch (task.recurrence) {
      case TaskRecurrence.once:
        final once = _onceAnchor(
          task: task,
          now: now,
          quietHours: quietHours,
          hour: hour,
          minute: minute,
          completed: completed,
        );
        return once == null ? const [] : [once];
      case TaskRecurrence.daily:
        final next = _nextClock(
          now: now,
          quietHours: quietHours,
          hour: hour,
          minute: minute,
          completed: completed,
          current: current,
          stepDays: 1,
          lookbackDays: 1,
        );
        if (next == null) return const [];
        return [
          TaskAnchorFire(at: next, repeat: TaskAnchorRepeat.daily, slotKey: 'daily'),
        ];
      case TaskRecurrence.weekly:
        return _weekdayAnchors(
          now: now,
          quietHours: quietHours,
          hour: hour,
          minute: minute,
          weekdays: task.weekdays,
          completed: completed,
          current: current,
          stepDays: 7,
          repeat: TaskAnchorRepeat.weekly,
        );
      case TaskRecurrence.biweekly:
        return _blockAnchors(
          task: task,
          now: now,
          quietHours: quietHours,
          hour: hour,
          minute: minute,
          completed: completed,
          current: current,
          count: 2,
        );
      case TaskRecurrence.monthly:
        final next = _nextMonthly(
          task: task,
          now: now,
          quietHours: quietHours,
          hour: hour,
          minute: minute,
          completed: completed,
          current: current,
        );
        if (next == null) return const [];
        return [
          TaskAnchorFire(
            at: next,
            repeat: TaskAnchorRepeat.monthly,
            slotKey: 'monthly',
          ),
        ];
    }
  }

  /// Próximos toques na janela vigente (nagging), filtrados por quiet hours.
  static List<DateTime> upcomingFires({
    required TaskItem task,
    required DateTime now,
    required TaskQuietHours quietHours,
    int maxCount = 36,
  }) {
    if (!task.hasReminder || !task.active) return const [];
    if (isCompletedInCurrentPeriod(task, now)) return const [];

    final period = window(
      recurrence: task.recurrence,
      now: now,
      onceDate: task.onceDate,
    );
    final anchor = anchorFireAt(task, now);
    if (anchor == null) return const [];

    final intervalMinutes =
        task.naggingIntervalMinutes < 1 ? 1 : task.naggingIntervalMinutes;
    final interval = Duration(minutes: intervalMinutes);

    DateTime cursor;
    if (anchor.isAfter(now)) {
      cursor = anchor;
    } else {
      final elapsed = now.difference(anchor);
      final steps = elapsed.inMinutes <= 0
          ? 1
          : (elapsed.inMinutes ~/ intervalMinutes) + 1;
      cursor = anchor.add(Duration(minutes: steps * intervalMinutes));
      if (!cursor.isAfter(now)) {
        cursor = now.add(interval);
      }
    }

    final snoozed = task.snoozedUntil;
    if (snoozed != null && snoozed.isAfter(cursor)) {
      cursor = snoozed;
    }

    final results = <DateTime>[];
    var guard = 0;
    while (results.length < maxCount && guard < 800) {
      guard++;
      if (!cursor.isBefore(period.end)) break;

      var candidate = quietHours.contains(cursor)
          ? quietHours.nextAllowed(cursor)
          : cursor;
      if (!candidate.isBefore(period.end)) break;
      if (quietHours.contains(candidate)) {
        cursor = candidate.add(interval);
        continue;
      }
      if (candidate.isAfter(now)) {
        results.add(candidate);
      }
      cursor = candidate.add(interval);
    }
    return results;
  }

  static (int, int)? parseTimeOfDay(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }

  static String formatTimeOfDay(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static DateTime _mondayOf(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  static DateTime _biweeklyStart(DateTime day) {
    final monday = _mondayOf(day);
    final days = monday.difference(biweeklyEpoch).inDays;
    final block = days < 0 ? ((days - 13) ~/ 14) : days ~/ 14;
    return biweeklyEpoch.add(Duration(days: block * 14));
  }

  static DateTime? _firstWeekdayFire({
    required TaskPeriodWindow period,
    required List<int> weekdays,
    required int hour,
    required int minute,
  }) {
    final wanted = weekdays.isEmpty
        ? const {1, 2, 3, 4, 5, 6, 7}
        : weekdays.toSet();
    for (var offset = 0; offset < 14; offset++) {
      final day = period.start.add(Duration(days: offset));
      if (!day.isBefore(period.end)) break;
      if (!wanted.contains(day.weekday)) continue;
      return DateTime(day.year, day.month, day.day, hour, minute);
    }
    return null;
  }

  static String _dayKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String _weekKey(DateTime monday) {
    final thursday = monday.add(const Duration(days: 3));
    final jan4 = DateTime(thursday.year, 1, 4);
    final week1Monday = _mondayOf(jan4);
    final week = (monday.difference(week1Monday).inDays ~/ 7) + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  static int _daysInMonth(DateTime monthStart) {
    final next = DateTime(monthStart.year, monthStart.month + 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  static DateTime _afterQuiet(DateTime at, TaskQuietHours quiet) {
    if (!quiet.contains(at)) return at;
    return quiet.nextAllowed(at);
  }

  static bool _rawInCompletedPeriod({
    required bool completed,
    required TaskPeriodWindow current,
    required DateTime raw,
    required TaskRecurrence recurrence,
    DateTime? onceDate,
  }) {
    if (!completed) return false;
    final period = window(
      recurrence: recurrence,
      now: raw,
      onceDate: onceDate,
    );
    return period.periodKey == current.periodKey;
  }

  static DateTime? _nextClock({
    required DateTime now,
    required TaskQuietHours quietHours,
    required int hour,
    required int minute,
    required bool completed,
    required TaskPeriodWindow current,
    required int stepDays,
    required int lookbackDays,
  }) {
    var day = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: lookbackDays),
    );
    DateTime? best;
    for (var i = 0; i < lookbackDays + stepDays + 2; i++) {
      final raw = DateTime(day.year, day.month, day.day, hour, minute);
      final blocked = _rawInCompletedPeriod(
        completed: completed,
        current: current,
        raw: raw,
        recurrence: stepDays == 1
            ? TaskRecurrence.daily
            : TaskRecurrence.weekly,
      );
      if (!blocked) {
        final at = _afterQuiet(raw, quietHours);
        if (at.isAfter(now) && (best == null || at.isBefore(best))) {
          best = at;
        }
      }
      day = day.add(Duration(days: stepDays));
    }
    return best;
  }

  static TaskAnchorFire? _onceAnchor({
    required TaskItem task,
    required DateTime now,
    required TaskQuietHours quietHours,
    required int hour,
    required int minute,
    required bool completed,
  }) {
    if (completed) return null;
    final anchor = task.onceDate == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime(
            task.onceDate!.year,
            task.onceDate!.month,
            task.onceDate!.day,
          );
    final at = _afterQuiet(
      DateTime(anchor.year, anchor.month, anchor.day, hour, minute),
      quietHours,
    );
    if (!at.isAfter(now)) return null;
    return TaskAnchorFire(
      at: at,
      repeat: TaskAnchorRepeat.once,
      slotKey: 'once',
    );
  }

  static List<TaskAnchorFire> _weekdayAnchors({
    required DateTime now,
    required TaskQuietHours quietHours,
    required int hour,
    required int minute,
    required List<int> weekdays,
    required bool completed,
    required TaskPeriodWindow current,
    required int stepDays,
    required TaskAnchorRepeat repeat,
  }) {
    final wanted = (weekdays.isEmpty
            ? const {1, 2, 3, 4, 5, 6, 7}
            : weekdays.toSet())
        .toList()
      ..sort();
    final fires = <TaskAnchorFire>[];
    final seen = <String>{};
    for (final weekday in wanted) {
      if (weekday < DateTime.monday || weekday > DateTime.sunday) continue;
      var day = DateTime(now.year, now.month, now.day).subtract(
        const Duration(days: 7),
      );
      while (day.weekday != weekday) {
        day = day.add(const Duration(days: 1));
      }
      DateTime? best;
      for (var i = 0; i < 4; i++) {
        final raw = DateTime(day.year, day.month, day.day, hour, minute);
        final blocked = _rawInCompletedPeriod(
          completed: completed,
          current: current,
          raw: raw,
          recurrence: TaskRecurrence.weekly,
        );
        if (!blocked) {
          final at = _afterQuiet(raw, quietHours);
          if (at.isAfter(now) && (best == null || at.isBefore(best))) {
            best = at;
          }
        }
        day = day.add(Duration(days: stepDays));
      }
      if (best == null) continue;
      final minuteKey =
          '${best.year}-${best.month}-${best.day}-${best.hour}-${best.minute}';
      if (!seen.add(minuteKey)) continue;
      fires.add(
        TaskAnchorFire(
          at: best,
          repeat: repeat,
          slotKey: 'wd-$weekday',
        ),
      );
    }
    fires.sort((a, b) => a.at.compareTo(b.at));
    return fires;
  }

  static List<TaskAnchorFire> _blockAnchors({
    required TaskItem task,
    required DateTime now,
    required TaskQuietHours quietHours,
    required int hour,
    required int minute,
    required bool completed,
    required TaskPeriodWindow current,
    required int count,
  }) {
    final fires = <TaskAnchorFire>[];
    final seen = <String>{};
    var cursor = now.subtract(const Duration(days: 14));
    for (var i = 0; i < 6 && fires.length < count; i++) {
      final period = window(
        recurrence: TaskRecurrence.biweekly,
        now: cursor,
      );
      final raw = _firstWeekdayFire(
        period: period,
        weekdays: task.weekdays,
        hour: hour,
        minute: minute,
      );
      final blocked = raw != null &&
          _rawInCompletedPeriod(
            completed: completed,
            current: current,
            raw: raw,
            recurrence: TaskRecurrence.biweekly,
          );
      if (raw != null && !blocked) {
        final at = _afterQuiet(raw, quietHours);
        final minuteKey =
            '${at.year}-${at.month}-${at.day}-${at.hour}-${at.minute}';
        if (at.isAfter(now) && seen.add(minuteKey)) {
          fires.add(
            TaskAnchorFire(
              at: at,
              repeat: TaskAnchorRepeat.once,
              slotKey: 'biweekly-${fires.length}',
            ),
          );
        }
      }
      cursor = period.end.add(const Duration(hours: 1));
    }
    return fires;
  }

  static DateTime? _nextMonthly({
    required TaskItem task,
    required DateTime now,
    required TaskQuietHours quietHours,
    required int hour,
    required int minute,
    required bool completed,
    required TaskPeriodWindow current,
  }) {
    var month = DateTime(now.year, now.month - 1, 1);
    DateTime? best;
    for (var i = 0; i < 4; i++) {
      final last = _daysInMonth(month);
      final day = task.dayOfMonth.clamp(1, last);
      final raw = DateTime(month.year, month.month, day, hour, minute);
      final blocked = _rawInCompletedPeriod(
        completed: completed,
        current: current,
        raw: raw,
        recurrence: TaskRecurrence.monthly,
      );
      if (!blocked) {
        final at = _afterQuiet(raw, quietHours);
        if (at.isAfter(now) && (best == null || at.isBefore(best))) {
          best = at;
        }
      }
      month = DateTime(month.year, month.month + 1, 1);
    }
    return best;
  }
}
