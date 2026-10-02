import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/efficacy_window.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const medsKey = 'noa_medications_list_v2';

  group('estoque da dose', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
      await repo.saveMedication(
        const Medication(
          id: 'med-1',
          name: 'Venvanse',
          dosage: '30mg',
          scheduledTimes: ['08:00'],
          remainingStock: 5,
        ),
      );
    });

    Future<int> stock() async {
      final meds = await repo.getMedications();
      return meds.single.remainingStock;
    }

    test('tomar a dose baixa o estoque uma vez', () async {
      final log = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Venvanse 30mg',
        scheduled: DateTime(2026, 10, 1, 8),
      );

      await repo.markAsTaken(log.id, DateTime(2026, 10, 1, 8, 5));
      await repo.markAsTaken(log.id, DateTime(2026, 10, 1, 8, 6));

      final taken = await repo.logById(log.id);
      expect(taken!.isTaken, isTrue);
      expect(taken.takenAt, DateTime(2026, 10, 1, 8, 5));
      expect(await stock(), 4);
    });

    test('estoque zerado continua zerado e a dose fica tomada', () async {
      await repo.saveMedication(
        const Medication(
          id: 'med-1',
          name: 'Venvanse',
          dosage: '30mg',
          scheduledTimes: ['08:00'],
          remainingStock: 0,
        ),
      );
      final log = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Venvanse 30mg',
        scheduled: DateTime(2026, 10, 1, 8),
      );

      await repo.markAsTaken(log.id, DateTime(2026, 10, 1, 8, 5));

      expect((await repo.logById(log.id))!.isTaken, isTrue);
      expect(await stock(), 0);
    });

    test('pular a dose não mexe no estoque', () async {
      final log = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Venvanse 30mg',
        scheduled: DateTime(2026, 10, 1, 8),
      );

      await repo.skipLog(log.id, 'voluntary');

      expect(await stock(), 5);
      expect((await repo.logById(log.id))!.skipped, isTrue);
    });

    test('id desconhecido não altera o estoque', () async {
      await repo.markAsTaken('nao-existe', DateTime(2026, 10, 1, 8));
      expect(await stock(), 5);
    });
  });

  group('log externo e dose repetida', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
      await repo.saveMedication(
        const Medication(
          id: 'med-1',
          name: 'Venvanse',
          dosage: '30mg',
          scheduledTimes: ['08:00'],
          remainingStock: 12,
        ),
      );
    });

    test('dose do Apple Health não duplica e não baixa o estoque', () async {
      final when = DateTime(2026, 10, 1, 12);
      final external = MedicationLog(
        id: 'apple-1',
        medicationId: 'med-1',
        medicationName: 'Venvanse 30mg',
        scheduledTime: when,
        takenAt: when,
        source: MedicationLogSource.appleHealth,
      );

      await repo.addExternalLog(external);
      await repo.addExternalLog(external);

      final day = await repo.getLogsForDate(when);
      final apple = day.where(
        (log) => log.source == MedicationLogSource.appleHealth,
      );
      expect(apple, hasLength(1));
      expect(apple.single.scheduledTime, when);
      final meds = await repo.getMedications();
      expect(meds.single.remainingStock, 12);
    });

    test('ensureDoseLog devolve a mesma dose no mesmo minuto', () async {
      final scheduled = DateTime(2026, 10, 1, 8, 0, 10);
      final first = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Venvanse 30mg',
        scheduled: scheduled,
      );
      final second = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Venvanse 30mg',
        scheduled: scheduled.add(const Duration(seconds: 40)),
      );

      expect(second.id, first.id);
      final day = await repo.getLogsForDate(scheduled);
      expect(
        day.where((log) => log.medicationId == 'med-1'),
        hasLength(1),
      );
    });
  });

  group('alinhamento do dia', () {
    late MedicationRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = MedicationRepository(prefs);
    });

    Medication med({
      List<String> times = const ['08:00'],
      List<int> days = const [1, 2, 3, 4, 5, 6, 7],
      bool active = true,
    }) {
      return Medication(
        id: 'med-1',
        name: 'Venvanse',
        dosage: '30mg',
        scheduledTimes: times,
        daysOfWeek: days,
        active: active,
      );
    }

    test('dia fora da semana e remédio inativo não criam dose pendente', () async {
      final thursday = DateTime(2026, 10, 1);
      expect(thursday.weekday, DateTime.thursday);

      await repo.saveMedication(med(days: const [DateTime.friday]));
      expect(await repo.getLogsForDate(thursday), isEmpty);

      await repo.saveMedication(med(active: false));
      expect(await repo.getLogsForDate(thursday), isEmpty);
    });

    test('horário repetido vira uma dose só', () async {
      await repo.saveMedication(med(times: const ['08:00', '8:00', '08:00']));

      final logs = await repo.getLogsForDate(DateTime(2026, 10, 1));

      expect(logs, hasLength(1));
      expect(logs.single.scheduledTime, DateTime(2026, 10, 1, 8));
    });

    test('mudar o horário leva a dose pendente e descarta a que saiu', () async {
      final day = DateTime(2026, 10, 1);
      await repo.saveMedication(med(times: const ['08:00', '14:00']));
      final created = await repo.getLogsForDate(day);
      expect(created, hasLength(2));
      final morning = created.firstWhere(
        (log) => log.scheduledTime.hour == 8,
      );

      await repo.saveMedication(med(times: const ['09:30']));
      final moved = await repo.getLogsForDate(day);

      expect(moved, hasLength(1));
      expect(moved.single.id, morning.id);
      expect(moved.single.scheduledTime, DateTime(2026, 10, 1, 9, 30));
    });

    test('dose tomada num horário que saiu permanece no dia', () async {
      final day = DateTime(2026, 10, 1);
      await repo.saveMedication(med(times: const ['08:00', '14:00']));
      final created = await repo.getLogsForDate(day);
      final morning = created.firstWhere(
        (log) => log.scheduledTime.hour == 8,
      );
      await repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 10));

      await repo.saveMedication(med(times: const ['14:00']));
      final left = await repo.getLogsForDate(day);

      expect(left, hasLength(2));
      final kept = left.firstWhere((log) => log.id == morning.id);
      expect(kept.isTaken, isTrue);
      expect(kept.scheduledTime.hour, 8);
      expect(left.any((log) => log.scheduledTime.hour == 14), isTrue);
    });

    test('inativar o remédio tira a pendente e guarda a tomada', () async {
      final day = DateTime(2026, 10, 1);
      await repo.saveMedication(med(times: const ['08:00', '14:00']));
      final created = await repo.getLogsForDate(day);
      final morning = created.firstWhere(
        (log) => log.scheduledTime.hour == 8,
      );
      await repo.markAsTaken(morning.id, DateTime(2026, 10, 1, 8, 10));

      await repo.saveMedication(med(active: false));
      final left = await repo.getLogsForDate(day);

      expect(left, hasLength(1));
      expect(left.single.id, morning.id);
      expect(left.single.isTaken, isTrue);
    });

    test('reconciliar um dia não apaga a dose de outro', () async {
      await repo.saveMedication(med());
      final friday = await repo.ensureDoseLog(
        medicationId: 'med-1',
        medicationName: 'Venvanse 30mg',
        scheduled: DateTime(2026, 10, 2, 8),
      );

      await repo.getLogsForDate(DateTime(2026, 10, 1));

      final still = await repo.logById(friday.id);
      expect(still, isNotNull);
      expect(still!.scheduledTime, DateTime(2026, 10, 2, 8));
    });

    test('JSON corrompido de remédios vira lista vazia', () async {
      SharedPreferences.setMockInitialValues({
        medsKey: '{nao e json',
      });
      final prefs = await SharedPreferences.getInstance();
      final broken = MedicationRepository(prefs);

      expect(await broken.getMedications(), isEmpty);

      SharedPreferences.setMockInitialValues({
        medsKey: jsonEncode([
          {'id': 'sem-horario'},
        ]),
      });
      final prefs2 = await SharedPreferences.getInstance();
      final partial = MedicationRepository(prefs2);
      expect(await partial.getMedications(), isEmpty);
    });
  });

  group('cadastro antigo', () {
    test('emoji legado vira ícone e o conceito antigo define a origem', () {
      final tablet = Medication.fromMap({
        'id': '1',
        'name': 'Ritalina',
        'dosage': '10mg',
        'scheduledTimes': ['14:00'],
        'shapeEmoji': '⚪',
        'healthKitMedicationId': 'legacy-id',
      });
      expect(tablet.shapeIcon, 'tablet');
      expect(tablet.appleConceptId, 'legacy-id');
      expect(tablet.source, MedicationSource.appleHealth);
      expect(tablet.isLinkedToAppleHealth, isTrue);

      final explicit = Medication.fromMap({
        'id': '2',
        'name': 'Ritalina',
        'dosage': '10mg',
        'scheduledTimes': ['14:00'],
        'shapeIcon': 'drop',
        'shapeEmoji': '⚪',
      });
      expect(explicit.shapeIcon, 'drop');
      expect(explicit.source, MedicationSource.local);

      expect(
        Medication.fromMap({
          'id': '3',
          'name': 'X',
          'dosage': '1',
          'scheduledTimes': ['08:00'],
          'shapeEmoji': '🧴',
        }).shapeIcon,
        'liquid',
      );
      expect(
        Medication.fromMap({
          'id': '4',
          'name': 'X',
          'dosage': '1',
          'scheduledTimes': ['08:00'],
          'shapeEmoji': '💧',
        }).shapeIcon,
        'drop',
      );
    });
  });

  test('janela curta fica dentro da hora e o pico não inclui as bordas', () {
    final taken = DateTime(2026, 10, 1, 8);
    final window = EfficacyWindow.ofDose(takenAt: taken, durationHours: 0);

    expect(window.crashTime, taken.add(const Duration(hours: 1)));
    expect(window.peakStart.isAfter(taken), isTrue);
    expect(window.peakEnd.isAfter(window.peakStart), isTrue);
    expect(window.peakEnd.isBefore(window.crashTime), isTrue);
    expect(
      window.isInPeak(window.peakStart.add(const Duration(microseconds: 1))),
      isTrue,
    );
    expect(window.isInPeak(taken), isFalse);
    expect(window.isInPeak(window.peakStart), isFalse);
    expect(window.isInPeak(window.peakEnd), isFalse);
    expect(window.isInPeak(window.crashTime), isFalse);
  });
}
