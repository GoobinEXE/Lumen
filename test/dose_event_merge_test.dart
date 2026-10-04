import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/medications/presentation/providers/medication_providers.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';

void main() {
  final when = DateTime(2026, 10, 1, 12, 30);

  List<MedicationLog> merge(List<HealthKitDoseEvent> events) {
    return mergeDoseEventsIntoLogs(
      medicationId: 'med-1',
      medicationName: 'Venvanse 30mg',
      existing: const [],
      events: events,
    );
  }

  test('status fora de tomada ou pulada não entra no dia', () {
    final logs = merge([
      HealthKitDoseEvent(
        appleConceptId: 'c1',
        status: 'scheduled',
        loggedAt: when,
      ),
      HealthKitDoseEvent(
        appleConceptId: 'c1',
        status: 'notTaken',
        loggedAt: when.add(const Duration(hours: 1)),
      ),
    ]);

    expect(logs, isEmpty);
  });

  test('pulada do Apple fica pulada e não tomada', () {
    final logs = merge([
      HealthKitDoseEvent(
        appleConceptId: 'c1',
        status: 'skipped',
        loggedAt: when,
      ),
    ]);

    expect(logs, hasLength(1));
    expect(logs.single.skipped, isTrue);
    expect(logs.single.takenAt, isNull);
    expect(logs.single.isPending, isFalse);
    expect(logs.single.source, MedicationLogSource.appleHealth);
    expect(logs.single.id, 'apple_${when.millisecondsSinceEpoch}_med-1');
  });

  test('o mesmo instante não entra de novo com outro status', () {
    final first = merge([
      HealthKitDoseEvent(
        appleConceptId: 'c1',
        status: 'taken',
        loggedAt: when,
      ),
    ]);
    final again = mergeDoseEventsIntoLogs(
      medicationId: 'med-1',
      medicationName: 'Venvanse 30mg',
      existing: first,
      events: [
        HealthKitDoseEvent(
          appleConceptId: 'c1',
          status: 'skipped',
          loggedAt: when,
        ),
      ],
    );

    expect(again, hasLength(1));
    expect(again.single.isTaken, isTrue);
    expect(again.single.skipped, isFalse);
  });
}
