import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('estoque 5.0 avisa e 5.6 arredonda para fora do aviso', () {
    final atLimit = Medication.fromMap({
      'id': 'm-limit',
      'name': 'Venvanse',
      'dosage': '30mg',
      'scheduledTimes': ['08:00'],
      'totalStock': 30.0,
      'remainingStock': 5.0,
      'refillWarningThreshold': 5.0,
      'durationHours': 4.4,
      'daysOfWeek': [1.0, 7.0],
    });

    expect(atLimit.remainingStock, 5);
    expect(atLimit.totalStock, 30);
    expect(atLimit.refillWarningThreshold, 5);
    expect(atLimit.needsRefillWarning, isTrue);
    expect(atLimit.durationHours, 4);
    expect(atLimit.daysOfWeek, [1, 7]);

    final above = Medication.fromMap({
      'id': 'm-above',
      'name': 'Venvanse',
      'dosage': '30mg',
      'scheduledTimes': ['08:00'],
      'remainingStock': 5.6,
      'refillWarningThreshold': 5,
    });
    expect(above.remainingStock, 6);
    expect(above.needsRefillWarning, isFalse);
    expect(above.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
  });

  test('salvar o irmão não apaga o cadastro que veio com decimal', () async {
    SharedPreferences.setMockInitialValues({
      'noa_medications_list_v2': jsonEncode([
        {
          'id': 'm-double',
          'name': 'Venvanse',
          'dosage': '30mg',
          'scheduledTimes': ['08:00'],
          'totalStock': 30.0,
          'remainingStock': 5.0,
          'refillWarningThreshold': 5.0,
          'durationHours': 10.0,
          'daysOfWeek': [1.0, 7.0],
          'active': true,
        },
        {
          'id': 'm-plain',
          'name': 'Ritalina',
          'dosage': '10mg',
          'scheduledTimes': ['14:00'],
          'daysOfWeek': [1, 2, 3, 4, 5],
          'active': true,
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = MedicationRepository(prefs);

    final before = await repo.getMedications();
    final venvanse = before.singleWhere((med) => med.id == 'm-double');
    expect(venvanse.remainingStock, 5);
    expect(venvanse.needsRefillWarning, isTrue);
    expect(venvanse.daysOfWeek, [1, 7]);
    expect(venvanse.durationHours, 10);

    await repo.saveMedication(
      before.singleWhere((med) => med.id == 'm-plain').copyWith(dosage: '20mg'),
    );

    final after = await repo.getMedications();
    expect(after.map((med) => med.id).toSet(), {'m-double', 'm-plain'});
    expect(after.singleWhere((med) => med.id == 'm-double').remainingStock, 5);
    expect(after.singleWhere((med) => med.id == 'm-plain').dosage, '20mg');
  });
}
