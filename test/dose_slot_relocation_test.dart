import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';

void main() {
  final day = DateTime(2026, 10, 1);

  Medication med(List<String> times) {
    return Medication(
      id: 'm1',
      name: 'Venvanse',
      dosage: '30mg',
      scheduledTimes: times,
    );
  }

  MedicationLog log({
    required String id,
    required int hour,
    DateTime? takenAt,
    bool skipped = false,
    String? skipReason,
  }) {
    return MedicationLog(
      id: id,
      medicationId: 'm1',
      medicationName: 'Venvanse 30mg',
      scheduledTime: DateTime(2026, 10, 1, hour),
      takenAt: takenAt,
      skipped: skipped,
      skipReason: skipReason,
    );
  }

  test(
    'trocar os dois horários leva cada log para o slot novo na ordem do dia',
    () {
      final takenAt = DateTime(2026, 10, 1, 8, 4);
      final result = MedicationRepository.alignDayLogs(
        day,
        [med(const ['09:00', '20:00'])],
        [
          log(id: 'taken', hour: 8, takenAt: takenAt),
          log(id: 'pending', hour: 14),
        ],
      );

      expect(result, hasLength(2));
      final taken = result.singleWhere((entry) => entry.id == 'taken');
      final pending = result.singleWhere((entry) => entry.id == 'pending');
      expect(taken.scheduledTime, DateTime(2026, 10, 1, 9));
      expect(taken.takenAt, takenAt);
      expect(taken.isTaken, isTrue);
      expect(pending.scheduledTime, DateTime(2026, 10, 1, 20));
      expect(pending.isPending, isTrue);
    },
  );

  test(
    'um horário novo pega o log mais cedo e a tomada que sobra fica na hora antiga',
    () {
      final takenAt = DateTime(2026, 10, 1, 14, 10);
      final result = MedicationRepository.alignDayLogs(
        day,
        [med(const ['09:00'])],
        [
          log(id: 'early', hour: 8),
          log(id: 'taken', hour: 14, takenAt: takenAt),
        ],
      );

      expect(result, hasLength(2));
      final early = result.singleWhere((entry) => entry.id == 'early');
      final taken = result.singleWhere((entry) => entry.id == 'taken');
      expect(early.scheduledTime, DateTime(2026, 10, 1, 9));
      expect(early.isPending, isTrue);
      expect(taken.scheduledTime, DateTime(2026, 10, 1, 14));
      expect(taken.takenAt, takenAt);
      expect(result.where((entry) => entry.isPending), hasLength(1));
    },
  );

  test('encolher três doses resolvidas não apaga a tomada que sobra', () {
    final morning = DateTime(2026, 10, 1, 8, 2);
    final night = DateTime(2026, 10, 1, 21, 5);
    final result = MedicationRepository.alignDayLogs(
      day,
      [med(const ['09:00', '18:00'])],
      [
        log(id: 'morning', hour: 8, takenAt: morning),
        log(id: 'mid', hour: 14, skipped: true, skipReason: 'voluntary'),
        log(id: 'night', hour: 21, takenAt: night),
      ],
    );

    expect(result, hasLength(3));
    expect(result.where((entry) => entry.isPending), isEmpty);
    final byId = {for (final entry in result) entry.id: entry};
    expect(byId['morning']!.scheduledTime, DateTime(2026, 10, 1, 9));
    expect(byId['morning']!.takenAt, morning);
    expect(byId['mid']!.scheduledTime, DateTime(2026, 10, 1, 18));
    expect(byId['mid']!.skipped, isTrue);
    expect(byId['mid']!.skipReason, 'voluntary');
    expect(byId['night']!.scheduledTime, DateTime(2026, 10, 1, 21));
    expect(byId['night']!.takenAt, night);
  });
}
