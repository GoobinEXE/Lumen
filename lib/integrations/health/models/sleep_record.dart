/// Representa uma sessão de sono consolidada (normalmente da noite anterior)
/// lida a partir do Apple Health (HealthKit) ou Health Connect.
class SleepRecord {
  final DateTime date; // Data de referência (dia em que o usuário acordou)
  final DateTime bedtime;
  final DateTime wakeTime;
  final Duration totalSleep;
  final Duration deepSleep;
  final Duration remSleep;
  final Duration lightSleep;
  final Duration awakeDuration;
  final int? averageHeartRate; // Batimentos médios em repouso durante a noite

  const SleepRecord({
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    required this.totalSleep,
    this.deepSleep = Duration.zero,
    this.remSleep = Duration.zero,
    this.lightSleep = Duration.zero,
    this.awakeDuration = Duration.zero,
    this.averageHeartRate,
  });

  /// Retorna o total de horas de sono como número decimal (ex: 7.5h)
  double get totalHours => totalSleep.inMinutes / 60.0;

  /// Retorna as horas de sono REM como decimal
  double get remHours => remSleep.inMinutes / 60.0;

  /// Retorna as horas de sono profundo como decimal
  double get deepHours => deepSleep.inMinutes / 60.0;

  /// Indica se houve déficit severo de sono (abaixo de 6 horas)
  bool get hasSleepDeficit => totalHours < 6.0;

  /// Indica se houve déficit de sono REM (< 1h15m / 75 min).
  /// O sono REM é fundamental para regulação emocional e dopamina no TDAH.
  bool get hasRemDeficit => remSleep.inMinutes < 75;

  /// Calcula uma pontuação de qualidade de sono baseada em duração e estágios (0 a 100)
  int get qualityScore {
    double score = 50;

    // Duração ideal (entre 7h e 9h)
    if (totalHours >= 7.0 && totalHours <= 9.0) {
      score += 30;
    } else if (totalHours >= 6.0) {
      score += 15;
    } else {
      score -= 20;
    }

    // Proporção de sono profundo + REM (restauração mental e física)
    final restorativeMinutes = deepSleep.inMinutes + remSleep.inMinutes;
    if (restorativeMinutes >= 150) {
      score += 20;
    } else if (restorativeMinutes >= 100) {
      score += 10;
    }

    return score.clamp(10, 100).toInt();
  }

  /// Formatação legível de duração (ex: "7h 25m")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'bedtime': bedtime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'totalSleepMinutes': totalSleep.inMinutes,
      'deepSleepMinutes': deepSleep.inMinutes,
      'remSleepMinutes': remSleep.inMinutes,
      'lightSleepMinutes': lightSleep.inMinutes,
      'awakeMinutes': awakeDuration.inMinutes,
      'averageHeartRate': averageHeartRate,
    };
  }

  factory SleepRecord.fromMap(Map<String, dynamic> map) {
    return SleepRecord(
      date: DateTime.parse(map['date'] as String),
      bedtime: DateTime.parse(map['bedtime'] as String),
      wakeTime: DateTime.parse(map['wakeTime'] as String),
      totalSleep: Duration(minutes: map['totalSleepMinutes'] as int? ?? 0),
      deepSleep: Duration(minutes: map['deepSleepMinutes'] as int? ?? 0),
      remSleep: Duration(minutes: map['remSleepMinutes'] as int? ?? 0),
      lightSleep: Duration(minutes: map['lightSleepMinutes'] as int? ?? 0),
      awakeDuration: Duration(minutes: map['awakeMinutes'] as int? ?? 0),
      averageHeartRate: map['averageHeartRate'] as int?,
    );
  }
}
