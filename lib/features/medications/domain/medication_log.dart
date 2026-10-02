enum MedicationLogSource { lumen, appleHealth }

/// Registro de dose tomada, adiada ou pulada
class MedicationLog {
  final String id;
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime;
  final DateTime? takenAt;
  final bool skipped;
  final String? skipReason;
  final DateTime? snoozedUntil;
  final MedicationLogSource source;

  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.takenAt,
    this.skipped = false,
    this.skipReason,
    this.snoozedUntil,
    this.source = MedicationLogSource.lumen,
  });

  bool get isTaken => takenAt != null;
  bool get isSnoozed =>
      snoozedUntil != null && snoozedUntil!.isAfter(DateTime.now());
  bool get isPending => !isTaken && !skipped && !isSnoozed;

  MedicationLog copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledTime,
    DateTime? takenAt,
    bool? skipped,
    String? skipReason,
    DateTime? snoozedUntil,
    MedicationLogSource? source,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenAt: takenAt ?? this.takenAt,
      skipped: skipped ?? this.skipped,
      skipReason: skipReason ?? this.skipReason,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenAt': takenAt?.toIso8601String(),
      'skipped': skipped,
      'skipReason': skipReason,
      'snoozedUntil': snoozedUntil?.toIso8601String(),
      'source': source.name,
    };
  }

  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] as String,
      medicationId: map['medicationId'] as String,
      medicationName: map['medicationName'] as String,
      scheduledTime: DateTime.parse(map['scheduledTime'] as String),
      takenAt: map['takenAt'] != null
          ? DateTime.parse(map['takenAt'] as String)
          : null,
      skipped: map['skipped'] as bool? ?? false,
      skipReason: map['skipReason'] as String?,
      snoozedUntil: map['snoozedUntil'] != null
          ? DateTime.parse(map['snoozedUntil'] as String)
          : null,
      source: MedicationLogSource.values.firstWhere(
        (s) => s.name == map['source'],
        orElse: () => MedicationLogSource.lumen,
      ),
    );
  }
}
