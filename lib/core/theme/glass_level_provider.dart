import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'lumen_glass_level.dart';

const String glassLevelPrefKey = 'noa_glass_level_v1';

/// Preferência da pessoa para o vidro do chrome iOS.
enum LumenGlassPreference {
  /// Segue Reduzir Transparência / Aumentar Contraste.
  system,

  /// Força transparente.
  clear,

  /// Força colorido (mais opaco).
  tinted,

  /// Força sólido.
  solid,
}

extension LumenGlassPreferenceX on LumenGlassPreference {
  /// `null` = deixar a resolução automática decidir.
  LumenGlassLevel? get overrideLevel => switch (this) {
        LumenGlassPreference.system => null,
        LumenGlassPreference.clear => LumenGlassLevel.clear,
        LumenGlassPreference.tinted => LumenGlassLevel.tinted,
        LumenGlassPreference.solid => LumenGlassLevel.solid,
      };

  String get storageValue => name;
}

class GlassLevelNotifier extends StateNotifier<LumenGlassPreference> {
  GlassLevelNotifier(this._ref) : super(LumenGlassPreference.system) {
    _load();
  }

  final Ref _ref;

  void _load() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      state = _fromStorage(prefs.getString(glassLevelPrefKey));
    } catch (_) {
      state = LumenGlassPreference.system;
    }
  }

  Future<void> setPreference(LumenGlassPreference preference) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(glassLevelPrefKey, preference.storageValue);
    state = preference;
  }

  static LumenGlassPreference _fromStorage(String? value) {
    switch (value) {
      case 'clear':
        return LumenGlassPreference.clear;
      case 'tinted':
        return LumenGlassPreference.tinted;
      case 'solid':
        return LumenGlassPreference.solid;
      case 'system':
      default:
        return LumenGlassPreference.system;
    }
  }
}

final glassLevelPreferenceProvider =
    StateNotifierProvider<GlassLevelNotifier, LumenGlassPreference>((ref) {
  return GlassLevelNotifier(ref);
});
