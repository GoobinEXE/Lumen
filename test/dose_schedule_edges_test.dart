import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('alinhamento que o dia não pode perder', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
    });

    Medication med({
      String dosage = '30mg',
      List<String> times = const ['08:00'],
    }) {
      return Medication(
        id: 'med-1',
        name: 'Venvanse',
        dosage: dosage,
        scheduledTimes: times,
      );
    }

    test('dose pulada no horário que saiu permanece no dia', () async {
      final day = DateTime(2026, 10, 1);
      await repo.saveMedication(med(times: const ['08:00', '14:00']));
      final created = await repo.getLogsForDate(day);
      final morning = created.firstWhere((log) => log.scheduledTime.hour == 8);

      await repo.skipLog(morning.id, 'voluntary');
      await repo.saveMedication(med(times: const ['14:00']));
      final left = await repo.getLogsForDate(day);

      expect(left, hasLength(2));
      final kept = left.firstWhere((log) => log.id == morning.id);
      expect(kept.skipped, isTrue);
      expect(kept.skipReason, 'voluntary');
      expect(kept.scheduledTime, DateTime(2026, 10, 1, 8));
      expect(
        left.any(
          (log) => log.scheduledTime.hour == 14 && log.isPending,
        ),
        isTrue,
      );
    });

    test('trocar a dose reescreve o nome da pendente', () async {
      final day = DateTime(2026, 10, 1);
      await repo.saveMedication(med());
      final created = await repo.getLogsForDate(day);

      await repo.saveMedication(med(dosage: '50mg'));
      final renamed = await repo.getLogsForDate(day);

      expect(renamed.single.id, created.single.id);
      expect(renamed.single.medicationName, 'Venvanse 50mg');
      expect(renamed.single.isPending, isTrue);
    });

    test('dose do Apple ainda não tomada não ocupa o horário local', () async {
      final day = DateTime(2026, 10, 1);
      await repo.saveMedication(med());
      await repo.addExternalLog(
        MedicationLog(
          id: 'apple-1',
          medicationId: 'med-1',
          medicationName: 'Venvanse 30mg',
          scheduledTime: DateTime(2026, 10, 1, 12),
          source: MedicationLogSource.appleHealth,
        ),
      );

      final logs = await repo.getLogsForDate(day);
      final apple = logs.singleWhere(
        (log) => log.source == MedicationLogSource.appleHealth,
      );
      final local = logs.singleWhere(
        (log) => log.source == MedicationLogSource.lumen,
      );

      expect(logs, hasLength(2));
      expect(apple.scheduledTime, DateTime(2026, 10, 1, 12));
      expect(apple.isPending, isTrue);
      expect(local.scheduledTime, DateTime(2026, 10, 1, 8));
      expect(local.isPending, isTrue);
    });
  });

  test('conceito vazio não vira importação', () {
    final blank = Medication.fromMap({
      'id': '1',
      'name': 'Venvanse',
      'dosage': '30mg',
      'scheduledTimes': ['08:00'],
      'appleConceptId': '',
      'source': 'nope',
    });

    expect(blank.source, MedicationSource.local);
    expect(blank.isLinkedToAppleHealth, isFalse);
    expect(blank.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);

    final imported = Medication.fromMap({
      'id': '2',
      'name': 'Venvanse',
      'dosage': '30mg',
      'scheduledTimes': ['08:00'],
      'appleConceptId': 'concept',
      'source': 'nope',
    });
    expect(imported.source, MedicationSource.appleHealth);
    expect(imported.isLinkedToAppleHealth, isTrue);

    final linked = Medication.fromMap({
      'id': '3',
      'name': 'Venvanse',
      'dosage': '30mg',
      'scheduledTimes': ['08:00'],
      'appleConceptId': 'concept',
      'source': 'linked',
    });
    expect(linked.source, MedicationSource.linked);
  });
}
