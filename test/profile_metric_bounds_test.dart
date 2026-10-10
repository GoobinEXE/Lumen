import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/onboarding/domain/onboarding_profile_draft.dart';
import 'package:noa/features/profile/domain/user_profile.dart';
import 'package:noa/features/profile/domain/voice_tone_profile.dart';

void main() {
  test('altura e peso incluem as bordas e excluem o milímetro de fora', () {
    expect(OnboardingProfileDraft.isValidHeight(50), isTrue);
    expect(OnboardingProfileDraft.isValidHeight(250), isTrue);
    expect(OnboardingProfileDraft.isValidHeight(49.9), isFalse);
    expect(OnboardingProfileDraft.isValidHeight(250.1), isFalse);
    expect(OnboardingProfileDraft.isValidWeight(15), isTrue);
    expect(OnboardingProfileDraft.isValidWeight(400), isTrue);
    expect(OnboardingProfileDraft.isValidWeight(14.9), isFalse);
    expect(OnboardingProfileDraft.isValidWeight(400.1), isFalse);

    expect(OnboardingProfileDraft.parseMetric('50,0'), 50);
    expect(OnboardingProfileDraft.parseMetric(' 15,5 '), 15.5);
    expect(OnboardingProfileDraft.parseMetric('1.2.3'), isNull);
    expect(OnboardingProfileDraft.parseMetric('15kg'), isNull);
  });

  test('nome só com espaço e sexo vazio seguram o concluir', () {
    final draft = OnboardingProfileDraft(
      name: '   ',
      birthDate: DateTime(1998, 5, 20),
      voiceToneProfile: VoiceToneProfile.casual,
      heightCm: 50,
      weightKg: 400,
      biologicalSex: '',
    );

    expect(
      draft.missingFields,
      equals({
        OnboardingProfileField.name,
        OnboardingProfileField.biologicalSex,
      }),
    );
    expect(draft.isComplete, isFalse);
    expect(draft.hasInvalidMetrics, isFalse);
  });

  test('o rascunho não herda o tom de voz já salvo', () {
    final profile = UserProfile(
      id: 'u1',
      name: '  Ana ',
      updatedAt: DateTime(2026, 10, 6),
      voiceToneProfile: VoiceToneProfile.formal,
      heightCm: 168,
      weightKg: 62,
      birthDate: DateTime(1998, 5, 20),
      biologicalSex: 'female',
    );

    final draft = OnboardingProfileDraft.fromProfile(profile);

    expect(draft.trimmedName, 'Ana');
    expect(draft.voiceToneProfile, isNull);
    expect(draft.missingFields, {OnboardingProfileField.voiceTone});
  });

  test('aplicar sem tom novo mantém o tom do perfil', () {
    final base = UserProfile(
      id: 'u1',
      updatedAt: DateTime(2026, 10, 6),
      voiceToneProfile: VoiceToneProfile.formal,
      importedFromHealth: true,
    );
    final draft = OnboardingProfileDraft(
      name: 'Ana',
      birthDate: DateTime(1998, 5, 20),
      heightCm: 168,
      weightKg: 62,
      biologicalSex: 'female',
    );

    final applied = draft.applyTo(base);

    expect(applied.voiceToneProfile, VoiceToneProfile.formal);
    expect(applied.trimmedName, 'Ana');
    expect(applied.importedFromHealth, isTrue);
    expect(applied.id, 'u1');
  });

  test('idade futura é nula e o aniversário de hoje conta', () {
    final now = DateTime.now();
    final future = UserProfile(
      id: 'u1',
      updatedAt: now,
      birthDate: DateTime(now.year + 1, now.month, now.day),
    );
    final today = UserProfile(
      id: 'u2',
      updatedAt: now,
      birthDate: DateTime(now.year - 25, now.month, now.day),
    );

    expect(future.ageYears, isNull);
    expect(today.ageYears, 25);
  });
}
