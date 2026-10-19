import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:noa/features/tasks/domain/task_quiet_hours.dart';

void main() {
  group('silêncio diurno', () {
    const quiet = TaskQuietHours(
      startHour: 13,
      startMinute: 0,
      endHour: 15,
      endMinute: 30,
    );

    test('13:00 entra e 15:30 sai, no mesmo dia', () {
      expect(quiet.spansMidnight, isFalse);
      expect(quiet.contains(DateTime(2026, 10, 5, 12, 59)), isFalse);
      expect(quiet.contains(DateTime(2026, 10, 5, 13)), isTrue);
      expect(quiet.contains(DateTime(2026, 10, 5, 15, 29)), isTrue);
      expect(quiet.contains(DateTime(2026, 10, 5, 15, 30)), isFalse);
      expect(
        quiet.nextAllowed(DateTime(2026, 10, 5, 13, 10)),
        DateTime(2026, 10, 5, 15, 30),
      );
      expect(
        quiet.nextAllowed(DateTime(2026, 10, 5, 9)),
        DateTime(2026, 10, 5, 9),
      );
    });

    test('manhã toca na hora; o aviso das 13:00 espera 15:30', () {
      final morning = TaskPeriod.upcomingFires(
        task: const TaskItem(
          id: 'agua',
          title: 'Água',
          timeOfDay: '09:00',
          naggingIntervalMinutes: 30,
        ),
        now: DateTime(2026, 10, 5, 8),
        quietHours: quiet,
        maxCount: 2,
      );
      expect(morning.first, DateTime(2026, 10, 5, 9));

      final fires = TaskPeriod.upcomingFires(
        task: const TaskItem(
          id: 'pausa',
          title: 'Pausa',
          timeOfDay: '13:00',
          naggingIntervalMinutes: 30,
        ),
        now: DateTime(2026, 10, 5, 12),
        quietHours: quiet,
        maxCount: 3,
      );
      expect(fires, [
        DateTime(2026, 10, 5, 15, 30),
        DateTime(2026, 10, 5, 16),
        DateTime(2026, 10, 5, 16, 30),
      ]);
      expect(fires.every((fire) => !quiet.contains(fire)), isTrue);
    });
  });

  group('silêncio com minuto', () {
    const quiet = TaskQuietHours(
      startHour: 22,
      startMinute: 15,
      endHour: 7,
      endMinute: 45,
    );

    test('22:15 entra e 07:45 sai', () {
      expect(quiet.contains(DateTime(2026, 10, 5, 22, 14)), isFalse);
      expect(quiet.contains(DateTime(2026, 10, 5, 22, 15)), isTrue);
      expect(quiet.contains(DateTime(2026, 10, 6, 7, 44)), isTrue);
      expect(quiet.contains(DateTime(2026, 10, 6, 7, 45)), isFalse);
      expect(
        quiet.nextAllowed(DateTime(2026, 10, 5, 23)),
        DateTime(2026, 10, 6, 7, 45),
      );
      expect(
        quiet.nextAllowed(DateTime(2026, 10, 6, 7, 10)),
        DateTime(2026, 10, 6, 7, 45),
      );
    });

    test('na semana o toque das 22:15 sai às 07:45', () {
      final fires = TaskPeriod.upcomingFires(
        task: const TaskItem(
          id: 'noite',
          title: 'Fechar o dia',
          timeOfDay: '22:15',
          recurrence: TaskRecurrence.weekly,
          weekdays: [1, 2, 3, 4, 5, 6, 7],
          naggingIntervalMinutes: 15,
        ),
        now: DateTime(2026, 10, 5, 22),
        quietHours: quiet,
        maxCount: 1,
      );
      expect(fires, [DateTime(2026, 10, 6, 7, 45)]);
      expect(quiet.contains(fires.single), isFalse);
    });

    test('no dia civil o silêncio não empurra o toque para amanhã', () {
      final fires = TaskPeriod.upcomingFires(
        task: const TaskItem(
          id: 'noite',
          title: 'Fechar o dia',
          timeOfDay: '22:15',
          naggingIntervalMinutes: 15,
        ),
        now: DateTime(2026, 10, 5, 22),
        quietHours: quiet,
      );
      expect(fires, isEmpty);
    });
  });

  group('conclusão quinzenal', () {
    test('vale nas duas semanas do bloco e cai no bloco seguinte', () {
      final firstWednesday = DateTime(2024, 1, 3, 18);
      final key = TaskPeriod.window(
        recurrence: TaskRecurrence.biweekly,
        now: firstWednesday,
      ).periodKey;
      final task = TaskItem(
        id: 'revisao',
        title: 'Revisão',
        recurrence: TaskRecurrence.biweekly,
        weekdays: const [DateTime.wednesday],
        completedPeriodKey: key,
      );

      expect(
        TaskPeriod.isCompletedInCurrentPeriod(task, firstWednesday),
        isTrue,
      );
      expect(
        TaskPeriod.isCompletedInCurrentPeriod(task, DateTime(2024, 1, 10, 9)),
        isTrue,
      );
      expect(
        TaskPeriod.isCompletedInCurrentPeriod(task, DateTime(2024, 1, 17, 9)),
        isFalse,
      );
      expect(
        TaskPeriod.upcomingFires(
          task: task,
          now: DateTime(2024, 1, 10, 8),
          quietHours: const TaskQuietHours.defaults(),
        ),
        isEmpty,
      );
    });
  });
}
