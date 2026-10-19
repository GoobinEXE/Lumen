import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/medications/presentation/providers/medication_providers.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';

void main() {
  test('o segundo 59 ocupa o minuto e o minuto seguinte vira outra dose', () {
    final existing = [
      MedicationLog(
        id: 'local',
        medicationId: 'm1',
        medicationName: 'Lis 30mg',
        scheduledTime: DateTime(2026, 10, 8, 10),
      ),
    ];
    final merged = mergeDoseEventsIntoLogs(
      medicationId: 'm1',
      medicationName: 'Lis 30mg',
      existing: existing,
      events: [
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'taken',
          loggedAt: DateTime(2026, 10, 8, 10, 0, 59),
        ),
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'skipped',
          loggedAt: DateTime(2026, 10, 8, 10, 1),
        ),
      ],
    );

    expect(merged, hasLength(2));
    final local = merged.singleWhere((log) => log.id == 'local');
    expect(local.isTaken, isFalse);
    expect(local.source, MedicationLogSource.lumen);

    final extra = merged.singleWhere((log) => log.id != 'local');
    expect(extra.scheduledTime, DateTime(2026, 10, 8, 10, 1));
    expect(extra.skipped, isTrue);
    expect(extra.isTaken, isFalse);
    expect(extra.source, MedicationLogSource.appleHealth);
  });

  test('pendente de um remédio não ocupa o horário vazio do outro', () {
    final day = DateTime(2026, 10, 8);
    const medA = Medication(
      id: 'a',
      name: 'Lis',
      dosage: '30mg',
      scheduledTimes: ['14:00'],
    );
    const medB = Medication(
      id: 'b',
      name: 'Ritalina',
      dosage: '10mg',
      scheduledTimes: ['08:00'],
    );
    final stray = MedicationLog(
      id: 'b-pendente',
      medicationId: 'b',
      medicationName: 'Ritalina 10mg',
      scheduledTime: DateTime(2026, 10, 8, 11),
    );
    final takenOffSchedule = MedicationLog(
      id: 'b-tomada',
      medicationId: 'b',
      medicationName: 'Ritalina 10mg',
      scheduledTime: DateTime(2026, 10, 8, 19),
      takenAt: DateTime(2026, 10, 8, 19, 5),
    );

    final result = MedicationRepository.alignDayLogs(
      day,
      const [medA, medB],
      [stray, takenOffSchedule],
    );

    final afternoon = result.singleWhere(
      (log) => log.medicationId == 'a' && log.scheduledTime.hour == 14,
    );
    expect(afternoon.id, isNot('b-pendente'));
    expect(afternoon.id, isNot('b-tomada'));
    expect(afternoon.isPending, isTrue);

    final morning = result.singleWhere((log) => log.id == 'b-pendente');
    expect(morning.medicationId, 'b');
    expect(morning.scheduledTime, DateTime(2026, 10, 8, 8));
    expect(morning.isPending, isTrue);

    final kept = result.singleWhere((log) => log.id == 'b-tomada');
    expect(kept.medicationId, 'b');
    expect(kept.scheduledTime, DateTime(2026, 10, 8, 19));
    expect(kept.isTaken, isTrue);
  });
}
