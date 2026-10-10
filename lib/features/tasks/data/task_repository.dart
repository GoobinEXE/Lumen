import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/async_mutex.dart';
import '../../../core/persistence/stored_json.dart';
import '../../routine_mood/data/micro_habits_prefs.dart';
import '../domain/task_item.dart';
import '../domain/task_period.dart';

const tasksStorageKey = 'noa_tasks_v1';
const tasksMigratedKey = 'noa_tasks_migrated_from_habits_v1';

class TaskRepository {
  TaskRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  /// Cache deste isolate. A gravação recarrega o disco antes: o handler da
  /// notificação escreve noutro isolate e não enxerga este cache.
  static List<TaskItem>? _cache;
  static String? _rawFingerprint;

  Future<T> _synchronized<T>(Future<T> Function() action) {
    return PersistenceLocks.tasks.synchronized(() async {
      // O handler da notificação grava noutro isolate. Sem reload, o cache
      // deste processo relê o JSON antigo e a próxima edição apaga a conclusão.
      await _prefs.reload();
      _cache = null;
      _rawFingerprint = null;
      return action();
    });
  }

  Future<void> reload() async {
    await _prefs.reload();
    _cache = null;
    _rawFingerprint = null;
  }

  Future<List<TaskItem>> getTasks() => _synchronized(() async => _read());

  Future<List<TaskItem>> loadOrSeed(List<String> defaultTitles) {
    return _synchronized(() async {
      if (_prefs.getBool(tasksMigratedKey) ?? false) {
        return _read();
      }

      final fromTemplate = _templateHabits();
      final source = fromTemplate.isNotEmpty ? fromTemplate : defaultTitles;
      final seeded = [
        for (final title in source)
          if (title.trim().isNotEmpty)
            TaskItem(
              id: _uuid.v4(),
              title: title.trim(),
              recurrence: TaskRecurrence.daily,
            ),
      ];
      await _saveAll(seeded);
      await _prefs.setBool(tasksMigratedKey, true);
      return seeded;
    });
  }

  Future<TaskItem?> getById(String id) {
    return _synchronized(() async {
      for (final task in _read()) {
        if (task.id == id) return task;
      }
      return null;
    });
  }

  Future<void> saveAll(List<TaskItem> tasks) {
    return _synchronized(() => _saveAll(tasks));
  }

  Future<TaskItem> upsert(TaskItem task) {
    return _synchronized(() async {
      final all = List<TaskItem>.from(_read());
      final index = all.indexWhere((t) => t.id == task.id);
      if (index >= 0) {
        all[index] = task;
      } else {
        all.add(task);
      }
      await _saveAll(all);
      return task;
    });
  }

  Future<void> delete(String id) {
    return _synchronized(() async {
      final all = _read();
      await _saveAll(all.where((t) => t.id != id).toList());
    });
  }

  Future<TaskItem> markComplete(String id, DateTime now) {
    return _synchronized(() async {
      final all = List<TaskItem>.from(_read());
      final index = all.indexWhere((t) => t.id == id);
      if (index < 0) {
        throw StateError('task missing: $id');
      }
      final task = all[index];
      final period = TaskPeriod.window(
        recurrence: task.recurrence,
        now: now,
        onceDate: task.onceDate,
      );
      final updated = task.copyWith(
        completedPeriodKey: period.periodKey,
        clearSnoozedUntil: true,
      );
      all[index] = updated;
      await _saveAll(all);
      return updated;
    });
  }

  Future<TaskItem> markIncomplete(String id) {
    return _synchronized(() async {
      final all = List<TaskItem>.from(_read());
      final index = all.indexWhere((t) => t.id == id);
      if (index < 0) {
        throw StateError('task missing: $id');
      }
      final updated = all[index].copyWith(clearCompletedPeriodKey: true);
      all[index] = updated;
      await _saveAll(all);
      return updated;
    });
  }

  Future<TaskItem> snooze(String id, DateTime until) {
    return _synchronized(() async {
      final all = List<TaskItem>.from(_read());
      final index = all.indexWhere((t) => t.id == id);
      if (index < 0) {
        throw StateError('task missing: $id');
      }
      final updated = all[index].copyWith(snoozedUntil: until);
      all[index] = updated;
      await _saveAll(all);
      return updated;
    });
  }

  List<String> titles(List<TaskItem> tasks) =>
      tasks.where((t) => t.active).map((t) => t.title).toList();

  Set<String> completedTitles(List<TaskItem> tasks, DateTime now) {
    return tasks
        .where((t) => t.active && TaskPeriod.isCompletedInCurrentPeriod(t, now))
        .map((t) => t.title)
        .toSet();
  }

  List<String> _templateHabits() {
    final raw = _prefs.getString(microHabitsTemplateKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  List<TaskItem> _read() {
    final raw = _prefs.getString(tasksStorageKey);
    final fingerprint = raw ?? '';
    final cached = _cache;
    if (cached != null && _rawFingerprint == fingerprint) return cached;

    final read = decodeStoredJsonList<TaskItem>(
      raw,
      (map) {
        try {
          final task = TaskItem.fromMap(map);
          if (task.id.isEmpty || task.title.isEmpty) return null;
          return task;
        } catch (_) {
          return null;
        }
      },
    );
    if (read.unreadable) {
      _cache = const [];
      _rawFingerprint = fingerprint;
      return _cache!;
    }
    _cache = read.items;
    _rawFingerprint = fingerprint;
    return read.items;
  }

  Future<void> _saveAll(List<TaskItem> tasks) async {
    if (storedJsonListBlobIsUnreadable(_prefs.getString(tasksStorageKey))) {
      return;
    }
    final encoded = encodeStoredJsonList(tasks.map((t) => t.toMap()));
    await _prefs.setString(tasksStorageKey, encoded);
    _cache = List<TaskItem>.from(tasks);
    _rawFingerprint = encoded;
  }
}
