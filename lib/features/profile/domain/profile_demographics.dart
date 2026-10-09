/// Dados demográficos vindos de uma fonte externa (ex.: Health) para preencher
/// lacunas do [UserProfile]. Campo nulo é dado ausente, nunca um palpite.
class ProfileDemographics {
  const ProfileDemographics({
    this.birthDate,
    this.weightKg,
    this.heightCm,
    this.biologicalSex,
  });

  final DateTime? birthDate;
  final double? weightKg;
  final double? heightCm;
  final String? biologicalSex;

  bool get isEmpty =>
      birthDate == null &&
      weightKg == null &&
      heightCm == null &&
      biologicalSex == null;

  factory ProfileDemographics.fromMap(Map<String, dynamic> map) {
    return ProfileDemographics(
      birthDate: DateTime.tryParse(map['birthDate'] as String? ?? ''),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      biologicalSex: map['biologicalSex'] as String?,
    );
  }
}
