import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';

void main() {
  test('passos decimais não apagam o outro dia', () {
    final raw = [
      {'date': '2026-10-08T00:00:00.000', 'steps': 1200},
      {'date': '2026-10-09T00:00:00.000', 'steps': 3999.6, 'hrvMs': 55},
      {'date': '2026-10-10T00:00:00.000', 'steps': 3999.4},
    ];

    final snaps = [
      for (final item in raw)
        DailyRecoverySnapshot.fromMap(Map<String, dynamic>.from(item)),
    ];

    expect(snaps, hasLength(3));
    expect(snaps[0].steps, 1200);
    expect(snaps[0].hasLowSteps, isTrue);
    expect(snaps[1].steps, 4000);
    expect(snaps[1].hasLowSteps, isFalse);
    expect(snaps[1].hrvMs, 55);
    expect(snaps[2].steps, 3999);
    expect(snaps[2].hasLowSteps, isTrue);
  });

  test('zero em decimal continua zero e passo ausente não vira zero', () {
    final zero = DailyRecoverySnapshot.fromMap({
      'date': '2026-10-08T00:00:00.000',
      'steps': 0.0,
    });
    expect(zero.steps, 0);
    expect(zero.hasLowSteps, isTrue);

    final missing = DailyRecoverySnapshot.fromMap({
      'date': '2026-10-08T00:00:00.000',
    });
    expect(missing.steps, isNull);
    expect(missing.hasLowSteps, isFalse);
  });
}
