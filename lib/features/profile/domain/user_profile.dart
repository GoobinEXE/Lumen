import 'profile_demographics.dart';
import 'voice_tone_profile.dart';

/// Perfil local e opcional da pessoa (GDD §6/§7). Tudo fica no aparelho.
class UserProfile {
  const UserProfile({
    required this.id,
    this.name,
    required this.updatedAt,
    this.birthDate,
    this.weightKg,
    this.heightCm,
    this.biologicalSex,
    this.voiceToneProfile = VoiceToneProfile.casual,
    this.importedFromHealth = false,
  });

  final String id;
  final String? name;
  final DateTime updatedAt;
  final DateTime? birthDate;
  final double? weightKg;
  final double? heightCm;
  final String? biologicalSex;
  final VoiceToneProfile voiceToneProfile;
  final bool importedFromHealth;

  String? get trimmedName {
    final value = name?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Idade em anos cheios a partir de [birthDate], se presente.
  int? get ageYears {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var age = now.year - birth.year;
    final hadBirthday = now.month > birth.month ||
        (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) age -= 1;
    return age < 0 ? null : age;
  }

  UserProfile copyWith({
    String? id,
    String? name,
    DateTime? updatedAt,
    DateTime? birthDate,
    double? weightKg,
    double? heightCm,
    String? biologicalSex,
    VoiceToneProfile? voiceToneProfile,
    bool? importedFromHealth,
    bool clearName = false,
    bool clearBirthDate = false,
    bool clearWeightKg = false,
    bool clearHeightCm = false,
    bool clearBiologicalSex = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      updatedAt: updatedAt ?? this.updatedAt,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      weightKg: clearWeightKg ? null : (weightKg ?? this.weightKg),
      heightCm: clearHeightCm ? null : (heightCm ?? this.heightCm),
      biologicalSex:
          clearBiologicalSex ? null : (biologicalSex ?? this.biologicalSex),
      voiceToneProfile: voiceToneProfile ?? this.voiceToneProfile,
      importedFromHealth: importedFromHealth ?? this.importedFromHealth,
    );
  }

  /// Preenche apenas os campos ainda nulos a partir de [demographics].
  /// Marca [importedFromHealth] quando algum dado foi efetivamente aplicado.
  UserProfile applyDemographicsGaps(ProfileDemographics demographics) {
    final nextBirthDate = birthDate ?? demographics.birthDate;
    final nextWeight = weightKg ?? demographics.weightKg;
    final nextHeight = heightCm ?? demographics.heightCm;
    final nextSex = biologicalSex ?? demographics.biologicalSex;

    final changed = (birthDate == null && nextBirthDate != null) ||
        (weightKg == null && nextWeight != null) ||
        (heightCm == null && nextHeight != null) ||
        (biologicalSex == null && nextSex != null);

    if (!changed) return this;

    return copyWith(
      birthDate: nextBirthDate,
      weightKg: nextWeight,
      heightCm: nextHeight,
      biologicalSex: nextSex,
      importedFromHealth: true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'updatedAt': updatedAt.toIso8601String(),
        'birthDate': birthDate?.toIso8601String(),
        'weightKg': weightKg,
        'heightCm': heightCm,
        'biologicalSex': biologicalSex,
        'voiceToneProfile': voiceToneProfile.toMap(),
        'importedFromHealth': importedFromHealth,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String?,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      birthDate: DateTime.tryParse(map['birthDate'] as String? ?? ''),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      biologicalSex: map['biologicalSex'] as String?,
      voiceToneProfile: VoiceToneProfile.fromMap(map['voiceToneProfile']),
      importedFromHealth: map['importedFromHealth'] as bool? ?? false,
    );
  }
}
