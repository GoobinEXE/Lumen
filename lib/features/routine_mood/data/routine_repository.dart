import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../state_of_mind/domain/state_of_mind_entry.dart';
import '../domain/daily_routine_state.dart';
import '../domain/routine_snapshot.dart';
import 'micro_habits_prefs.dart';

class RoutineRepository {
  static const String _routinePrefix = 'noa_daily_routine_';
  static final RegExp _keyPattern = RegExp(
    r'^noa_daily_routine_(\d+)_(\d+)_(\d+)$',
  );

  final SharedPreferences _prefs;

  RoutineRepository(this._prefs);

  String _getKey(DateTime date) {
    return '$_routinePrefix${date.year}_${date.month}_${date.day}';
  }

  List<RoutineSnapshot> getSnapshotsForDate(DateTime date) {
    final raw = _prefs.getString(_getKey(date));
    if (raw == null || raw.isEmpty) return const [];
    return _decode(raw);
  }

  Future<void> appendSnapshot(RoutineSnapshot snapshot) async {
    final existing = getSnapshotsForDate(snapshot.savedAt);
    final next = [...existing, snapshot]
      ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    await _write(snapshot.savedAt, next);
    await setMicroHabitsTemplate(_prefs, snapshot.microHabits);
  }

  Future<void> setCalendarEventId({
    required DateTime savedAt,
    required String snapshotId,
    required String eventId,
  }) async {
    final next = [
      for (final snapshot in getSnapshotsForDate(savedAt))
        if (snapshot.id == snapshotId)
          snapshot.copyWith(calendarEventId: eventId)
        else
          snapshot,
    ];
    await _write(savedAt, next);
  }

  List<RoutineSnapshot> snapshotsSince(DateTime start) {
    final startDay = DateTime(start.year, start.month, start.day);
    final all = <RoutineSnapshot>[];
    for (final day in markedDays()) {
      if (day.isBefore(startDay)) continue;
      all.addAll(getSnapshotsForDate(day));
    }
    all.sort((a, b) => a.savedAt.compareTo(b.savedAt));
    return all;
  }

  Set<DateTime> markedDays() {
    final days = <DateTime>{};
    for (final key in _prefs.getKeys()) {
      final match = _keyPattern.firstMatch(key);
      if (match == null) continue;
      final day = DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
      if (getSnapshotsForDate(day).isEmpty) continue;
      days.add(day);
    }
    return days;
  }

  /// Conta dias com State of Mind originado do Apple Health (últimos [days]).
  int countAppleHealthStateOfMind({int days = 14}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var count = 0;
    for (var i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      final snapshots = getSnapshotsForDate(day);
      final fromApple = snapshots.any(
        (snapshot) => snapshot.stateOfMind?.source == StateOfMindSource.appleHealth,
      );
      if (fromApple) count++;
    }
    return count;
  }

  Future<void> _write(DateTime date, List<RoutineSnapshot> snapshots) async {
    final raw = jsonEncode(snapshots.map((snapshot) => snapshot.toMap()).toList());
    await _prefs.setString(_getKey(date), raw);
  }

  List<RoutineSnapshot> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final snapshots = <RoutineSnapshot>[];
        for (final item in decoded) {
          if (item is! Map) continue;
          snapshots.add(
            RoutineSnapshot.fromMap(Map<String, dynamic>.from(item)),
          );
        }
        snapshots.sort((a, b) => a.savedAt.compareTo(b.savedAt));
        return snapshots;
      }
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        if (map['date'] is! String) return const [];
        return [RoutineSnapshot.fromLegacy(DailyRoutineState.fromMap(map))];
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }
}
