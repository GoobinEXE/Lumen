import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/environment_recovery_merge.dart';
import 'package:noa/integrations/health/models/daily_environment_snapshot.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';

void main() {
  test('ambiente vazio devolve a recuperação como está', () {
    final base = [
      DailyRecoverySnapshot(date: DateTime(2026, 10, 5), hrvMs: 42),
    ];

    expect(mergeEnvironmentIntoRecovery(base, const []), same(base));
  });

  test('mesmo dia civil guarda HRV e recebe luz e ruído', () {
    final recovery = DailyRecoverySnapshot(
      date: DateTime(2026, 10, 5),
      hrvMs: 48,
      steps: 6200,
      timeInDaylightMinutes: 40,
    );
    final merged = mergeEnvironmentIntoRecovery(
      [recovery],
      [
        DailyEnvironmentSnapshot(
          date: DateTime(2026, 10, 5, 15, 30),
          daylightMinutes: 18,
          envAudioDb: 71,
        ),
      ],
    );

    expect(merged, hasLength(1));
    expect(merged.single.date, DateTime(2026, 10, 5));
    expect(merged.single.hrvMs, 48);
    expect(merged.single.steps, 6200);
    expect(merged.single.timeInDaylightMinutes, 18);
    expect(merged.single.avgEnvironmentalDb, 71);
    expect(merged.single.avgHeadphoneDb, isNull);
  });

  test('campo ausente no ambiente não apaga o que a recuperação já tinha', () {
    final merged = mergeEnvironmentIntoRecovery(
      [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 5),
          hrvMs: 48,
          timeInDaylightMinutes: 40,
          avgHeadphoneDb: 82,
        ),
      ],
      [
        DailyEnvironmentSnapshot(
          date: DateTime(2026, 10, 5),
          envAudioDb: 65,
        ),
      ],
    );

    expect(merged.single.hrvMs, 48);
    expect(merged.single.timeInDaylightMinutes, 40);
    expect(merged.single.avgHeadphoneDb, 82);
    expect(merged.single.avgEnvironmentalDb, 65);
  });

  test('dia só de ambiente entra, e o mais novo vem primeiro', () {
    final merged = mergeEnvironmentIntoRecovery(
      [
        DailyRecoverySnapshot(date: DateTime(2026, 10, 5), hrvMs: 50),
      ],
      [
        DailyEnvironmentSnapshot(
          date: DateTime(2026, 10, 6),
          daylightMinutes: 12,
          headphoneAudioDb: 80,
        ),
        DailyEnvironmentSnapshot(
          date: DateTime(2026, 10, 15),
          daylightMinutes: 30,
        ),
      ],
    );

    expect(merged.map((s) => s.date), [
      DateTime(2026, 10, 15),
      DateTime(2026, 10, 6),
      DateTime(2026, 10, 5),
    ]);
    expect(merged[1].hrvMs, isNull);
    expect(merged[1].timeInDaylightMinutes, 12);
    expect(merged[1].avgHeadphoneDb, 80);
    expect(merged.last.hrvMs, 50);
    expect(merged.last.timeInDaylightMinutes, isNull);
  });
}
