import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/efficacy_window.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/integrations/health/models/sleep_night.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('logs do dia', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
    });

    test('segundo remédio do mesmo dia ganha a própria dose', () async {
      final day = DateTime(2026, 10, 1, 15);
      await repo.saveMedication(
        const Medication(
          id: 'a',
          name: 'Venvanse',
          dosage: '30mg',
          scheduledTimes: ['08:00'],
        ),
      );
      final first = await repo.getLogsForDate(day);
      expect(first, hasLength(1));

      await repo.saveMedication(
        const Medication(
          id: 'b',
          name: 'Ritalina',
          dosage: '10mg',
          scheduledTimes: ['14:00'],
        ),
      );
      final second = await repo.getLogsForDate(day);
      expect(second.map((log) => log.medicationId), containsAll(['a', 'b']));
      expect(second, hasLength(2));
    });

    test('apagar o remédio tira o log do dia', () async {
      final day = DateTime(2026, 10, 1, 9);
      await repo.saveMedication(
        const Medication(
          id: 'a',
          name: 'Venvanse',
          dosage: '30mg',
          scheduledTimes: ['08:00'],
        ),
      );
      await repo.saveMedication(
        const Medication(
          id: 'b',
          name: 'Ritalina',
          dosage: '10mg',
          scheduledTimes: ['14:00'],
        ),
      );
      await repo.getLogsForDate(day);
      await repo.deleteMedication('a');

      final left = await repo.getLogsForDate(day);
      expect(left.map((log) => log.medicationId), everyElement('b'));
      expect(left, hasLength(1));
    });
  });

  test('pico de 4 h fica entre a dose e o fim da janela', () {
    final taken = DateTime(2026, 10, 1, 8);
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 4);

    expect(window.peakStart.isAfter(taken), isTrue);
    expect(window.peakStart.isBefore(window.peakEnd), isTrue);
    expect(window.peakEnd.isBefore(window.crashTime), isTrue);
    expect(window.crashTime, taken.add(const Duration(hours: 4)));
  });

  test('janela de 12 h mantém o platô das 2 h até 4 h antes do fim', () {
    final taken = DateTime(2026, 10, 1, 8);
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 12);

    expect(window.peakStart, taken.add(const Duration(hours: 2)));
    expect(window.peakEnd, taken.add(const Duration(hours: 8)));
    expect(window.crashTime, taken.add(const Duration(hours: 12)));
  });

  test(
    'noite que cruza a meia-noite vira um registro no dia em que acorda',
    () {
      final nights = SleepNight.aggregate([
        SleepInterval(
          kind: SleepIntervalKind.asleep,
          start: DateTime(2026, 9, 30, 23, 30),
          end: DateTime(2026, 10, 1, 2),
        ),
        SleepInterval(
          kind: SleepIntervalKind.rem,
          start: DateTime(2026, 10, 1, 5),
          end: DateTime(2026, 10, 1, 6),
        ),
        SleepInterval(
          kind: SleepIntervalKind.deep,
          start: DateTime(2026, 10, 1, 2),
          end: DateTime(2026, 10, 1, 3),
        ),
      ]);

      expect(nights, hasLength(1));
      expect(nights.single.date, DateTime(2026, 10, 1));
      expect(nights.single.remSleep, const Duration(hours: 1));
      expect(nights.single.deepSleep, const Duration(hours: 1));
      expect(nights.single.totalSleep, const Duration(hours: 2));
    },
  );

  test('sem estágio, o total usa só o tempo adormecido', () {
    final nights = SleepNight.aggregate([
      SleepInterval(
        kind: SleepIntervalKind.asleep,
        start: DateTime(2026, 9, 30, 23),
        end: DateTime(2026, 10, 1, 6),
      ),
    ]);

    expect(nights, hasLength(1));
    expect(nights.single.totalSleep, const Duration(hours: 7));
  });
}
