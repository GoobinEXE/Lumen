import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/data/medication_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('pular a dose solta o adiamento', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = MedicationRepository(prefs);
    final log = await repo.ensureDoseLog(
      medicationId: 'med-1',
      medicationName: 'Lisdexanfetamina',
      scheduled: DateTime(2026, 10, 1, 8),
    );

    await repo.snoozeLog(log.id, 15);
    expect((await repo.logById(log.id))!.isSnoozed, isTrue);

    await repo.skipLog(log.id, 'voluntary');
    final skipped = await repo.logById(log.id);

    expect(skipped!.skipped, isTrue);
    expect(skipped.skipReason, 'voluntary');
    expect(skipped.snoozedUntil, isNull);
    expect(skipped.isSnoozed, isFalse);
  });
}
