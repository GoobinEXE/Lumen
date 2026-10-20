import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/medications/presentation/providers/medication_providers.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('dose do dia que não pode duplicar nem sumir', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
    });

    Medication med({
      bool active = true,
      List<String> times = const ['08:00'],
      int remainingStock = 10,
    }) {
      return Medication(
        id: 'med-1',
        name: 'Venvanse',
        dosage: '30mg',
        scheduledTimes: times,
        active: active,
        totalStock: 30,
        remainingStock: remainingStock,
      );
    }

    test(
      'dose tomada do Apple no mesmo minuto ocupa o horário e não baixa o estoque',
      () async {
        final day = DateTime(2026, 10, 1);
        await repo.saveMedication(med());
        await repo.addExternalLog(
          MedicationLog(
            id: 'apple-1',
            medicationId: 'med-1',
            medicationName: 'Venvanse 30mg',
            scheduledTime: DateTime(2026, 10, 1, 8, 0, 45),
            takenAt: DateTime(2026, 10, 1, 8, 0, 45),
            source: MedicationLogSource.appleHealth,
          ),
        );

        final logs = await repo.getLogsForDate(day);

        expect(logs, hasLength(1));
        expect(logs.single.source, MedicationLogSource.appleHealth);
        expect(logs.single.isTaken, isTrue);
        expect(logs.single.scheduledTime, DateTime(2026, 10, 1, 8, 0, 45));
        expect((await repo.getMedications()).single.remainingStock, 10);
      },
    );

    test('pausar o remédio guarda a dose pulada e solta a pendente', () async {
      final day = DateTime(2026, 10, 1);
      await repo.saveMedication(med(times: const ['08:00', '14:00']));
      final created = await repo.getLogsForDate(day);
      final morning = created.firstWhere((log) => log.scheduledTime.hour == 8);

      await repo.skipLog(morning.id, 'voluntary');
      await repo.saveMedication(
        med(active: false, times: const ['08:00', '14:00']),
      );
      final left = await repo.getLogsForDate(day);

      expect(left, hasLength(1));
      expect(left.single.id, morning.id);
      expect(left.single.skipped, isTrue);
      expect(left.single.skipReason, 'voluntary');
      expect(left.single.scheduledTime, DateTime(2026, 10, 1, 8));
    });

    test(
      'tomar a dose pulada marca tomada e desconta o estoque uma vez',
      () async {
        final day = DateTime(2026, 10, 1, 8, 5);
        await repo.saveMedication(med(remainingStock: 4));
        final created = await repo.getLogsForDate(day);
        await repo.skipLog(created.single.id, 'voluntary');

        await repo.markAsTaken(created.single.id, day);
        final taken = await repo.logById(created.single.id);

        expect(taken!.isTaken, isTrue);
        expect(taken.skipped, isFalse);
        expect(taken.isPending, isFalse);
        expect(taken.takenAt, day);
        expect((await repo.getMedications()).single.remainingStock, 3);

        await repo.markAsTaken(
          created.single.id,
          day.add(const Duration(hours: 1)),
        );

        expect((await repo.getMedications()).single.remainingStock, 3);
        expect((await repo.logById(created.single.id))!.takenAt, day);
      },
    );
  });

  test('log local no mesmo instante não esconde a dose pulada do Apple', () {
    final when = DateTime(2026, 10, 1, 8);
    final merged = mergeDoseEventsIntoLogs(
      medicationId: 'med-1',
      medicationName: 'Venvanse 30mg',
      existing: [
        MedicationLog(
          id: 'local',
          medicationId: 'med-1',
          medicationName: 'Venvanse 30mg',
          scheduledTime: when,
          takenAt: when,
        ),
      ],
      events: [
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'skipped',
          loggedAt: when,
        ),
      ],
    );

    expect(merged, hasLength(2));
    final apple = merged.singleWhere(
      (log) => log.source == MedicationLogSource.appleHealth,
    );
    expect(apple.skipped, isTrue);
    expect(apple.isTaken, isFalse);
    expect(apple.scheduledTime, when);
  });
}
