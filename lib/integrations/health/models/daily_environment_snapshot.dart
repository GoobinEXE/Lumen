/// Snapshot diário de ambiente (luz do dia + exposição sonora).
/// Disponível via bridge HealthKit nativo (iOS); vazio no Android.
class DailyEnvironmentSnapshot {
  final DateTime date;
  final double? daylightMinutes;
  final double? envAudioDb;
  final double? headphoneAudioDb;

  const DailyEnvironmentSnapshot({
    required this.date,
    this.daylightMinutes,
    this.envAudioDb,
    this.headphoneAudioDb,
  });

  bool get hasLowDaylight => daylightMinutes != null && daylightMinutes! < 20;
  bool get hasHighEnvNoise => envAudioDb != null && envAudioDb! >= 70;
  bool get hasHighHeadphoneNoise =>
      headphoneAudioDb != null && headphoneAudioDb! >= 80;
  bool get hasData =>
      daylightMinutes != null || envAudioDb != null || headphoneAudioDb != null;

  DailyEnvironmentSnapshot copyWith({
    DateTime? date,
    double? daylightMinutes,
    double? envAudioDb,
    double? headphoneAudioDb,
  }) {
    return DailyEnvironmentSnapshot(
      date: date ?? this.date,
      daylightMinutes: daylightMinutes ?? this.daylightMinutes,
      envAudioDb: envAudioDb ?? this.envAudioDb,
      headphoneAudioDb: headphoneAudioDb ?? this.headphoneAudioDb,
    );
  }

  Map<String, dynamic> toMap() => {
    'date': date.toIso8601String(),
    'daylightMinutes': daylightMinutes,
    'envAudioDb': envAudioDb,
    'headphoneAudioDb': headphoneAudioDb,
  };

  factory DailyEnvironmentSnapshot.fromMap(Map<String, dynamic> map) {
    return DailyEnvironmentSnapshot(
      date: DateTime.parse(map['date'] as String),
      daylightMinutes: (map['daylightMinutes'] as num?)?.toDouble(),
      envAudioDb: (map['envAudioDb'] as num?)?.toDouble(),
      headphoneAudioDb: (map['headphoneAudioDb'] as num?)?.toDouble(),
    );
  }
}
