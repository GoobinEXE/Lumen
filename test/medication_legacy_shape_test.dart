import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/medication.dart';

void main() {
  Map<String, dynamic> legacy(String emoji) {
    return {
      'id': 'm-1',
      'name': 'Venvanse',
      'dosage': '30mg',
      'shapeEmoji': emoji,
      'scheduledTimes': ['08:00'],
    };
  }

  test('emoji antigo vira o ícone e o ícone novo prevalece', () {
    expect(Medication.fromMap(legacy('💧')).shapeIcon, 'drop');
    expect(Medication.fromMap(legacy('🧴')).shapeIcon, 'liquid');
    expect(Medication.fromMap(legacy('⚪')).shapeIcon, 'tablet');
    expect(Medication.fromMap(legacy('💊')).shapeIcon, 'capsule');

    final kept = Medication.fromMap({
      ...legacy('💧'),
      'shapeIcon': 'tablet',
    });
    expect(kept.shapeIcon, 'tablet');
  });

  test('semana ausente no JSON antigo cobre os sete dias', () {
    final restored = Medication.fromMap(legacy('💊'));

    expect(restored.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
    expect(restored.active, isTrue);
    expect(restored.source, MedicationSource.local);
  });
}
