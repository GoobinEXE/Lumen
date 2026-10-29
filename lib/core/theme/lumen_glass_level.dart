import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../integrations/system/system_settings.dart';

/// Intensidade do vidro no chrome iOS (HIG: navegação/controles, não conteúdo).
enum LumenGlassLevel {
  /// Transparente — refração plena.
  clear,

  /// Colorido — mais opaco, mais contraste; borda reforçada.
  tinted,

  /// Opaco — sem refração (Reduzir Transparência ou escolha explícita).
  solid,
}

/// Resolve o nível a partir do que o sistema deixa ler.
///
/// Sem API pública para Transparente/Colorido do iOS 26.1; usa
/// Reduzir Transparência e Aumentar Contraste.
LumenGlassLevel resolveLumenGlassLevel({
  required bool reduceTransparency,
  required bool highContrast,
  LumenGlassLevel? preference,
}) {
  if (preference != null) return preference;
  if (reduceTransparency) return LumenGlassLevel.solid;
  if (highContrast) return LumenGlassLevel.tinted;
  return LumenGlassLevel.clear;
}

/// Snapshot de acessibilidade que o glass lê (iOS; no Android fica neutro).
@immutable
class LumenGlassAccessibility {
  const LumenGlassAccessibility({
    this.reduceTransparency = false,
    this.highContrast = false,
  });

  final bool reduceTransparency;
  final bool highContrast;

  LumenGlassLevel get resolvedLevel => resolveLumenGlassLevel(
        reduceTransparency: reduceTransparency,
        highContrast: highContrast,
      );

  @override
  bool operator ==(Object other) {
    return other is LumenGlassAccessibility &&
        other.reduceTransparency == reduceTransparency &&
        other.highContrast == highContrast;
  }

  @override
  int get hashCode => Object.hash(reduceTransparency, highContrast);
}

final systemSettingsForGlassProvider = Provider<SystemSettings>((ref) {
  return SystemSettings();
});

/// Flags nativas + [MediaQuery.highContrast]; refresca ao voltar do background.
final lumenGlassAccessibilityProvider =
    AsyncNotifierProvider<LumenGlassAccessibilityNotifier, LumenGlassAccessibility>(
  LumenGlassAccessibilityNotifier.new,
);

class LumenGlassAccessibilityNotifier
    extends AsyncNotifier<LumenGlassAccessibility> {
  @override
  Future<LumenGlassAccessibility> build() async {
    return _read();
  }

  Future<void> refresh() async {
    state = AsyncData(await _read());
  }

  Future<LumenGlassAccessibility> _read() async {
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    if (!isIos) {
      return const LumenGlassAccessibility();
    }
    final settings = ref.read(systemSettingsForGlassProvider);
    final reduce = await settings.isReduceTransparencyEnabled();
    return LumenGlassAccessibility(reduceTransparency: reduce);
  }
}

/// Nível efetivo: preferência do app + acessibilidade + contraste.
LumenGlassLevel lumenGlassLevelOf(
  BuildContext context,
  WidgetRef ref, {
  LumenGlassLevel? preference,
}) {
  final highContrast = MediaQuery.highContrastOf(context);
  final a11y = ref.watch(lumenGlassAccessibilityProvider).valueOrNull ??
      const LumenGlassAccessibility();
  return resolveLumenGlassLevel(
    reduceTransparency: a11y.reduceTransparency,
    highContrast: highContrast || a11y.highContrast,
    preference: preference,
  );
}

/// Versão sem Riverpod (wrappers Stateless que só têm [BuildContext]).
LumenGlassLevel lumenGlassLevelFromMedia({
  required BuildContext context,
  bool reduceTransparency = false,
}) {
  return resolveLumenGlassLevel(
    reduceTransparency: reduceTransparency,
    highContrast: MediaQuery.highContrastOf(context),
  );
}

/// Inherited para o chrome ler o nível sem todo widget virar Consumer.
class LumenGlassScope extends InheritedWidget {
  const LumenGlassScope({
    super.key,
    required this.level,
    required this.reduceTransparency,
    required super.child,
  });

  final LumenGlassLevel level;
  final bool reduceTransparency;

  static LumenGlassScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LumenGlassScope>();
  }

  static LumenGlassLevel levelOf(BuildContext context) {
    final scope = maybeOf(context);
    if (scope != null) return scope.level;
    return lumenGlassLevelFromMedia(context: context);
  }

  @override
  bool updateShouldNotify(LumenGlassScope oldWidget) {
    return level != oldWidget.level ||
        reduceTransparency != oldWidget.reduceTransparency;
  }
}
