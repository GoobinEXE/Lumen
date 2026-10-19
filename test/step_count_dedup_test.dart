import 'package:flutter_test/flutter_test.dart';
import 'package:noa/integrations/health/models/step_count.dart';

void main() {
  final day = DateTime(2026, 10, 19);

  StepContribution sample({
    required String sourceKey,
    required double count,
    required int startHour,
    int startMinute = 0,
    int endHour = 23,
    int endMinute = 59,
  }) {
    return StepContribution(
      sourceKey: sourceKey,
      count: count,
      start: DateTime(day.year, day.month, day.day, startHour, startMinute),
      end: DateTime(day.year, day.month, day.day, endHour, endMinute),
    );
  }

  test('relógio e telefone no mesmo intervalo não dobram os passos', () {
    final total = dedupedStepCount([
      sample(sourceKey: 'watch', count: 8200, startHour: 0, endHour: 23),
      sample(sourceKey: 'phone', count: 4100, startHour: 0, endHour: 23),
    ]);

    expect(total, 8200);
  });

  test('trechos da mesma fonte continuam somando', () {
    final total = dedupedStepCount([
      sample(
        sourceKey: 'phone',
        count: 2000,
        startHour: 8,
        endHour: 12,
      ),
      sample(
        sourceKey: 'phone',
        count: 3000,
        startHour: 12,
        endHour: 18,
      ),
    ]);

    expect(total, 5000);
  });

  test('manhã no telefone e tarde no relógio somam', () {
    final total = dedupedStepCount([
      sample(
        sourceKey: 'phone',
        count: 3000,
        startHour: 8,
        endHour: 12,
      ),
      sample(
        sourceKey: 'watch',
        count: 3500,
        startHour: 13,
        endHour: 20,
      ),
    ]);

    expect(total, 6500);
  });

  test('dia parado continua abaixo do corte de poucos passos', () {
    final total = dedupedStepCount([
      sample(sourceKey: 'watch', count: 2500, startHour: 8, endHour: 22),
      sample(sourceKey: 'phone', count: 2400, startHour: 8, endHour: 22),
    ]);

    expect(total, 2500);
    expect(total! < 4000, isTrue);
  });

  test('amostra vazia ou inválida não inventa passos', () {
    expect(dedupedStepCount(const []), isNull);
    expect(
      dedupedStepCount([
        sample(sourceKey: 'phone', count: 0, startHour: 8, endHour: 9),
        sample(sourceKey: 'phone', count: -10, startHour: 10, endHour: 11),
      ]),
      isNull,
    );
  });
}
