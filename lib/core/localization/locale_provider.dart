import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';

/// Mapeia o locale do aparelho para um dos suportados pelo Lumen.
Locale resolveSupportedLocale([Locale? locale]) {
  final code =
      (locale ?? PlatformDispatcher.instance.locale).languageCode.toLowerCase();
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
}

/// Locale ativo = preferência do sistema (sem override no app).
final activeLocaleProvider = Provider<Locale>((ref) {
  return resolveSupportedLocale();
});

/// Strings ativas no idioma atual (camadas sem BuildContext).
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  return lookupAppLocalizations(ref.watch(activeLocaleProvider));
});
