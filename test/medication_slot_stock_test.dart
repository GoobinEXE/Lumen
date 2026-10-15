import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final day = DateTime(2026, 10, 1, 16);

  Medication med({
    required String id,
    required String name,
    required List<String> times,
    required int stock,
  }) {
    return Medication(
      id: id,
      name: name,
      dosage: '30mg',
      scheduledTimes: times,
      totalStock: stock,
      remainingStock: stock,
    );
  }

  late MedicationRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = MedicationRepository(prefs);
    await repo.reload();
  });

  test('duas doses tomadas juntas descontam o estoque duas vezes', () async {
    await repo.saveMedication(
      med(
        id: 'a',
        name: 'Venvanse',
        times: const ['08:00', '14:00'],
        stock: 10,
      ),
    );
    final logs = await repo.getLogsForDate(day);
    final morning = logs.firstWhere((log) => log.scheduledTime.hour == 8);
    final afternoon = logs.firstWhere((log) => log.scheduledTime.hour == 14);

    await Future.wait([
      repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 1)),
      repo.markAsTaken(afternoon.id, DateTime(2026, 10, 1, 14, 1)),
    ]);

    final stored = await repo.getMedications();
    expect(stored.single.remainingStock, 8);
    final after = await repo.getLogsForDate(day);
    expect(after, hasLength(2));
    expect(after.every((log) => log.isTaken), isTrue);
    expect(after.map((log) => log.id).toSet(), {morning.id, afternoon.id});
  });

  test(
    'a segunda dose com uma unidade restante não deixa o estoque negativo',
    () async {
      await repo.saveMedication(
        med(
          id: 'a',
          name: 'Venvanse',
          times: const ['08:00', '14:00'],
          stock: 1,
        ),
      );
      final logs = await repo.getLogsForDate(day);
      final morning = logs.firstWhere((log) => log.scheduledTime.hour == 8);
      final afternoon = logs.firstWhere((log) => log.scheduledTime.hour == 14);

      await repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 1));
      await repo.markAsTaken(afternoon.id, DateTime(2026, 10, 1, 14, 1));

      final stored = await repo.getMedications();
      expect(stored.single.remainingStock, 0);
      final after = await repo.getLogsForDate(day);
      expect(after.every((log) => log.isTaken), isTrue);
    },
  );

  test('tomar um remédio não baixa o estoque do outro', () async {
    await repo.saveMedication(
      med(id: 'a', name: 'Venvanse', times: const ['08:00'], stock: 10),
    );
    await repo.saveMedication(
      med(id: 'b', name: 'Ritalina', times: const ['14:00'], stock: 7),
    );
    final logs = await repo.getLogsForDate(day);
    final morning = logs.firstWhere((log) => log.medicationId == 'a');

    await repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 4));

    final stored = await repo.getMedications();
    expect(stored.firstWhere((item) => item.id == 'a').remainingStock, 9);
    expect(stored.firstWhere((item) => item.id == 'b').remainingStock, 7);
  });

  test(
    'incluir um terceiro horário não troca o status dos slots que já existem',
    () async {
      await repo.saveMedication(
        med(
          id: 'a',
          name: 'Venvanse',
          times: const ['08:00', '14:00'],
          stock: 20,
        ),
      );
      final logs = await repo.getLogsForDate(day);
      final morning = logs.firstWhere((log) => log.scheduledTime.hour == 8);
      final afternoon = logs.firstWhere((log) => log.scheduledTime.hour == 14);
      await repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 5));
      await repo.skipLog(afternoon.id, 'voluntary');

      await repo.saveMedication(
        med(
          id: 'a',
          name: 'Venvanse',
          times: const ['08:00', '14:00', '20:00'],
          stock: 19,
        ),
      );

      final after = await repo.getLogsForDate(day);
      expect(after, hasLength(3));
      final keptMorning = after.firstWhere((log) => log.id == morning.id);
      final keptAfternoon = after.firstWhere((log) => log.id == afternoon.id);
      final evening = after.firstWhere((log) => log.scheduledTime.hour == 20);

      expect(keptMorning.isTaken, isTrue);
      expect(keptMorning.scheduledTime.hour, 8);
      expect(keptAfternoon.skipped, isTrue);
      expect(keptAfternoon.scheduledTime.hour, 14);
      expect(evening.isPending, isTrue);
      expect(evening.id, isNot(morning.id));
      expect(evening.id, isNot(afternoon.id));
    },
  );

  test('dois horários já tomados não engolem um terceiro minuto', () async {
    await repo.saveMedication(
      med(
        id: 'a',
        name: 'Venvanse',
        times: const ['08:00', '14:00'],
        stock: 10,
      ),
    );
    final logs = await repo.getLogsForDate(day);
    final morning = logs.firstWhere((log) => log.scheduledTime.hour == 8);
    final afternoon = logs.firstWhere((log) => log.scheduledTime.hour == 14);
    await repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 2));
    await repo.markAsTaken(afternoon.id, DateTime(2026, 10, 1, 14, 2));
    final before = (await repo.getMedications()).single.remainingStock;

    final third = await repo.ensureDoseLog(
      medicationId: 'a',
      medicationName: 'Venvanse 30mg',
      scheduled: DateTime(2026, 10, 1, 20),
    );

    expect(third.id, isNot(morning.id));
    expect(third.id, isNot(afternoon.id));
    expect(third.isTaken, isFalse);
    expect(third.scheduledTime, DateTime(2026, 10, 1, 20));
    expect((await repo.logById(third.id))?.id, third.id);

    await repo.markAsTaken(third.id, DateTime(2026, 10, 1, 20, 4));

    expect((await repo.getMedications()).single.remainingStock, before - 1);
    final after = await repo.getLogsForDate(day);
    final kept = after.firstWhere((log) => log.id == third.id);
    expect(after, hasLength(3));
    expect(kept.isTaken, isTrue);
    expect(kept.scheduledTime.hour, 20);
    expect(
      after.firstWhere((log) => log.id == morning.id).scheduledTime.hour,
      8,
    );
    expect(
      after.firstWhere((log) => log.id == afternoon.id).scheduledTime.hour,
      14,
    );
  });

  test(
    'pular uma dose já tomada não devolve o estoque nem abre outro slot',
    () async {
      await repo.saveMedication(
        med(id: 'a', name: 'Venvanse', times: const ['08:00'], stock: 6),
      );
      final created = await repo.getLogsForDate(day);
      final takenAt = DateTime(2026, 10, 1, 8, 6);
      await repo.markAsTaken(created.single.id, takenAt);

      await repo.skipLog(created.single.id, 'voluntary');

      final stored = await repo.getMedications();
      expect(stored.single.remainingStock, 5);
      final after = await repo.getLogsForDate(day);
      expect(after, hasLength(1));
      expect(after.single.id, created.single.id);
      expect(after.single.takenAt, takenAt);
      expect(after.single.skipped, isTrue);
      expect(after.single.isTaken, isTrue);
    },
  );
}
