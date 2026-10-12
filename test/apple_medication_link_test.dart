import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/medication.dart';
import 'package:noa/features/medications/service/apple_medication_link.dart';
import 'package:noa/integrations/healthkit_bridge/healthkit_bridge.dart';

void main() {
  HealthKitMedicationInfo info({
    String concept = 'concept-1',
    String name = 'Lisdexanfetamina',
    String? nickname,
    String? form,
    String? rxNorm,
    bool active = true,
  }) {
    return HealthKitMedicationInfo(
      appleConceptId: concept,
      name: name,
      nickname: nickname,
      form: form,
      rxNormCode: rxNorm,
      isActive: active,
    );
  }

  Medication local({
    required String id,
    required String name,
    String dosage = '30mg',
    List<String> times = const ['21:00'],
    String? concept,
    String? rxNorm,
  }) {
    return Medication(
      id: id,
      name: name,
      dosage: dosage,
      scheduledTimes: times,
      appleConceptId: concept,
      rxNormCode: rxNorm,
    );
  }

  AppleMedicationLink? link({
    required HealthKitMedicationInfo remote,
    required List<Medication> existing,
    String Function()? newId,
  }) {
    return linkAppleMedication(
      info: remote,
      existing: existing,
      newId: newId ?? () => 'novo',
      fallbackDosage: 'dose',
      fallbackInstructions: 'conforme a receita',
    );
  }

  test('remédio inativo no Saúde não entra nem liga um cadastro local', () {
    final result = link(
      remote: info(active: false, name: 'Venvanse'),
      existing: [local(id: 'local', name: 'Venvanse')],
      newId: () => throw StateError('não cria id'),
    );

    expect(result, isNull);
  });

  test('o mesmo concept id não conta de novo e não troca o horário local', () {
    var created = 0;
    final result = link(
      remote: info(name: 'Outro nome', rxNorm: '123'),
      existing: [
        local(id: 'outro', name: 'Outro nome'),
        local(
          id: 'local',
          name: 'Venvanse',
          concept: 'concept-1',
          times: const ['08:00', '14:00'],
          rxNorm: 'antigo',
        ),
      ],
      newId: () {
        created++;
        return 'nao-usar';
      },
    );

    expect(created, 0);
    expect(result!.countsAsImported, isFalse);
    expect(result.medication.id, 'local');
    expect(result.medication.name, 'Venvanse');
    expect(result.medication.scheduledTimes, ['08:00', '14:00']);
    expect(result.medication.rxNormCode, '123');
    expect(result.medication.source, MedicationSource.linked);
  });

  test('concept já ligado conserva o código quando o Saúde não manda outro', () {
    final result = link(
      remote: info(),
      existing: [
        local(id: 'local', name: 'Venvanse', concept: 'concept-1', rxNorm: 'antigo'),
      ],
    );

    expect(result!.medication.rxNormCode, 'antigo');
    expect(result.countsAsImported, isFalse);
  });

  test('nome igual ignora maiúscula, liga o concept e conta como importado', () {
    final result = link(
      remote: info(name: 'VENVANSE', rxNorm: '999'),
      existing: [
        local(id: 'local', name: 'Venvanse', times: const ['21:00'], rxNorm: 'antigo'),
      ],
    );

    expect(result!.countsAsImported, isTrue);
    expect(result.medication.id, 'local');
    expect(result.medication.appleConceptId, 'concept-1');
    expect(result.medication.scheduledTimes, ['21:00']);
    expect(result.medication.rxNormCode, '999');
    expect(result.medication.source, MedicationSource.linked);
  });

  test('apelido casa com o nome local e apelido vazio não apaga o código', () {
    final byNickname = link(
      remote: info(name: 'Lisdexanfetamina', nickname: 'Venvanse'),
      existing: [local(id: 'local', name: 'Venvanse', rxNorm: 'antigo')],
    );
    expect(byNickname!.medication.id, 'local');
    expect(byNickname.medication.rxNormCode, 'antigo');
    expect(byNickname.countsAsImported, isTrue);

    final blankNickname = link(
      remote: info(name: 'Lisdexanfetamina', nickname: ''),
      existing: [local(id: 'local', name: 'Venvanse')],
    );
    expect(blankNickname!.medication.id, isNot('local'));
    expect(blankNickname.medication.name, 'Lisdexanfetamina');
  });

  test('cadastro novo usa apelido, forma e o horário das 08:00', () {
    final result = link(
      remote: info(
        name: 'Lisdexanfetamina',
        nickname: 'Venvanse',
        form: 'cápsula',
        rxNorm: '55',
      ),
      existing: const [],
    );

    expect(result!.countsAsImported, isTrue);
    expect(result.medication.id, 'novo');
    expect(result.medication.name, 'Venvanse');
    expect(result.medication.dosage, 'cápsula');
    expect(result.medication.scheduledTimes, ['08:00']);
    expect(result.medication.instructions, 'conforme a receita');
    expect(result.medication.appleConceptId, 'concept-1');
    expect(result.medication.rxNormCode, '55');
    expect(result.medication.source, MedicationSource.appleHealth);
  });

  test('sem forma e sem apelido usa o nome oficial e a dose de reserva', () {
    final result = link(
      remote: info(nickname: null, form: null),
      existing: const [],
    );

    expect(result!.medication.name, 'Lisdexanfetamina');
    expect(result.medication.dosage, 'dose');
  });
}
