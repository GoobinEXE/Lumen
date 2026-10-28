import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';

void main() {
  test('o rascunho seguinte mantém a medicação prescrita marcada', () {
    final saved = DailyRoutineState(
      date: DateTime(2026, 10, 28, 15, 4),
      waterGlasses: 3,
      tookPrescribedMedication: true,
      eveningReflection: 'fechou o dia',
      therapistNotes: 'pauta',
    );

    final next = saved.keptForNextSave();

    expect(next.tookPrescribedMedication, isTrue);
    expect(next.waterGlasses, 3);
    expect(next.date, DateTime(2026, 10, 28));
    expect(next.eveningReflection, isEmpty);
    expect(next.therapistNotes, isNull);
  });

  test('reabrir o dia lê a medicação do último salvamento', () {
    final morning = DateTime(2026, 10, 28, 8);
    final afternoon = DateTime(2026, 10, 28, 16);
    final markedLater = [
      RoutineSnapshot(
        id: 'afternoon',
        savedAt: afternoon,
        tookPrescribedMedication: true,
        waterGlasses: 2,
      ),
      RoutineSnapshot(
        id: 'morning',
        savedAt: morning,
        tookPrescribedMedication: false,
        waterGlasses: 1,
      ),
    ];
    final unmarkedLater = [
      RoutineSnapshot(
        id: 'morning',
        savedAt: morning,
        tookPrescribedMedication: true,
      ),
      RoutineSnapshot(
        id: 'afternoon',
        savedAt: afternoon,
        tookPrescribedMedication: false,
      ),
    ];

    expect(
      RoutineSnapshot.latestTookPrescribedMedication(markedLater),
      isTrue,
    );
    expect(
      RoutineSnapshot.latestTookPrescribedMedication(unmarkedLater),
      isFalse,
    );
    expect(
      RoutineSnapshot.latestTookPrescribedMedication(const []),
      isFalse,
    );
  });
}
