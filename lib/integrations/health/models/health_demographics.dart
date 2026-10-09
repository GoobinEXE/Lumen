/// Sexo biológico lido do Health, em códigos estáveis para o app.
enum HealthBiologicalSex {
  male('male'),
  female('female'),
  other('other');

  const HealthBiologicalSex(this.code);

  final String code;

  static HealthBiologicalSex? fromCode(String? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Dados demográficos lidos do HealthKit / Health Connect.
/// Campo ausente significa sem permissão ou sem registro: nunca é inventado.
class HealthDemographics {
  const HealthDemographics({
    this.birthDate,
    this.weightKg,
    this.heightCm,
    this.biologicalSex,
  });

  static const HealthDemographics empty = HealthDemographics();

  final DateTime? birthDate;
  final double? weightKg;
  final double? heightCm;
  final HealthBiologicalSex? biologicalSex;

  bool get isEmpty =>
      birthDate == null &&
      weightKg == null &&
      heightCm == null &&
      biologicalSex == null;

  /// `HKBiologicalSex`: 0 notSet, 1 female, 2 male, 3 other.
  /// Também cobre o 0 que o plugin devolve quando o valor nativo veio nulo.
  static HealthBiologicalSex? sexFromHealthKitRawValue(num? raw) {
    switch (raw?.toInt()) {
      case 1:
        return HealthBiologicalSex.female;
      case 2:
        return HealthBiologicalSex.male;
      case 3:
        return HealthBiologicalSex.other;
      default:
        return null;
    }
  }

  /// O HealthKit entrega a data de nascimento como `timeIntervalSince1970`.
  /// Zero ou negativo é o placeholder de valor ausente, não 1970.
  static DateTime? birthDateFromEpochSeconds(num? seconds) {
    final value = seconds?.toDouble();
    if (value == null || value <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
  }

  /// Converte a altura para centímetros a partir do nome da `HealthDataUnit`.
  static double? heightToCm(num? value, String unitName) {
    final raw = value?.toDouble();
    if (raw == null || raw <= 0) return null;
    final factor = switch (unitName) {
      'CENTIMETER' => 1.0,
      'METER' => 100.0,
      'INCH' => 2.54,
      'FOOT' => 30.48,
      'YARD' => 91.44,
      _ => null,
    };
    if (factor == null) return null;
    return raw * factor;
  }

  /// Converte o peso para quilos a partir do nome da `HealthDataUnit`.
  static double? weightToKg(num? value, String unitName) {
    final raw = value?.toDouble();
    if (raw == null || raw <= 0) return null;
    final factor = switch (unitName) {
      'KILOGRAM' => 1.0,
      'GRAM' => 0.001,
      'POUND' => 0.45359237,
      'OUNCE' => 0.028349523125,
      'STONE' => 6.35029318,
      _ => null,
    };
    if (factor == null) return null;
    return raw * factor;
  }

  HealthDemographics copyWith({
    DateTime? birthDate,
    double? weightKg,
    double? heightCm,
    HealthBiologicalSex? biologicalSex,
  }) {
    return HealthDemographics(
      birthDate: birthDate ?? this.birthDate,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      biologicalSex: biologicalSex ?? this.biologicalSex,
    );
  }

  Map<String, dynamic> toMap() => {
    'birthDate': birthDate?.toIso8601String(),
    'weightKg': weightKg,
    'heightCm': heightCm,
    'biologicalSex': biologicalSex?.code,
  };

  factory HealthDemographics.fromMap(Map<String, dynamic> map) {
    return HealthDemographics(
      birthDate: DateTime.tryParse(map['birthDate'] as String? ?? ''),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      biologicalSex: HealthBiologicalSex.fromCode(
        map['biologicalSex'] as String?,
      ),
    );
  }
}
