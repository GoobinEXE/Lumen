import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const logsKey = 'noa_medication_logs_v2';

  Medication twoSlots() {
    return const Medication(
      id: 'a',
      name: 'Venvanse',
      dosage: '30mg',
      scheduledTimes: ['08:00', '14:00'],
      remainingStock: 10,
    );
  }

  group('ensureDoseLog distingue os horários do mesmo remédio', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
      await repo.saveMedication(twoSlots());
    });

    test('o minuto pedido devolve o slot da tarde, não o da manhã', () async {
      final day = DateTime(2026, 10, 1, 15);
      final logs = await repo.getLogsForDate(day);
      final morning = logs.firstWhere((log) => log.scheduledTime.hour == 8);
      final afternoon = logs.firstWhere((log) => log.scheduledTime.hour == 14);

      final resolved = await repo.ensureDoseLog(
        medicationId: 'a',
        medicationName: 'Venvanse 30mg',
        scheduled: DateTime(2026, 10, 1, 14, 0, 45),
      );

      expect(resolved.id, afternoon.id);
      expect(resolved.id, isNot(morning.id));

      await repo.markAsTaken(resolved.id, DateTime(2026, 10, 1, 14, 5));

      final meds = await repo.getMedications();
      expect(meds.single.remainingStock, 9);

      final after = await repo.getLogsForDate(day);
      expect(after, hasLength(2));
      expect(after.firstWhere((log) => log.id == morning.id).isPending, isTrue);
      expect(after.firstWhere((log) => log.id == afternoon.id).isTaken, isTrue);
      expect(
        after.firstWhere((log) => log.id == afternoon.id).takenAt,
        DateTime(2026, 10, 1, 14, 5),
      );
    });

    test(
      'dois slots pendentes e um terceiro minuto não engolem os ids existentes',
      () async {
        final day = DateTime(2026, 10, 1, 15);
        final logs = await repo.getLogsForDate(day);
        final ids = logs.map((log) => log.id).toSet();

        final extra = await repo.ensureDoseLog(
          medicationId: 'a',
          medicationName: 'Venvanse 30mg',
          scheduled: DateTime(2026, 10, 1, 16),
        );

        expect(ids.contains(extra.id), isFalse);
        final all = await repo.getAllLogs();
        expect(all.map((log) => log.id).toSet(), {...ids, extra.id});
        expect(
          all.map((log) => log.scheduledTime.hour).toSet(),
          {8, 14, 16},
        );
      },
    );
  });

  test(
    'horário sem log, com um único log no dia, reaproveita esse log',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = MedicationRepository(prefs);

      final first = await repo.ensureDoseLog(
        medicationId: 'a',
        medicationName: 'Venvanse 30mg',
        scheduled: DateTime(2026, 10, 1, 8),
      );
      final reused = await repo.ensureDoseLog(
        medicationId: 'a',
        medicationName: 'Venvanse 30mg',
        scheduled: DateTime(2026, 10, 1, 9, 15),
      );

      expect(reused.id, first.id);
      expect((await repo.getAllLogs()), hasLength(1));
    },
  );

  test('leitura do dia não cria slot nem regrava o JSON', () async {
    final med = twoSlots();
    SharedPreferences.setMockInitialValues({
      'noa_medications_list_v2': jsonEncode([med.toMap()]),
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = MedicationRepository(prefs);
    final day = DateTime(2026, 10, 1, 15);

    final readOnly = await repo.getLogsForDateReadOnly(day);
    expect(readOnly, isEmpty);
    expect(prefs.getString(logsKey), isNull);

    final reconciled = await repo.getLogsForDate(day);
    expect(reconciled.map((log) => log.scheduledTime.hour).toSet(), {8, 14});
    expect(prefs.getString(logsKey), isNotNull);
  });

  test('leitura do dia mantém o log bom e não apaga o item podre', () async {
    final day = DateTime(2026, 10, 1);
    final good = MedicationLog(
      id: 'ok',
      medicationId: 'a',
      medicationName: 'Venvanse 30mg',
      scheduledTime: DateTime(2026, 10, 1, 8),
      takenAt: DateTime(2026, 10, 1, 8, 4),
    );
    final raw = jsonEncode([
      good.toMap(),
      {'id': 1},
    ]);
    SharedPreferences.setMockInitialValues({
      'noa_medications_list_v2': jsonEncode([twoSlots().toMap()]),
      logsKey: raw,
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = MedicationRepository(prefs);

    final logs = await repo.getLogsForDateReadOnly(day);

    expect(logs, hasLength(1));
    expect(logs.single.id, 'ok');
    expect(logs.single.isTaken, isTrue);
    expect(prefs.getString(logsKey), raw);
  });
}
