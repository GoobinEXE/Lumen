/// Origem do cadastro do medicamento no Lumen.
enum MedicationSource { local, appleHealth, linked }

/// Representa um medicamento cadastrado pelo usuário
class Medication {
  final String id;
  final String name;
  final String dosage;

  /// Chave de ícone: capsule | tablet | liquid | drop
  final String shapeIcon;
  final List<String> scheduledTimes;
  final int totalStock;
  final int remainingStock;
  final int refillWarningThreshold;
  final int durationHours;
  final String instructions;
  final bool active;
  final List<int> daysOfWeek;

  /// Concept ID do medicamento no Apple Health (quando importado/vinculado).
  final String? appleConceptId;

  /// Código RxNorm quando disponível via Apple Health.
  final String? rxNormCode;
  final MedicationSource source;

  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    this.shapeIcon = 'capsule',
    required this.scheduledTimes,
    this.totalStock = 30,
    this.remainingStock = 30,
    this.refillWarningThreshold = 5,
    this.durationHours = 10,
    this.instructions = '',
    this.active = true,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.appleConceptId,
    this.rxNormCode,
    this.source = MedicationSource.local,
  });

  bool get needsRefillWarning => remainingStock <= refillWarningThreshold;
  bool get isLinkedToAppleHealth =>
      appleConceptId != null && appleConceptId!.isNotEmpty;

  /// Alias legado.
  String? get healthKitMedicationId => appleConceptId;

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? shapeIcon,
    List<String>? scheduledTimes,
    int? totalStock,
    int? remainingStock,
    int? refillWarningThreshold,
    int? durationHours,
    String? instructions,
    bool? active,
    List<int>? daysOfWeek,
    String? appleConceptId,
    String? rxNormCode,
    MedicationSource? source,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      shapeIcon: shapeIcon ?? this.shapeIcon,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      totalStock: totalStock ?? this.totalStock,
      remainingStock: remainingStock ?? this.remainingStock,
      refillWarningThreshold:
          refillWarningThreshold ?? this.refillWarningThreshold,
      durationHours: durationHours ?? this.durationHours,
      instructions: instructions ?? this.instructions,
      active: active ?? this.active,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      appleConceptId: appleConceptId ?? this.appleConceptId,
      rxNormCode: rxNormCode ?? this.rxNormCode,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'shapeIcon': shapeIcon,
      'scheduledTimes': scheduledTimes,
      'totalStock': totalStock,
      'remainingStock': remainingStock,
      'refillWarningThreshold': refillWarningThreshold,
      'durationHours': durationHours,
      'instructions': instructions,
      'active': active,
      'daysOfWeek': daysOfWeek,
      if (appleConceptId != null) 'appleConceptId': appleConceptId,
      // Compatibilidade com persistência antiga.
      if (appleConceptId != null) 'healthKitMedicationId': appleConceptId,
      if (rxNormCode != null) 'rxNormCode': rxNormCode,
      'source': source.name,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    final legacyEmoji = map['shapeEmoji'] as String?;
    String icon = map['shapeIcon'] as String? ?? 'capsule';
    if (legacyEmoji != null && map['shapeIcon'] == null) {
      if (legacyEmoji.contains('⚪') || legacyEmoji == 'tablet') {
        icon = 'tablet';
      } else if (legacyEmoji.contains('🧴') || legacyEmoji == 'liquid') {
        icon = 'liquid';
      } else if (legacyEmoji.contains('💧') || legacyEmoji == 'drop') {
        icon = 'drop';
      } else {
        icon = 'capsule';
      }
    }

    final concept =
        map['appleConceptId'] as String? ??
        map['healthKitMedicationId'] as String?;

    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      shapeIcon: icon,
      scheduledTimes: (map['scheduledTimes'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      totalStock: map['totalStock'] as int? ?? 30,
      remainingStock: map['remainingStock'] as int? ?? 30,
      refillWarningThreshold: map['refillWarningThreshold'] as int? ?? 5,
      durationHours: map['durationHours'] as int? ?? 10,
      instructions: map['instructions'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      daysOfWeek:
          (map['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      appleConceptId: concept,
      rxNormCode: map['rxNormCode'] as String?,
      source: MedicationSource.values.firstWhere(
        (s) => s.name == map['source'],
        orElse: () => concept != null && concept.isNotEmpty
            ? MedicationSource.appleHealth
            : MedicationSource.local,
      ),
    );
  }
}
