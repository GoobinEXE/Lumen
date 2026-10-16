import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/service/reminder_schedule.dart';

void main() {
  final mondayMorning = DateTime(2026, 10, 5, 6);

  test('horário ilegível não derruba o outro alarme do mesmo remédio', () {
    expect(mondayMorning.weekday, DateTime.monday);

    final slots = upcomingDoseOccurrences(
      now: mondayMorning,
      scheduledTimes: const ['24:00', 'manha', '08:60', '', '14:00'],
      daysOfWeek: const [0, DateTime.monday, 8],
    );

    expect(slots, hasLength(1));
    expect(slots.single.time, '14:00');
    expect(slots.single.weekday, DateTime.monday);
    expect(slots.single.at, DateTime(2026, 10, 5, 14));
  });

  test('dia ou hora fora do relógio não agenda', () {
    expect(
      nextDoseOccurrence(
        now: mondayMorning,
        weekday: 0,
        hour: 8,
        minute: 0,
      ),
      isNull,
    );
    expect(
      nextDoseOccurrence(
        now: mondayMorning,
        weekday: 8,
        hour: 8,
        minute: 0,
      ),
      isNull,
    );
    expect(
      nextDoseOccurrence(
        now: mondayMorning,
        weekday: DateTime.monday,
        hour: 24,
        minute: 0,
      ),
      isNull,
    );
    expect(
      nextDoseOccurrence(
        now: mondayMorning,
        weekday: DateTime.monday,
        hour: 8,
        minute: 60,
      ),
      isNull,
    );
    expect(
      nextDoseOccurrence(
        now: mondayMorning,
        weekday: DateTime.monday,
        hour: -1,
        minute: 0,
      ),
      isNull,
    );
  });

  test('lista de dias vazia não vira a semana inteira', () {
    final slots = upcomingDoseOccurrences(
      now: mondayMorning,
      scheduledTimes: const ['08:00', '14:00'],
      daysOfWeek: const [],
    );

    expect(slots, isEmpty);
  });
}
