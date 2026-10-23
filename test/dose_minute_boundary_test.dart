import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/medications/presentation/providers/medication_providers.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';

void main() {
  test('08:00:59 ocupa o minuto e 08:01 abre outra dose', () {
    final local = MedicationLog(
      id: 'local-8',
      medicationId: 'm1',
      medicationName: 'Venvanse 30mg',
      scheduledTime: DateTime(2026, 10, 23, 8),
      takenAt: DateTime(2026, 10, 23, 8, 0, 10),
    );

    final merged = mergeDoseEventsIntoLogs(
      medicationId: 'm1',
      medicationName: 'Venvanse 30mg',
      existing: [local],
      events: [
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'taken',
          loggedAt: DateTime(2026, 10, 23, 8, 0, 59),
        ),
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'taken',
          loggedAt: DateTime(2026, 10, 23, 8, 1),
        ),
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'notTaken',
          loggedAt: DateTime(2026, 10, 23, 9),
        ),
      ],
    );

    expect(merged, hasLength(2));
    expect(merged.first.id, 'local-8');
    expect(merged.last.scheduledTime, DateTime(2026, 10, 23, 8, 1));
    expect(merged.last.isTaken, isTrue);
    expect(merged.last.source, MedicationLogSource.appleHealth);
    expect(
      merged.any((log) => log.scheduledTime.hour == 9),
      isFalse,
    );
  });
}
