import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/health_sync/data/health_sync_prefs.dart';

void main() {
  test('respiração em japonês entra e hábito comum fica de fora', () {
    expect(isBreathingMindfulnessHabit('深呼吸'), isTrue);
    expect(isBreathingMindfulnessHabit('ストレッチ'), isTrue);
    expect(isBreathingMindfulnessHabit('Alongar os ombros'), isTrue);
    expect(isBreathingMindfulnessHabit('água'), isFalse);
    expect(isBreathingMindfulnessHabit('caminhar'), isFalse);
  });
}
