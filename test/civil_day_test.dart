import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/time/civil_day.dart';

void main() {
  test('chave civil ignora a hora e preenche mês e dia', () {
    final evening = DateTime(2026, 1, 5, 23, 59);
    final morning = DateTime(2026, 1, 5, 0, 1);

    expect(civilDayKey(evening), '2026-01-05');
    expect(civilDay(evening), DateTime(2026, 1, 5));
    expect(isSameCivilDay(evening, morning), isTrue);
    expect(isSameCivilDay(evening, DateTime(2026, 1, 6)), isFalse);
  });
}
