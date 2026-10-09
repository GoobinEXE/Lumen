import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/onboarding/data/onboarding_prefs.dart';
import 'package:noa/features/onboarding/domain/onboarding_profile_draft.dart';
import 'package:noa/features/profile/data/user_profile_repository.dart';
import 'package:noa/features/profile/domain/profile_demographics.dart';
import 'package:noa/features/profile/domain/user_profile.dart';
import 'package:noa/features/profile/domain/voice_tone_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('UserProfile round-trip keeps name', () {
    final profile = UserProfile(
      id: 'u1',
      name: 'Ana',
      updatedAt: DateTime(2026, 10, 2),
    );
    final restored = UserProfile.fromMap(profile.toMap());
    expect(restored.id, 'u1');
    expect(restored.trimmedName, 'Ana');
  });

  test('fromMap aceita shape antigo só com id/name/updatedAt', () {
    final restored = UserProfile.fromMap({
      'id': 'u1',
      'name': 'Ana',
      'updatedAt': DateTime(2026, 10, 2).toIso8601String(),
    });
    expect(restored.id, 'u1');
    expect(restored.trimmedName, 'Ana');
    expect(restored.birthDate, isNull);
    expect(restored.weightKg, isNull);
    expect(restored.heightCm, isNull);
    expect(restored.biologicalSex, isNull);
    expect(restored.voiceToneProfile, VoiceToneProfile.casual);
    expect(restored.importedFromHealth, isFalse);
  });

  test('UserProfile round-trip preserva campos novos', () {
    final profile = UserProfile(
      id: 'u1',
      name: 'Ana',
      updatedAt: DateTime(2026, 10, 2),
      birthDate: DateTime(1998, 5, 20),
      weightKg: 62.5,
      heightCm: 168,
      biologicalSex: 'female',
      voiceToneProfile: VoiceToneProfile.femaleAdult,
      importedFromHealth: true,
    );
    final restored = UserProfile.fromMap(profile.toMap());
    expect(restored.birthDate, DateTime(1998, 5, 20));
    expect(restored.weightKg, 62.5);
    expect(restored.heightCm, 168);
    expect(restored.biologicalSex, 'female');
    expect(restored.voiceToneProfile, VoiceToneProfile.femaleAdult);
    expect(restored.importedFromHealth, isTrue);
  });

  test('voiceToneProfile desconhecido cai no padrão casual', () {
    expect(VoiceToneProfile.fromMap('inexistente'), VoiceToneProfile.casual);
    expect(VoiceToneProfile.fromMap(null), VoiceToneProfile.casual);
    expect(VoiceToneProfile.fromMap('boyYouth'), VoiceToneProfile.boyYouth);
  });

  test('ageYears usa birthDate e considera aniversário no ano', () {
    final now = DateTime.now();
    final hadBirthday = UserProfile(
      id: 'u1',
      updatedAt: now,
      birthDate: DateTime(now.year - 30, 1, 1),
    );
    expect(hadBirthday.ageYears, 30);

    final notYet = UserProfile(
      id: 'u2',
      updatedAt: now,
      birthDate: DateTime(now.year - 30, 12, 31),
    );
    // Em 31/12 o aniversário do ano ainda não ocorreu (salvo no próprio dia).
    final expected = now.month == 12 && now.day == 31 ? 30 : 29;
    expect(notYet.ageYears, expected);

    final noBirth = UserProfile(id: 'u3', updatedAt: now);
    expect(noBirth.ageYears, isNull);
  });

  test('copyWith clears zeram campos opcionais', () {
    final profile = UserProfile(
      id: 'u1',
      name: 'Ana',
      updatedAt: DateTime(2026, 10, 2),
      birthDate: DateTime(1998, 5, 20),
      weightKg: 62.5,
      heightCm: 168,
      biologicalSex: 'female',
    );
    final cleared = profile.copyWith(
      clearBirthDate: true,
      clearWeightKg: true,
      clearHeightCm: true,
      clearBiologicalSex: true,
    );
    expect(cleared.birthDate, isNull);
    expect(cleared.weightKg, isNull);
    expect(cleared.heightCm, isNull);
    expect(cleared.biologicalSex, isNull);
    // Campos não marcados permanecem.
    expect(cleared.trimmedName, 'Ana');
  });

  test('applyDemographicsGaps preenche só os campos nulos', () {
    final profile = UserProfile(
      id: 'u1',
      updatedAt: DateTime(2026, 10, 2),
      weightKg: 60,
    );
    final filled = profile.applyDemographicsGaps(
      const ProfileDemographics(
        birthDate: null,
        weightKg: 99,
        heightCm: 170,
        biologicalSex: 'male',
      ),
    );
    expect(filled.weightKg, 60); // mantém valor já existente
    expect(filled.heightCm, 170); // preenche lacuna
    expect(filled.biologicalSex, 'male');
    expect(filled.importedFromHealth, isTrue);

    // Sem lacunas aplicáveis, retorna o mesmo objeto.
    final noop = filled.applyDemographicsGaps(const ProfileDemographics());
    expect(identical(noop, filled), isTrue);
  });

  test('profileDisplayName falls back when name is empty', () {
    final profile = UserProfile(
      id: 'u1',
      name: '  ',
      updatedAt: DateTime(2026, 10, 2),
    );
    expect(profileDisplayName(profile, 'Paciente'), 'Paciente');
  });

  test('UserProfileRepository persists name locally', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = UserProfileRepository(prefs);
    final saved = await repo.saveName('João');
    expect(saved.trimmedName, 'João');
    expect(repo.read().trimmedName, 'João');
  });

  test('repositório atualiza campos e preenche lacunas', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = UserProfileRepository(prefs);

    await repo.updateFields(
      name: 'João',
      heightCm: 180,
      voiceToneProfile: VoiceToneProfile.relaxed,
    );
    var stored = repo.read();
    expect(stored.heightCm, 180);
    expect(stored.voiceToneProfile, VoiceToneProfile.relaxed);

    await repo.applyDemographicsGaps(
      const ProfileDemographics(weightKg: 75, heightCm: 999),
    );
    stored = repo.read();
    expect(stored.weightKg, 75); // lacuna preenchida
    expect(stored.heightCm, 180); // valor existente mantido
    expect(stored.importedFromHealth, isTrue);
  });

  test('onboarding aparece só na primeira abertura sem dados', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(shouldShowFirstLaunchOnboarding(prefs), isTrue);
    await markOnboardingDone(prefs);
    expect(shouldShowFirstLaunchOnboarding(prefs), isFalse);
  });

  test('onboarding não aparece se já houver dados locais', () async {
    SharedPreferences.setMockInitialValues({
      'noa_mood_entries_v2': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(shouldShowFirstLaunchOnboarding(prefs), isFalse);
    expect(prefs.getBool(onboardingDoneKey), isTrue);
  });

  group('OnboardingProfileDraft', () {
    final emptyProfile = UserProfile(id: 'u1', updatedAt: DateTime(2026, 10, 6));

    test('sem Health exige todos os campos antes de concluir', () {
      final draft = OnboardingProfileDraft.fromProfile(emptyProfile);
      expect(draft.importedFromHealth, isFalse);
      expect(
        draft.requiredFromUser,
        equals(OnboardingProfileField.values.toSet()),
      );
      expect(draft.missingFields, equals(OnboardingProfileField.values.toSet()));
      expect(draft.isComplete, isFalse);
    });

    test('com Health preenche lacunas e só pede o que faltou', () {
      final draft = OnboardingProfileDraft.fromProfile(
        emptyProfile,
        demographics: ProfileDemographics(
          birthDate: DateTime(1998, 5, 20),
          biologicalSex: 'female',
        ),
      );
      expect(draft.importedFromHealth, isTrue);
      expect(
        draft.healthFilled,
        equals({
          OnboardingProfileField.birthDate,
          OnboardingProfileField.biologicalSex,
        }),
      );
      // Nome e tom de voz nunca vêm do Health; altura e peso faltaram.
      expect(
        draft.requiredFromUser,
        equals({
          OnboardingProfileField.name,
          OnboardingProfileField.voiceTone,
          OnboardingProfileField.heightCm,
          OnboardingProfileField.weightKg,
        }),
      );
      expect(draft.missingFields, equals(draft.requiredFromUser));
    });

    test('Health não sobrescreve o que a pessoa já tinha', () {
      final profile = emptyProfile.copyWith(heightCm: 180);
      final draft = OnboardingProfileDraft.fromProfile(
        profile,
        demographics: const ProfileDemographics(heightCm: 150, weightKg: 70),
      );
      expect(draft.heightCm, 180);
      expect(draft.weightKg, 70);
      expect(draft.healthFilled, equals({OnboardingProfileField.weightKg}));
    });

    test('rascunho completo vira perfil com importedFromHealth', () {
      final draft = OnboardingProfileDraft.fromProfile(
        emptyProfile,
        demographics: ProfileDemographics(
          birthDate: DateTime(1998, 5, 20),
          weightKg: 62.5,
          heightCm: 168,
          biologicalSex: 'female',
        ),
      ).copyWith(
        name: '  Ana ',
        voiceToneProfile: VoiceToneProfile.femaleAdult,
      );
      expect(draft.isComplete, isTrue);

      final profile = draft.applyTo(emptyProfile);
      expect(profile.id, 'u1');
      expect(profile.trimmedName, 'Ana');
      expect(profile.birthDate, DateTime(1998, 5, 20));
      expect(profile.weightKg, 62.5);
      expect(profile.heightCm, 168);
      expect(profile.biologicalSex, 'female');
      expect(profile.voiceToneProfile, VoiceToneProfile.femaleAdult);
      expect(profile.importedFromHealth, isTrue);
    });

    test('altura e peso fora da faixa seguram o botão de concluir', () {
      final base = OnboardingProfileDraft.fromProfile(emptyProfile).copyWith(
        name: 'Ana',
        birthDate: DateTime(1998, 5, 20),
        voiceToneProfile: VoiceToneProfile.casual,
        biologicalSex: 'female',
        heightCm: 1.68, // metros em vez de centímetros
        weightKg: 62,
      );
      expect(base.missingFields, equals({OnboardingProfileField.heightCm}));
      expect(base.copyWith(heightCm: 168).isComplete, isTrue);
      expect(
        base.copyWith(heightCm: 168, weightKg: 5).missingFields,
        equals({OnboardingProfileField.weightKg}),
      );
    });

    test('campo vazio não conta como inválido; fora da faixa conta', () {
      final base = OnboardingProfileDraft.fromProfile(emptyProfile);
      expect(base.hasInvalidMetrics, isFalse);
      expect(base.copyWith(heightCm: 168, weightKg: 62).hasInvalidMetrics,
          isFalse);
      expect(base.copyWith(heightCm: 1.68).hasInvalidMetrics, isTrue);
      expect(base.copyWith(weightKg: 62500).hasInvalidMetrics, isTrue);
      // Limpar o campo volta a ser branco, não erro.
      expect(
        base
            .copyWith(heightCm: 1.68)
            .copyWith(clearHeightCm: true)
            .hasInvalidMetrics,
        isFalse,
      );
    });

    test('parseMetric aceita vírgula e rejeita lixo', () {
      expect(OnboardingProfileDraft.parseMetric('62,5'), 62.5);
      expect(OnboardingProfileDraft.parseMetric(' 168 '), 168);
      expect(OnboardingProfileDraft.parseMetric(''), isNull);
      expect(OnboardingProfileDraft.parseMetric('abc'), isNull);
      expect(OnboardingProfileDraft.parseMetric(null), isNull);
    });
  });
}
