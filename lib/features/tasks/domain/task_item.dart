/// Recorrência da tarefa. A obrigação vive só na janela vigente — sem empilhar períodos.
enum TaskRecurrence { once, daily, weekly, biweekly, monthly }

/// Intensidade do aviso no aparelho.
enum TaskAlertStyle { notification, alarm, insistent }

/// Item da lista única de Tarefas (rotina).
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.timeOfDay,
    this.recurrence = TaskRecurrence.daily,
    this.naggingIntervalMinutes = 5,
    this.alertStyle = TaskAlertStyle.notification,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.dayOfMonth = 1,
    this.onceDate,
    this.completedPeriodKey,
    this.snoozedUntil,
    this.active = true,
  });

  final String id;
  final String title;

  /// Horário HH:mm. Sem horário = só checklist, sem notificação.
  final String? timeOfDay;
  final TaskRecurrence recurrence;
  final int naggingIntervalMinutes;
  final TaskAlertStyle alertStyle;

  /// Dias da semana (1=seg … 7=dom) para weekly/biweekly.
  final List<int> weekdays;

  /// Dia do mês (1–31) para monthly.
  final int dayOfMonth;

  /// Dia civil da tarefa pontual.
  final DateTime? onceDate;

  /// Chave da janela em que foi concluída (ex. `2026-10-03`, `2026-W40`).
  final String? completedPeriodKey;
  final DateTime? snoozedUntil;
  final bool active;

  bool get hasReminder =>
      active && timeOfDay != null && timeOfDay!.trim().isNotEmpty;

  TaskItem copyWith({
    String? id,
    String? title,
    String? timeOfDay,
    bool clearTimeOfDay = false,
    TaskRecurrence? recurrence,
    int? naggingIntervalMinutes,
    TaskAlertStyle? alertStyle,
    List<int>? weekdays,
    int? dayOfMonth,
    DateTime? onceDate,
    bool clearOnceDate = false,
    String? completedPeriodKey,
    bool clearCompletedPeriodKey = false,
    DateTime? snoozedUntil,
    bool clearSnoozedUntil = false,
    bool? active,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      timeOfDay: clearTimeOfDay ? null : (timeOfDay ?? this.timeOfDay),
      recurrence: recurrence ?? this.recurrence,
      naggingIntervalMinutes:
          naggingIntervalMinutes ?? this.naggingIntervalMinutes,
      alertStyle: alertStyle ?? this.alertStyle,
      weekdays: weekdays ?? this.weekdays,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      onceDate: clearOnceDate ? null : (onceDate ?? this.onceDate),
      completedPeriodKey: clearCompletedPeriodKey
          ? null
          : (completedPeriodKey ?? this.completedPeriodKey),
      snoozedUntil:
          clearSnoozedUntil ? null : (snoozedUntil ?? this.snoozedUntil),
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        if (timeOfDay != null) 'timeOfDay': timeOfDay,
        'recurrence': recurrence.name,
        'naggingIntervalMinutes': naggingIntervalMinutes,
        'alertStyle': alertStyle.name,
        'weekdays': weekdays,
        'dayOfMonth': dayOfMonth,
        if (onceDate != null) 'onceDate': _dateOnly(onceDate!).toIso8601String(),
        if (completedPeriodKey != null)
          'completedPeriodKey': completedPeriodKey,
        if (snoozedUntil != null)
          'snoozedUntil': snoozedUntil!.toIso8601String(),
        'active': active,
      };

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    final onceRaw = map['onceDate'] as String?;
    final snoozeRaw = map['snoozedUntil'] as String?;
    return TaskItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      timeOfDay: map['timeOfDay'] as String?,
      recurrence: _recurrenceFrom(map['recurrence'] as String?),
      naggingIntervalMinutes: (map['naggingIntervalMinutes'] as num?)?.toInt() ??
          5,
      alertStyle: alertStyleFrom(map['alertStyle'] as String?),
      weekdays: (map['weekdays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      dayOfMonth: (map['dayOfMonth'] as num?)?.toInt() ?? 1,
      onceDate: onceRaw == null ? null : DateTime.tryParse(onceRaw),
      completedPeriodKey: map['completedPeriodKey'] as String?,
      snoozedUntil: snoozeRaw == null ? null : DateTime.tryParse(snoozeRaw),
      active: map['active'] as bool? ?? true,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static TaskRecurrence _recurrenceFrom(String? raw) {
    for (final value in TaskRecurrence.values) {
      if (value.name == raw) return value;
    }
    return TaskRecurrence.daily;
  }

  static TaskAlertStyle alertStyleFrom(String? raw) {
    for (final value in TaskAlertStyle.values) {
      if (value.name == raw) return value;
    }
    return TaskAlertStyle.notification;
  }
}
