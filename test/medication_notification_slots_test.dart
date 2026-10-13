import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/service/medication_reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('conta avisos de dose e adiamento na fila do aparelho', () async {
    SharedPreferences.setMockInitialValues({
      'noa_med_reminder_schedule_v1': jsonEncode({
        'ids': [1, 2, 3],
        'signature': 'x',
        'snoozes': [
          {'id': 9, 'medicationId': 'm', 'logId': 'l'},
        ],
      }),
    });
    final prefs = await SharedPreferences.getInstance();

    expect(MedicationReminderService.occupiedNotificationSlots(prefs), 4);
  });

  test('agenda ausente ou ilegível não reserva lugar fantasma', () async {
    SharedPreferences.setMockInitialValues({
      'noa_med_reminder_schedule_v1': '{',
    });
    final prefs = await SharedPreferences.getInstance();

    expect(MedicationReminderService.occupiedNotificationSlots(prefs), 0);
  });
}
