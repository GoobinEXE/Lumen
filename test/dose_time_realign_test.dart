import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final day = DateTime(2026, 10, 8, 12);

  late MedicationRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = MedicationRepository(prefs);
  });

  Medication med({required List<String> times}) {
    return Medication(
      id: 'a',
      name: 'Venvanse',
      dosage: '30mg',
      scheduledTimes: times,
      remainingStock: 10,
    );
  }

  test('mudar o horário leva a pendente junto e não deixa outra no horário velho', () async {
    await repo.saveMedication(med(times: const ['08:00']));
    final before = await repo.getLogsForDate(day);
    final id = before.single.id;

    await repo.saveMedication(med(times: const ['09:15']));
    final after = await repo.getLogsForDate(day);

    expect(after, hasLength(1));
    expect(after.single.id, id);
    expect(after.single.scheduledTime, DateTime(2026, 10, 8, 9, 15));
    expect(after.single.isPending, isTrue);
  });

  test('tirar o horário some com a pendente e conserva a dose já tomada', () async {
    await repo.saveMedication(med(times: const ['08:00', '21:00']));
    final created = await repo.getLogsForDate(day);
    final morning = created.firstWhere(
      (log) => log.scheduledTime == DateTime(2026, 10, 8, 8),
    );
    await repo.markAsTaken(morning.id, DateTime(2026, 10, 8, 8, 5));

    await repo.saveMedication(med(times: const ['08:00']));
    final left = await repo.getLogsForDate(day);

    expect(left, hasLength(1));
    expect(left.single.id, morning.id);
    expect(left.single.scheduledTime, DateTime(2026, 10, 8, 8));
    expect(left.single.isTaken, isTrue);
  });

  test('dose do Apple Health não muda de hora quando o lembrete local muda', () async {
    await repo.saveMedication(med(times: const ['08:00']));
    await repo.addExternalLog(
      MedicationLog(
        id: 'apple-7',
        medicationId: 'a',
        medicationName: 'Venvanse 30mg',
        scheduledTime: DateTime(2026, 10, 8, 7),
        source: MedicationLogSource.appleHealth,
      ),
    );
    final before = await repo.getLogsForDate(day);
    final local = before.singleWhere(
      (log) => log.source == MedicationLogSource.lumen,
    );

    await repo.saveMedication(med(times: const ['09:15']));
    final after = await repo.getLogsForDate(day);

    expect(after, hasLength(2));
    expect(
      after.singleWhere((log) => log.id == local.id).scheduledTime,
      DateTime(2026, 10, 8, 9, 15),
    );
    final apple = after.singleWhere((log) => log.id == 'apple-7');
    expect(apple.scheduledTime, DateTime(2026, 10, 8, 7));
    expect(apple.source, MedicationLogSource.appleHealth);
  });

  test('confirmar a mesma dose duas vezes baixa o estoque uma vez só', () async {
    await repo.saveMedication(med(times: const ['08:00']));
    final log = (await repo.getLogsForDate(day)).single;
    final takenAt = DateTime(2026, 10, 8, 8, 4);

    await repo.markAsTaken(log.id, takenAt);
    await repo.markAsTaken(log.id, DateTime(2026, 10, 8, 8, 9));
    await repo.markAsTaken('nao-existe', takenAt);

    final stored = await repo.logById(log.id);
    final saved = await repo.getMedications();

    expect(stored!.takenAt, takenAt);
    expect(stored.isTaken, isTrue);
    expect(saved.single.remainingStock, 9);
  });
}
