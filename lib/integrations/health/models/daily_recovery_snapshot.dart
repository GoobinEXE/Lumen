/// Snapshot diário de recuperação / atividade (Apple Health / Health Connect).
class DailyRecoverySnapshot {
  final DateTime date;
  final double? hrvMs;
  final double? restingHeartRate;
  final int? steps;
  final double? exerciseMinutes;

  /// Minutos sob luz do dia (Apple Watch / iOS).
  final double? timeInDaylightMinutes;

  /// Média de exposição sonora ambiental (dB).
  final double? avgEnvironmentalDb;

  /// Média de exposição sonora de fones (dB).
  final double? avgHeadphoneDb;

  const DailyRecoverySnapshot({
    required this.date,
    this.hrvMs,
    this.restingHeartRate,
    this.steps,
    this.exerciseMinutes,
    this.timeInDaylightMinutes,
    this.avgEnvironmentalDb,
    this.avgHeadphoneDb,
  });

  bool get hasLowHrv => hrvMs != null && hrvMs! < 40;
  bool get hasLowSteps => steps != null && steps! < 4000;
  bool get hasLowDaylight =>
      timeInDaylightMinutes != null && timeInDaylightMinutes! < 20;
  bool get hasHighNoise =>
      (avgEnvironmentalDb != null && avgEnvironmentalDb! >= 70) ||
      (avgHeadphoneDb != null && avgHeadphoneDb! >= 80);

  DailyRecoverySnapshot copyWith({
    DateTime? date,
    double? hrvMs,
    double? restingHeartRate,
    int? steps,
    double? exerciseMinutes,
    double? timeInDaylightMinutes,
    double? avgEnvironmentalDb,
    double? avgHeadphoneDb,
  }) {
    return DailyRecoverySnapshot(
      date: date ?? this.date,
      hrvMs: hrvMs ?? this.hrvMs,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      steps: steps ?? this.steps,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      timeInDaylightMinutes:
          timeInDaylightMinutes ?? this.timeInDaylightMinutes,
      avgEnvironmentalDb: avgEnvironmentalDb ?? this.avgEnvironmentalDb,
      avgHeadphoneDb: avgHeadphoneDb ?? this.avgHeadphoneDb,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'hrvMs': hrvMs,
      'restingHeartRate': restingHeartRate,
      'steps': steps,
      'exerciseMinutes': exerciseMinutes,
      'timeInDaylightMinutes': timeInDaylightMinutes,
      'avgEnvironmentalDb': avgEnvironmentalDb,
      'avgHeadphoneDb': avgHeadphoneDb,
    };
  }

  factory DailyRecoverySnapshot.fromMap(Map<String, dynamic> map) {
    return DailyRecoverySnapshot(
      date: DateTime.parse(map['date'] as String),
      hrvMs: (map['hrvMs'] as num?)?.toDouble(),
      restingHeartRate: (map['restingHeartRate'] as num?)?.toDouble(),
      steps: map['steps'] as int?,
      exerciseMinutes: (map['exerciseMinutes'] as num?)?.toDouble(),
      timeInDaylightMinutes: (map['timeInDaylightMinutes'] as num?)?.toDouble(),
      avgEnvironmentalDb: (map['avgEnvironmentalDb'] as num?)?.toDouble(),
      avgHeadphoneDb: (map['avgHeadphoneDb'] as num?)?.toDouble(),
    );
  }
}
