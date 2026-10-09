import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/persistence/async_mutex.dart';
import '../../../core/persistence/stored_json.dart';
import '../../../core/time/civil_day.dart';
import '../domain/mood_entry.dart';

class MoodRepository {
  static const String _storageKey = 'noa_mood_entries_v2';
  final SharedPreferences _prefs;

  var _preserveUnreadablePayload = false;

  static List<MoodEntry>? _cache;
  static Map<String, List<MoodEntry>>? _byDayCache;
  static String? _rawFingerprint;

  MoodRepository(this._prefs);

  Future<T> _synchronized<T>(Future<T> Function() action) =>
      PersistenceLocks.mood.synchronized(action);

  Future<void> addEntry(MoodEntry entry) {
    return _synchronized(() async {
      final list = List<MoodEntry>.from(_readAll());
      list.insert(0, entry);
      await _saveList(list);
    });
  }

  Future<List<MoodEntry>> getAllEntries() =>
      _synchronized(() async => _readAll());

  Future<MoodEntry?> getLatestEntry() {
    return _synchronized(() async {
      final list = _readAll();
      return list.isNotEmpty ? list.first : null;
    });
  }

  Future<List<MoodEntry>> getEntriesForDays(int days) {
    return _synchronized(() async {
      final all = _readAll();
      final cutoff = DateTime.now().subtract(Duration(days: days));
      return all.where((e) => e.timestamp.isAfter(cutoff)).toList();
    });
  }

  Future<List<MoodEntry>> getEntriesForCivilDay(DateTime day) {
    return _synchronized(() async {
      final key = civilDayKey(day);
      return List<MoodEntry>.from(_indexByDay()[key] ?? const []);
    });
  }

  Future<Set<DateTime>> markedCivilDays() {
    return _synchronized(() async {
      return {
        for (final key in _indexByDay().keys)
          DateTime.parse('${key}T00:00:00'),
      };
    });
  }

  List<MoodEntry> _readAll() {
    final raw = _prefs.getString(_storageKey);
    final fingerprint = raw ?? '';
    final cached = _cache;
    if (cached != null && _rawFingerprint == fingerprint) return cached;

    final read = decodeStoredJsonList<MoodEntry>(
      raw,
      (map) {
        try {
          return MoodEntry.fromMap(map);
        } catch (_) {
          return null;
        }
      },
    );
    if (read.unreadable) {
      _preserveUnreadablePayload = true;
      _cache = const [];
      _byDayCache = {};
      _rawFingerprint = fingerprint;
      return _cache!;
    }
    _preserveUnreadablePayload = false;
    _cache = read.items;
    _byDayCache = null;
    _rawFingerprint = fingerprint;
    return read.items;
  }

  Map<String, List<MoodEntry>> _indexByDay() {
    final cached = _byDayCache;
    if (cached != null) return cached;
    final index = <String, List<MoodEntry>>{};
    for (final entry in _readAll()) {
      final key = civilDayKey(entry.timestamp);
      (index[key] ??= []).add(entry);
    }
    for (final list in index.values) {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
    _byDayCache = index;
    return index;
  }

  Future<void> _saveList(List<MoodEntry> list) async {
    if (_preserveUnreadablePayload) return;
    final encoded = encodeStoredJsonList(list.map((e) => e.toMap()));
    await _prefs.setString(_storageKey, encoded);
    _cache = List<MoodEntry>.from(list);
    _byDayCache = null;
    _rawFingerprint = encoded;
  }
}
