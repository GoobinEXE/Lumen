import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('horário que saiu da agenda', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
    });

    Future<void> saveAt(List<String> times) {
      return repo.saveMedication(
        Medication(
          id: 'med-1',
          name: 'Venvanse',
          dosage: '30mg',
          scheduledTimes: times,
        ),
      );
    }

    test(
      'dose tomada no único horário permanece e o novo fica pendente',
      () async {
        final day = DateTime(2026, 10, 1);
        await saveAt(const ['08:00']);
        final created = await repo.getLogsForDate(day);
        final morning = created.single;
        await repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 10));

        await saveAt(const ['21:00']);
        final left = await repo.getLogsForDate(day);

        final kept = left.singleWhere((log) => log.id == morning.id);
        expect(kept.isTaken, isTrue);
        expect(kept.takenAt, DateTime(2026, 10, 1, 8, 10));
        expect(kept.scheduledTime, DateTime(2026, 10, 1, 8));

        final evening = left.singleWhere((log) => log.id != morning.id);
        expect(evening.scheduledTime, DateTime(2026, 10, 1, 21));
        expect(evening.isPending, isTrue);
        expect(evening.isTaken, isFalse);
      },
    );

    test(
      'dose pulada no único horário não marca o horário novo como pulada',
      () async {
        final day = DateTime(2026, 10, 1);
        await saveAt(const ['08:00']);
        final created = await repo.getLogsForDate(day);
        final morning = created.single;
        await repo.skipLog(morning.id, 'voluntary');

        await saveAt(const ['21:00']);
        final left = await repo.getLogsForDate(day);

        final kept = left.singleWhere((log) => log.id == morning.id);
        expect(kept.skipped, isTrue);
        expect(kept.scheduledTime, DateTime(2026, 10, 1, 8));

        final evening = left.singleWhere((log) => log.id != morning.id);
        expect(evening.scheduledTime, DateTime(2026, 10, 1, 21));
        expect(evening.isPending, isTrue);
        expect(evening.skipped, isFalse);
      },
    );

    test('dose pendente ainda acompanha o horário novo', () async {
      final day = DateTime(2026, 10, 1);
      await saveAt(const ['08:00']);
      final created = await repo.getLogsForDate(day);

      await saveAt(const ['09:30']);
      final moved = await repo.getLogsForDate(day);

      expect(moved, hasLength(1));
      expect(moved.single.id, created.single.id);
      expect(moved.single.scheduledTime, DateTime(2026, 10, 1, 9, 30));
      expect(moved.single.isPending, isTrue);
    });
  });
}
