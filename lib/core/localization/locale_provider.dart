import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';
import '../providers.dart';

const String _localePrefKey = 'noa_preferred_locale_code';

class LocaleNotifier extends StateNotifier<Locale?> {
  final Ref _ref;

  LocaleNotifier(this._ref) : super(null) {
    _loadPreference();
  }

  void _loadPreference() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final savedCode = prefs.getString(_localePrefKey);
      if (savedCode != null && savedCode.isNotEmpty && savedCode != 'system') {
        state = Locale(savedCode);
      } else {
        state = null; // null = sincronizar com o sistema
      }
    } catch (_) {
      state = null;
    }
  }

  Future<void> setLocale(String? languageCode) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    if (languageCode == null || languageCode == 'system') {
      await prefs.setString(_localePrefKey, 'system');
      state = null;
    } else {
      await prefs.setString(_localePrefKey, languageCode);
      state = Locale(languageCode);
    }
  }
}

/// Provedor da escolha explícita do usuário (null = automático pelo sistema)
final userLocalePreferenceProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref);
});

/// Provedor do Locale ativo consolidado (resolvendo sistema vs manual)
final activeLocaleProvider = Provider<Locale>((ref) {
  final userPref = ref.watch(userLocalePreferenceProvider);
  if (userPref != null) return userPref;

  // Sincronização automática com a preferência do sistema operacional
  final systemLocale = PlatformDispatcher.instance.locale;
  final code = systemLocale.languageCode.toLowerCase();

  switch (code) {
    case 'en':
      return const Locale('en', 'US');
    case 'ja':
      return const Locale('ja', 'JP');
    case 'es':
      return const Locale('es', 'ES');
    case 'pt':
    default:
      return const Locale('pt', 'BR');
  }
});

/// Strings ativas no idioma atual (camadas sem BuildContext)
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  return lookupAppLocalizations(ref.watch(activeLocaleProvider));
});
