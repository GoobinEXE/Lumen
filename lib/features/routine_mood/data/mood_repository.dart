import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/mood_entry.dart';

class MoodRepository {
  static const String _storageKey = 'noa_mood_entries_v2';
  final SharedPreferences _prefs;

  MoodRepository(this._prefs);

  /// Salva um novo registro de humor
  Future<void> addEntry(MoodEntry entry) async {
    final list = await getAllEntries();
    list.insert(0, entry); // Mais recente no início
    await _saveList(list);
  }

  /// Retorna todos os registros salvos
  Future<List<MoodEntry>> getAllEntries() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => MoodEntry.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Retorna o registro mais recente
  Future<MoodEntry?> getLatestEntry() async {
    final list = await getAllEntries();
    return list.isNotEmpty ? list.first : null;
  }

  /// Filtra registros para um intervalo de dias
  Future<List<MoodEntry>> getEntriesForDays(int days) async {
    final all = await getAllEntries();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }

  Future<void> _saveList(List<MoodEntry> list) async {
    final encoded = jsonEncode(list.map((e) => e.toMap()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
