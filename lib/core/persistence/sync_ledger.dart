import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'async_mutex.dart';

/// Marcas do que já foi espelhado no Saúde ou no calendário.
///
/// A atualização do app conserva essas marcas. Sem a marca, ou com a lista
/// ilegível, o mesmo registro não é escrito de novo.
class SyncLedger {
  static const String waterSnapshots = 'noa_health_water_snapshot_ids_v1';
  static const String stateOfMindMs = 'noa_health_som_synced_ms_v1';
  static const String calendarSnapshots = 'noa_calendar_snapshot_ids_v1';

  /// Teto por ledger — evita crescimento ilimitado sem mudar a semântica recente.
  static const int maxIds = 400;

  static final Map<String, Set<String>> _memory = {};

  static bool contains(SharedPreferences prefs, String key, String id) {
    if (id.isEmpty) return true;
    final read = _read(prefs, key);
    if (read.unreadable) return true;
    return read.ids.contains(id);
  }

  static Future<void> remember(
    SharedPreferences prefs,
    String key,
    String id,
  ) {
    return PersistenceLocks.syncLedger.synchronized(() async {
      if (id.isEmpty) return;
      final read = _read(prefs, key);
      if (read.unreadable || read.ids.contains(id)) return;
      read.ids.add(id);
      while (read.ids.length > maxIds) {
        read.ids.remove(read.ids.first);
      }
      await prefs.setString(key, jsonEncode(read.ids.toList()));
      _memory[key] = read.ids;
    });
  }

  static ({Set<String> ids, bool unreadable}) _read(
    SharedPreferences prefs,
    String key,
  ) {
    final cached = _memory[key];
    if (cached != null) {
      return (ids: cached, unreadable: false);
    }
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      final empty = <String>{};
      _memory[key] = empty;
      return (ids: empty, unreadable: false);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return (ids: <String>{}, unreadable: true);
      final ids = decoded.map((item) => item.toString()).toSet();
      _memory[key] = ids;
      return (ids: ids, unreadable: false);
    } catch (_) {
      return (ids: <String>{}, unreadable: true);
    }
  }
}
