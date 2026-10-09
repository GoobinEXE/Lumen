import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/task_quiet_hours.dart';

const taskQuietHoursKey = 'noa_task_quiet_hours_v1';

TaskQuietHours getTaskQuietHours(SharedPreferences prefs) {
  final raw = prefs.getString(taskQuietHoursKey);
  if (raw == null || raw.isEmpty) return const TaskQuietHours.defaults();
  try {
    final map = jsonDecode(raw);
    if (map is! Map) return const TaskQuietHours.defaults();
    return TaskQuietHours.fromMap(Map<String, dynamic>.from(map));
  } catch (_) {
    return const TaskQuietHours.defaults();
  }
}

Future<void> setTaskQuietHours(
  SharedPreferences prefs,
  TaskQuietHours hours,
) {
  return prefs.setString(taskQuietHoursKey, jsonEncode(hours.toMap()));
}
