import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/onboarding/domain/onboarding_profile_draft.dart';
import 'package:noa/features/profile/domain/profile_demographics.dart';
import 'package:noa/features/profile/domain/user_profile.dart';
import 'package:noa/features/profile/domain/voice_tone_profile.dart';

void main() {
  test('altura ou peso do Saúde fora da faixa segura o concluir', () {
    final profile = UserProfile(id: 'u1', updatedAt: DateTime(2026, 10, 6));
    final draft = OnboardingProfileDraft.fromProfile(
      profile,
      demographics: ProfileDemographics(
        birthDate: DateTime(1998, 5, 20),
        heightCm: 300,
        weightKg: 2,
        biologicalSex: 'female',
      ),
    ).copyWith(name: 'Ana', voiceToneProfile: VoiceToneProfile.casual);

    expect(
      draft.healthFilled,
      equals({
        OnboardingProfileField.birthDate,
        OnboardingProfileField.heightCm,
        OnboardingProfileField.weightKg,
        OnboardingProfileField.biologicalSex,
      }),
    );
    expect(
      draft.requiredFromUser.contains(OnboardingProfileField.heightCm),
      isFalse,
    );
    expect(
      draft.requiredFromUser.contains(OnboardingProfileField.weightKg),
      isFalse,
    );
    expect(
      draft.missingFields,
      equals({
        OnboardingProfileField.heightCm,
        OnboardingProfileField.weightKg,
      }),
    );
    expect(draft.hasInvalidMetrics, isTrue);
    expect(draft.isComplete, isFalse);

    final fixed = draft.copyWith(heightCm: 168, weightKg: 62);
    expect(fixed.hasInvalidMetrics, isFalse);
    expect(fixed.isComplete, isTrue);
    expect(fixed.applyTo(profile).heightCm, 168);
    expect(fixed.applyTo(profile).weightKg, 62);
  });
}
