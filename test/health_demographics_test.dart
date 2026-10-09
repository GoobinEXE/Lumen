import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/profile/domain/health_demographics_mapper.dart';
import 'package:noa/features/profile/domain/user_profile.dart';
import 'package:noa/integrations/health/models/health_demographics.dart';

void main() {
  test('sexo biológico vem do raw value do HealthKit', () {
    expect(
      HealthDemographics.sexFromHealthKitRawValue(1),
      HealthBiologicalSex.female,
    );
    expect(
      HealthDemographics.sexFromHealthKitRawValue(2),
      HealthBiologicalSex.male,
    );
    expect(
      HealthDemographics.sexFromHealthKitRawValue(3),
      HealthBiologicalSex.other,
    );
  });

  test('raw value ausente ou fora da tabela não vira sexo biológico', () {
    // 0 é o notSet do HealthKit e também o fallback do plugin para valor nulo.
    expect(HealthDemographics.sexFromHealthKitRawValue(0), isNull);
    expect(HealthDemographics.sexFromHealthKitRawValue(null), isNull);
    expect(HealthDemographics.sexFromHealthKitRawValue(42), isNull);
  });

  test('altura converte para centímetros conforme a unidade', () {
    expect(HealthDemographics.heightToCm(1.75, 'METER'), closeTo(175, 0.001));
    expect(HealthDemographics.heightToCm(175, 'CENTIMETER'), 175);
    expect(HealthDemographics.heightToCm(69, 'INCH'), closeTo(175.26, 0.001));
    expect(HealthDemographics.heightToCm(6, 'FOOT'), closeTo(182.88, 0.001));
  });

  test('peso converte para quilos conforme a unidade', () {
    expect(HealthDemographics.weightToKg(72.5, 'KILOGRAM'), 72.5);
    expect(HealthDemographics.weightToKg(72500, 'GRAM'), closeTo(72.5, 0.001));
    expect(HealthDemographics.weightToKg(160, 'POUND'), closeTo(72.575, 0.001));
  });

  test('valor zerado ou unidade desconhecida não vira medida', () {
    expect(HealthDemographics.heightToCm(0, 'METER'), isNull);
    expect(HealthDemographics.heightToCm(null, 'METER'), isNull);
    expect(HealthDemographics.heightToCm(1.75, 'LITER'), isNull);
    expect(HealthDemographics.weightToKg(-3, 'KILOGRAM'), isNull);
    expect(HealthDemographics.weightToKg(72.5, 'DECIBEL'), isNull);
  });

  test('data de nascimento só sai de epoch positivo', () {
    final birth = DateTime.utc(1990, 5, 14);
    expect(
      HealthDemographics.birthDateFromEpochSeconds(
        birth.millisecondsSinceEpoch / 1000,
      )?.toUtc(),
      birth,
    );
    expect(HealthDemographics.birthDateFromEpochSeconds(0), isNull);
    expect(HealthDemographics.birthDateFromEpochSeconds(null), isNull);
  });

  test('demografia vazia não preenche nada do perfil', () {
    final profile = UserProfile(id: 'u1', updatedAt: DateTime(2026, 10, 6));
    final demographics = HealthDemographics.empty.toProfileDemographics();

    expect(HealthDemographics.empty.isEmpty, isTrue);
    expect(demographics.isEmpty, isTrue);

    final applied = profile.applyDemographicsGaps(demographics);
    expect(identical(applied, profile), isTrue);
    expect(applied.importedFromHealth, isFalse);
  });

  test('demografia do Health preenche só as lacunas do perfil', () {
    final profile = UserProfile(
      id: 'u1',
      updatedAt: DateTime(2026, 10, 6),
      weightKg: 60,
    );
    final demographics = HealthDemographics(
      birthDate: DateTime(1990, 5, 14),
      weightKg: 99,
      heightCm: 175,
      biologicalSex: HealthBiologicalSex.female,
    ).toProfileDemographics();

    expect(demographics.biologicalSex, 'female');

    final applied = profile.applyDemographicsGaps(demographics);
    expect(applied.weightKg, 60);
    expect(applied.heightCm, 175);
    expect(applied.birthDate, DateTime(1990, 5, 14));
    expect(applied.biologicalSex, 'female');
    expect(applied.importedFromHealth, isTrue);
  });

  test('HealthDemographics sobrevive a toMap/fromMap', () {
    final original = HealthDemographics(
      birthDate: DateTime(1990, 5, 14),
      weightKg: 72.5,
      heightCm: 175,
      biologicalSex: HealthBiologicalSex.other,
    );
    final restored = HealthDemographics.fromMap(original.toMap());

    expect(restored.birthDate, original.birthDate);
    expect(restored.weightKg, 72.5);
    expect(restored.heightCm, 175);
    expect(restored.biologicalSex, HealthBiologicalSex.other);
    expect(
      HealthDemographics.fromMap(HealthDemographics.empty.toMap()).isEmpty,
      isTrue,
    );
  });
}
