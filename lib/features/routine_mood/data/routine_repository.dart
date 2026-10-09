import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/async_mutex.dart';
import '../../../core/time/civil_day.dart';
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
  final Set<String> _blockedKeys = {};
  Set<DateTime>? _markedDaysCache;
  final Map<String, List<RoutineSnapshot>> _snapshotCache = {};

  RoutineRepository(this._prefs);

  Future<T> _synchronized<T>(Future<T> Function() action) =>
      PersistenceLocks.routine.synchronized(action);

  String _getKey(DateTime date) {
    final day = civilDay(date);
    return '$_routinePrefix${day.year}_${day.month}_${day.day}';
  }

  List<RoutineSnapshot> getSnapshotsForDate(DateTime date) {
    final key = _getKey(date);
    final cached = _snapshotCache[key];
    if (cached != null) return cached;

    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      _blockedKeys.remove(key);
      _snapshotCache[key] = const [];
      return const [];
    }
    final decoded = _decode(raw);
    if (decoded.unreadable) {
      _blockedKeys.add(key);
      _snapshotCache[key] = const [];
      return const [];
    }
    _blockedKeys.remove(key);
    _snapshotCache[key] = decoded.snapshots;
    return decoded.snapshots;
  }

  Future<void> appendSnapshot(RoutineSnapshot snapshot) {
    return _synchronized(() async {
      final existing = getSnapshotsForDate(snapshot.savedAt);
      final next = [...existing, snapshot]
        ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      await _write(snapshot.savedAt, next);
      await setMicroHabitsTemplate(_prefs, snapshot.microHabits);
    });
  }

  Future<RoutineSnapshot> mergeTodayStateOfMind(StateOfMindEntry entry) {
    return _synchronized(() async {
      final existing = getSnapshotsForDate(entry.timestamp);
      if (existing.isEmpty) {
        final snapshot = RoutineSnapshot(
          id: const Uuid().v4(),
          savedAt: entry.timestamp,
          stateOfMind: entry,
        );
        await _write(entry.timestamp, [snapshot]);
        return snapshot;
      }
      final latest = existing.last;
      final merged = latest.copyWith(stateOfMind: entry);
      final next = [
        for (final snapshot in existing)
          if (snapshot.id == latest.id) merged else snapshot,
      ];
      await _write(entry.timestamp, next);
      return merged;
    });
  }

  Future<void> setCalendarEventId({
    required DateTime savedAt,
    required String snapshotId,
    required String eventId,
  }) {
    return _synchronized(() async {
      final next = [
        for (final snapshot in getSnapshotsForDate(savedAt))
          if (snapshot.id == snapshotId)
            snapshot.copyWith(calendarEventId: eventId)
          else
            snapshot,
      ];
      await _write(savedAt, next);
    });
  }

  List<RoutineSnapshot> snapshotsSince(DateTime start) {
    final startDay = civilDay(start);
    final days = markedDays();
    final all = <RoutineSnapshot>[];
    for (final day in days) {
      if (day.isBefore(startDay)) continue;
      all.addAll(getSnapshotsForDate(day));
    }
    all.sort((a, b) => a.savedAt.compareTo(b.savedAt));
    return all;
  }

  Set<DateTime> markedDays() {
    final cached = _markedDaysCache;
    if (cached != null) return cached;

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
    _markedDaysCache = days;
    return days;
  }

  int countAppleHealthStateOfMind({int days = 14}) {
    final today = civilDay(DateTime.now());
    var count = 0;
    for (var i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      final snapshots = getSnapshotsForDate(day);
      final fromApple = snapshots.any(
        (snapshot) =>
            snapshot.stateOfMind?.source == StateOfMindSource.appleHealth,
      );
      if (fromApple) count++;
    }
    return count;
  }

  Future<void> _write(DateTime date, List<RoutineSnapshot> snapshots) async {
    final key = _getKey(date);
    if (_blockedKeys.contains(key)) return;
    final raw =
        jsonEncode(snapshots.map((snapshot) => snapshot.toMap()).toList());
    await _prefs.setString(key, raw);
    _snapshotCache[key] = List<RoutineSnapshot>.from(snapshots)
      ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    final day = civilDay(date);
    final marked = _markedDaysCache ?? <DateTime>{};
    if (snapshots.isEmpty) {
      marked.remove(day);
    } else {
      marked.add(day);
    }
    _markedDaysCache = marked;
  }

  ({List<RoutineSnapshot> snapshots, bool unreadable}) _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final snapshots = <RoutineSnapshot>[];
        var hadCorrupt = false;
        for (final item in decoded) {
          if (item is! Map) {
            hadCorrupt = true;
            continue;
          }
          try {
            snapshots.add(
              RoutineSnapshot.fromMap(Map<String, dynamic>.from(item)),
            );
          } catch (_) {
            hadCorrupt = true;
          }
        }
        if (snapshots.isEmpty && hadCorrupt && decoded.isNotEmpty) {
          return (snapshots: const [], unreadable: true);
        }
        snapshots.sort((a, b) => a.savedAt.compareTo(b.savedAt));
        return (snapshots: snapshots, unreadable: false);
      }
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        if (map['date'] is! String) {
          return (snapshots: const [], unreadable: true);
        }
        return (
          snapshots: [
            RoutineSnapshot.fromLegacy(DailyRoutineState.fromMap(map)),
          ],
          unreadable: false,
        );
      }
    } catch (_) {
      return (snapshots: const [], unreadable: true);
    }
    return (snapshots: const [], unreadable: true);
  }
}
