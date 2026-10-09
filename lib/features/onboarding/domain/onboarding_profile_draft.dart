import '../../profile/domain/profile_demographics.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/domain/voice_tone_profile.dart';

/// Campos do formulário de perfil da primeira abertura.
enum OnboardingProfileField {
  name,
  birthDate,
  voiceTone,
  heightCm,
  weightKg,
  biologicalSex,
}

/// Rascunho do perfil preenchido no wizard. Não persiste nada: o valor só
/// vira [UserProfile] quando a pessoa conclui o fluxo.
class OnboardingProfileDraft {
  const OnboardingProfileDraft({
    this.name,
    this.birthDate,
    this.voiceToneProfile,
    this.heightCm,
    this.weightKg,
    this.biologicalSex,
    this.healthFilled = const {},
  });

  /// Limites de sanidade para evitar digitação trocada (m x cm, g x kg).
  static const double minHeightCm = 50;
  static const double maxHeightCm = 250;
  static const double minWeightKg = 15;
  static const double maxWeightKg = 400;

  /// Campos que o app de saúde nunca entrega; sempre pedidos à pessoa.
  static const Set<OnboardingProfileField> alwaysRequired = {
    OnboardingProfileField.name,
    OnboardingProfileField.voiceTone,
  };

  final String? name;
  final DateTime? birthDate;
  final VoiceToneProfile? voiceToneProfile;
  final double? heightCm;
  final double? weightKg;
  final String? biologicalSex;

  /// Campos que vieram preenchidos do app de saúde.
  final Set<OnboardingProfileField> healthFilled;

  /// Rascunho a partir do perfil atual (normalmente vazio na 1ª abertura),
  /// com as lacunas cobertas pelos dados do app de saúde quando houver.
  factory OnboardingProfileDraft.fromProfile(
    UserProfile profile, {
    ProfileDemographics? demographics,
  }) {
    final filled = <OnboardingProfileField>{};
    var birthDate = profile.birthDate;
    var heightCm = profile.heightCm;
    var weightKg = profile.weightKg;
    var biologicalSex = profile.biologicalSex;

    if (demographics != null) {
      if (birthDate == null && demographics.birthDate != null) {
        birthDate = demographics.birthDate;
        filled.add(OnboardingProfileField.birthDate);
      }
      if (heightCm == null && demographics.heightCm != null) {
        heightCm = demographics.heightCm;
        filled.add(OnboardingProfileField.heightCm);
      }
      if (weightKg == null && demographics.weightKg != null) {
        weightKg = demographics.weightKg;
        filled.add(OnboardingProfileField.weightKg);
      }
      if (biologicalSex == null && demographics.biologicalSex != null) {
        biologicalSex = demographics.biologicalSex;
        filled.add(OnboardingProfileField.biologicalSex);
      }
    }

    return OnboardingProfileDraft(
      name: profile.trimmedName,
      birthDate: birthDate,
      // Tom de voz é escolha ativa da pessoa; o padrão do modelo não conta.
      voiceToneProfile: null,
      heightCm: heightCm,
      weightKg: weightKg,
      biologicalSex: biologicalSex,
      healthFilled: filled,
    );
  }

  String? get trimmedName {
    final value = name?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool get importedFromHealth => healthFilled.isNotEmpty;

  /// O que a pessoa precisa preencher à mão: tudo, menos o que o app de
  /// saúde já cobriu. Nome e tom de voz entram sempre.
  Set<OnboardingProfileField> get requiredFromUser {
    return OnboardingProfileField.values
        .where(
          (field) =>
              alwaysRequired.contains(field) || !healthFilled.contains(field),
        )
        .toSet();
  }

  /// Campos ainda vazios ou fora da faixa; vazio libera o botão de concluir.
  Set<OnboardingProfileField> get missingFields {
    final missing = <OnboardingProfileField>{};
    if (trimmedName == null) missing.add(OnboardingProfileField.name);
    if (birthDate == null) missing.add(OnboardingProfileField.birthDate);
    if (voiceToneProfile == null) missing.add(OnboardingProfileField.voiceTone);
    if (!isValidHeight(heightCm)) missing.add(OnboardingProfileField.heightCm);
    if (!isValidWeight(weightKg)) missing.add(OnboardingProfileField.weightKg);
    if (biologicalSex == null || biologicalSex!.isEmpty) {
      missing.add(OnboardingProfileField.biologicalSex);
    }
    return missing;
  }

  bool get isComplete => missingFields.isEmpty;

  /// Altura ou peso digitados fora da faixa. Diferente de [missingFields]:
  /// campo vazio não é inválido, só está em branco.
  bool get hasInvalidMetrics =>
      (heightCm != null && !isValidHeight(heightCm)) ||
      (weightKg != null && !isValidWeight(weightKg));

  static bool isValidHeight(double? value) =>
      value != null && value >= minHeightCm && value <= maxHeightCm;

  static bool isValidWeight(double? value) =>
      value != null && value >= minWeightKg && value <= maxWeightKg;

  /// Aceita vírgula ou ponto como separador decimal; vazio ou lixo vira nulo.
  static double? parseMetric(String? raw) {
    final text = raw?.trim().replaceAll(',', '.');
    if (text == null || text.isEmpty) return null;
    return double.tryParse(text);
  }

  OnboardingProfileDraft copyWith({
    String? name,
    DateTime? birthDate,
    VoiceToneProfile? voiceToneProfile,
    double? heightCm,
    double? weightKg,
    String? biologicalSex,
    Set<OnboardingProfileField>? healthFilled,
    bool clearHeightCm = false,
    bool clearWeightKg = false,
  }) {
    return OnboardingProfileDraft(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      voiceToneProfile: voiceToneProfile ?? this.voiceToneProfile,
      heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
      weightKg: clearWeightKg ? null : (weightKg ?? this.weightKg),
      biologicalSex: biologicalSex ?? this.biologicalSex,
      healthFilled: healthFilled ?? this.healthFilled,
    );
  }

  /// Aplica o rascunho sobre [base], mantendo id e o que o wizard não toca.
  /// Só chame com [isComplete] verdadeiro.
  UserProfile applyTo(UserProfile base) {
    return base.copyWith(
      name: trimmedName,
      birthDate: birthDate,
      heightCm: heightCm,
      weightKg: weightKg,
      biologicalSex: biologicalSex,
      voiceToneProfile: voiceToneProfile ?? base.voiceToneProfile,
      importedFromHealth: base.importedFromHealth || importedFromHealth,
    );
  }
}
