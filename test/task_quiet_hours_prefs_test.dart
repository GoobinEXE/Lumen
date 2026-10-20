import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/tasks/data/task_quiet_hours_prefs.dart';
import 'package:noa/features/tasks/domain/task_quiet_hours.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('silêncio salvo volta com hora e minuto', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const hours = TaskQuietHours(
      startHour: 13,
      startMinute: 15,
      endHour: 15,
      endMinute: 45,
    );

    await setTaskQuietHours(prefs, hours);
    final restored = getTaskQuietHours(prefs);

    expect(restored.startHour, 13);
    expect(restored.startMinute, 15);
    expect(restored.endHour, 15);
    expect(restored.endMinute, 45);
    expect(restored.contains(DateTime(2026, 10, 20, 13, 15)), isTrue);
    expect(restored.contains(DateTime(2026, 10, 20, 15, 45)), isFalse);
  });

  test('JSON quebrado ou hora em texto volta ao silêncio da noite', () async {
    SharedPreferences.setMockInitialValues({
      taskQuietHoursKey: 'não é json',
    });
    final broken = await SharedPreferences.getInstance();
    final fallback = getTaskQuietHours(broken);
    expect(fallback.startHour, 22);
    expect(fallback.startMinute, 0);
    expect(fallback.endHour, 7);
    expect(fallback.endMinute, 0);

    SharedPreferences.setMockInitialValues({
      taskQuietHoursKey: jsonEncode({'startHour': '21', 'endHour': 6}),
    });
    final typed = await SharedPreferences.getInstance();
    final fromText = getTaskQuietHours(typed);
    expect(fromText.startHour, 22);
    expect(fromText.endHour, 7);
  });

  test('mapa sem minuto conserva a hora e completa o resto', () async {
    SharedPreferences.setMockInitialValues({
      taskQuietHoursKey: jsonEncode({'startHour': 21, 'endHour': 6}),
    });
    final prefs = await SharedPreferences.getInstance();
    final hours = getTaskQuietHours(prefs);

    expect(hours.startHour, 21);
    expect(hours.startMinute, 0);
    expect(hours.endHour, 6);
    expect(hours.endMinute, 0);
    expect(hours.contains(DateTime(2026, 10, 20, 21)), isTrue);
    expect(hours.contains(DateTime(2026, 10, 20, 12)), isFalse);
  });
}
