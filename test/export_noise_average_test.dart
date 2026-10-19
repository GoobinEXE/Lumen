import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/therapist_export/domain/period_export_stats.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';

void main() {
  test('ruído do fone não entra na média e 0 dB do ambiente entra', () {
    final stats = PeriodExportStats.from(
      sleepRecords: const [],
      moodEntries: const [],
      recoverySnapshots: [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 6),
          avgEnvironmentalDb: 70,
          avgHeadphoneDb: 90,
        ),
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 7),
          avgHeadphoneDb: 85,
        ),
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 8),
          avgEnvironmentalDb: 0,
        ),
      ],
    );

    expect(stats.avgNoiseDb, 35);
    expect(stats.avgHrv, isNull);
  });

  test('só fone deixa a média de ruído vazia', () {
    final stats = PeriodExportStats.from(
      sleepRecords: const [],
      moodEntries: const [],
      recoverySnapshots: [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 8),
          avgHeadphoneDb: 88,
        ),
      ],
    );

    expect(stats.avgNoiseDb, isNull);
    expect(stats.sleepNights, 0);
    expect(stats.avgSleepHours, 0);
  });
}
