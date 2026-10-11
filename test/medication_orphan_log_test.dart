import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const logsKey = 'noa_medication_logs_v2';

  test(
    'log de remédio apagado sai na reconciliação do dia e fica na leitura',
    () async {
      final day = DateTime(2026, 10, 6);
      final vivo = Medication(
        id: 'vivo',
        name: 'Lis',
        dosage: '30mg',
        scheduledTimes: const ['08:00'],
      );
      final tomada = MedicationLog(
        id: 'tomada',
        medicationId: 'vivo',
        medicationName: 'Lis 30mg',
        scheduledTime: DateTime(2026, 10, 6, 8),
        takenAt: DateTime(2026, 10, 6, 8, 4),
      );
      final orfao = MedicationLog(
        id: 'orfao',
        medicationId: 'apagado',
        medicationName: 'Ritalina 10mg',
        scheduledTime: DateTime(2026, 10, 6, 9),
        takenAt: DateTime(2026, 10, 6, 9, 2),
      );
      final amanha = MedicationLog(
        id: 'orfao-amanha',
        medicationId: 'apagado',
        medicationName: 'Ritalina 10mg',
        scheduledTime: DateTime(2026, 10, 7, 9),
        takenAt: DateTime(2026, 10, 7, 9, 2),
      );

      SharedPreferences.setMockInitialValues({
        'noa_medications_list_v2': jsonEncode([vivo.toMap()]),
        logsKey: jsonEncode([tomada.toMap(), orfao.toMap(), amanha.toMap()]),
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = MedicationRepository(prefs);
      await repo.reload();
      final rawBefore = prefs.getString(logsKey);

      final leitura = await repo.getLogsForDateReadOnly(day);
      expect(leitura.map((log) => log.id), ['tomada', 'orfao']);
      expect(prefs.getString(logsKey), rawBefore);

      final reconciliado = await repo.getLogsForDate(day);
      expect(reconciliado.map((log) => log.id), ['tomada']);

      final stored = jsonDecode(prefs.getString(logsKey)!) as List<dynamic>;
      final ids = stored.map((item) => (item as Map)['id']).toList();
      expect(ids, contains('tomada'));
      expect(ids, contains('orfao-amanha'));
      expect(ids, isNot(contains('orfao')));

      final diaSeguinte = await repo.getLogsForDateReadOnly(
        DateTime(2026, 10, 7),
      );
      expect(diaSeguinte.single.id, 'orfao-amanha');
    },
  );
}
