import 'models/daily_environment_snapshot.dart';
import 'models/daily_recovery_snapshot.dart';

/// Cruza luz e áudio do HealthKit no snapshot de recuperação do mesmo dia civil.
///
/// O dia que só tem ambiente entra na lista. Campo ausente no ambiente não
/// apaga HRV, passos ou um valor que a recuperação já tinha.
List<DailyRecoverySnapshot> mergeEnvironmentIntoRecovery(
  List<DailyRecoverySnapshot> base,
  List<DailyEnvironmentSnapshot> environment,
) {
  if (environment.isEmpty) return base;

  String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  final byKey = {for (final s in base) dayKey(s.date): s};

  for (final reading in environment) {
    final key = dayKey(reading.date);
    final existing = byKey[key];
    byKey[key] = (existing ?? DailyRecoverySnapshot(date: reading.date))
        .copyWith(
          timeInDaylightMinutes: reading.daylightMinutes,
          avgEnvironmentalDb: reading.envAudioDb,
          avgHeadphoneDb: reading.headphoneAudioDb,
        );
  }

  final merged = byKey.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return merged;
}
