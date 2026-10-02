import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers.dart';

/// Telefone do terapeuta. A chave atual tem versão; a leitura ainda
/// aceita a chave anterior para não perder o que já foi salvo.
class TherapistContactRepository {
  TherapistContactRepository(this._prefs);

  static const String currentKey = 'noa_therapist_phone_v1';
  static const String legacyKey = 'noa_therapist_phone';

  final SharedPreferences _prefs;

  String readPhone() {
    final current = _prefs.getString(currentKey);
    if (current != null) return current;
    final legacy = _prefs.getString(legacyKey);
    if (legacy == null) return '';
    _prefs.setString(currentKey, legacy);
    return legacy;
  }

  Future<void> savePhone(String value) {
    return _prefs.setString(currentKey, value.trim());
  }
}

final therapistContactRepositoryProvider =
    Provider<TherapistContactRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TherapistContactRepository(prefs);
});
