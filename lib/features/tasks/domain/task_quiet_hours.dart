/// Janela silenciosa do app para avisos de tarefa (não afeta remédios).
class TaskQuietHours {
  const TaskQuietHours({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  /// Padrão 22:00–07:00.
  const TaskQuietHours.defaults()
      : startHour = 22,
        startMinute = 0,
        endHour = 7,
        endMinute = 0;

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  bool get spansMidnight {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    return start != end && start > end;
  }

  bool contains(DateTime when) {
    final minutes = when.hour * 60 + when.minute;
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    if (start == end) return false;
    if (spansMidnight) {
      return minutes >= start || minutes < end;
    }
    return minutes >= start && minutes < end;
  }

  /// Próximo instante fora do silêncio, se [when] estiver dentro; senão [when].
  DateTime nextAllowed(DateTime when) {
    if (!contains(when)) return when;
    if (spansMidnight) {
      // Sai às endHour:endMinute do dia civil em que o silêncio noturno acaba.
      final endToday = DateTime(
        when.year,
        when.month,
        when.day,
        endHour,
        endMinute,
      );
      if (when.isBefore(endToday)) return endToday;
      return endToday.add(const Duration(days: 1));
    }
    final endToday = DateTime(
      when.year,
      when.month,
      when.day,
      endHour,
      endMinute,
    );
    if (!when.isBefore(endToday)) {
      return DateTime(
        when.year,
        when.month,
        when.day + 1,
        endHour,
        endMinute,
      );
    }
    return endToday;
  }

  Map<String, dynamic> toMap() => {
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      };

  factory TaskQuietHours.fromMap(Map<String, dynamic> map) {
    return TaskQuietHours(
      startHour: (map['startHour'] as num?)?.toInt() ?? 22,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 7,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
    );
  }
}
