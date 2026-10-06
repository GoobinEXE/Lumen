import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const monday = '2026-10-05';
  final mondayMorning = DateTime(2026, 10, 5, 10);
  final wednesdayMorning = DateTime(2026, 10, 7, 10);

  Medication med({
    bool active = true,
    List<String> scheduledTimes = const ['08:00'],
    List<int> daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    int remainingStock = 30,
  }) {
    return Medication(
      id: 'a',
      name: 'Venvanse',
      dosage: '30mg',
      scheduledTimes: scheduledTimes,
      active: active,
      daysOfWeek: daysOfWeek,
      remainingStock: remainingStock,
    );
  }

  Future<MedicationRepository> openRepo([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    final prefs = await SharedPreferences.getInstance();
    return MedicationRepository(prefs);
  }

  test('horário repetido no mesmo minuto vira uma dose só', () async {
    final repo = await openRepo();
    await repo.saveMedication(
      med(scheduledTimes: const ['08:00', '08:00', '8:00']),
    );

    final logs = await repo.getLogsForDate(mondayMorning);

    expect(logs, hasLength(1));
    expect(logs.single.scheduledTime, DateTime(2026, 10, 5, 8));
  });

  test('dia fora da semana não cria dose e não apaga a de segunda', () async {
    final repo = await openRepo();
    await repo.saveMedication(med(daysOfWeek: const [DateTime.monday]));

    final onMonday = await repo.getLogsForDate(mondayMorning);
    final onWednesday = await repo.getLogsForDate(wednesdayMorning);
    final mondayAgain = await repo.getLogsForDate(mondayMorning);

    expect(DateTime.parse(monday).weekday, DateTime.monday);
    expect(wednesdayMorning.weekday, DateTime.wednesday);
    expect(onMonday, hasLength(1));
    expect(onWednesday, isEmpty);
    expect(mondayAgain.single.id, onMonday.single.id);
  });

  test('remédio pausado some da pendente e a dose tomada fica', () async {
    final repo = await openRepo();
    final active = med();
    await repo.saveMedication(active);
    await repo.getLogsForDate(mondayMorning);
    await repo.saveMedication(active.copyWith(active: false));

    expect(await repo.getLogsForDate(mondayMorning), isEmpty);

    await repo.saveMedication(active);
    final created = await repo.getLogsForDate(mondayMorning);
    await repo.markAsTaken(created.single.id, DateTime(2026, 10, 5, 8, 4));
    await repo.saveMedication(active.copyWith(active: false));
    final kept = await repo.getLogsForDate(mondayMorning);

    expect(kept, hasLength(1));
    expect(kept.single.id, created.single.id);
    expect(kept.single.isTaken, isTrue);
  });

  test('estoque zerado não fica negativo', () async {
    final repo = await openRepo();
    await repo.saveMedication(med(remainingStock: 0));
    final logs = await repo.getLogsForDate(mondayMorning);

    await repo.markAsTaken(logs.single.id, DateTime(2026, 10, 5, 8, 2));
    await repo.markAsTaken('nao-existe', DateTime(2026, 10, 5, 8, 3));

    final stored = await repo.getMedications();
    expect(stored.single.remainingStock, 0);
    expect((await repo.logById(logs.single.id))!.isTaken, isTrue);
  });

  test('JSON ilegível devolve lista vazia em vez de quebrar o dia', () async {
    final repo = await openRepo({
      'noa_medications_list_v2': '{',
      'noa_medication_logs_v2': 'nao-e-lista',
    });

    expect(await repo.getMedications(), isEmpty);
    expect(await repo.getLogsForDate(mondayMorning), isEmpty);
  });

  test('a mesma dose do Apple Health não entra duas vezes', () async {
    final repo = await openRepo();
    final when = DateTime(2026, 10, 5, 8, 0, 12);
    final apple = MedicationLog(
      id: 'ext-1',
      medicationId: 'a',
      medicationName: 'Venvanse 30mg',
      scheduledTime: when,
      takenAt: when,
      source: MedicationLogSource.appleHealth,
    );

    await repo.addExternalLog(apple);
    await repo.addExternalLog(
      MedicationLog(
        id: 'ext-2',
        medicationId: apple.medicationId,
        medicationName: apple.medicationName,
        scheduledTime: when,
        takenAt: when,
        source: MedicationLogSource.appleHealth,
      ),
    );

    expect(await repo.logById('ext-1'), isNotNull);
    expect(await repo.logById('ext-2'), isNull);
  });
}
