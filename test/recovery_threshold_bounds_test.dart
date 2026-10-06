import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/daily_environment_snapshot.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';

void main() {
  final day = DateTime(2026, 10, 1);

  test('HRV, passos, luz e ruído usam o corte exato', () {
    final below = DailyRecoverySnapshot(
      date: day,
      hrvMs: 39.99,
      steps: 3999,
      timeInDaylightMinutes: 19.99,
      avgEnvironmentalDb: 69.99,
      avgHeadphoneDb: 79.99,
    );
    expect(below.hasLowHrv, isTrue);
    expect(below.hasLowSteps, isTrue);
    expect(below.hasLowDaylight, isTrue);
    expect(below.hasHighNoise, isFalse);

    final atLimit = DailyRecoverySnapshot(
      date: day,
      hrvMs: 40,
      steps: 4000,
      timeInDaylightMinutes: 20,
      avgEnvironmentalDb: 70,
      avgHeadphoneDb: 80,
    );
    expect(atLimit.hasLowHrv, isFalse);
    expect(atLimit.hasLowSteps, isFalse);
    expect(atLimit.hasLowDaylight, isFalse);
    expect(atLimit.hasHighNoise, isTrue);

    final missing = DailyRecoverySnapshot(date: day);
    expect(missing.hasLowHrv, isFalse);
    expect(missing.hasLowSteps, isFalse);
    expect(missing.hasLowDaylight, isFalse);
    expect(missing.hasHighNoise, isFalse);
  });

  test('só o fone alto já marca ruído, e o mapa aceita número inteiro', () {
    final headphones = DailyRecoverySnapshot(
      date: day,
      avgEnvironmentalDb: 40,
      avgHeadphoneDb: 80,
    );
    expect(headphones.hasHighNoise, isTrue);

    final restored = DailyRecoverySnapshot.fromMap({
      'date': day.toIso8601String(),
      'hrvMs': 39,
      'steps': 1000,
      'timeInDaylightMinutes': 15,
    });
    expect(restored.hrvMs, 39);
    expect(restored.hasLowHrv, isTrue);
    expect(restored.hasLowDaylight, isTrue);
  });

  test('ambiente vazio não vira luz baixa nem ruído alto', () {
    final empty = DailyEnvironmentSnapshot(date: day);
    expect(empty.hasData, isFalse);
    expect(empty.hasLowDaylight, isFalse);
    expect(empty.hasHighEnvNoise, isFalse);
    expect(empty.hasHighHeadphoneNoise, isFalse);

    final bounds = DailyEnvironmentSnapshot(
      date: day,
      daylightMinutes: 20,
      envAudioDb: 70,
      headphoneAudioDb: 79.99,
    );
    expect(bounds.hasData, isTrue);
    expect(bounds.hasLowDaylight, isFalse);
    expect(bounds.hasHighEnvNoise, isTrue);
    expect(bounds.hasHighHeadphoneNoise, isFalse);

    final fromInts = DailyEnvironmentSnapshot.fromMap({
      'date': day.toIso8601String(),
      'daylightMinutes': 19,
      'headphoneAudioDb': 80,
    });
    expect(fromInts.hasLowDaylight, isTrue);
    expect(fromInts.hasHighHeadphoneNoise, isTrue);
    expect(fromInts.hasHighEnvNoise, isFalse);
  });
}
