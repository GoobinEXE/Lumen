import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'lumen_glass_style.dart';

/// Overlay de toque sem ripple Material 3 (opacidade suave).
WidgetStateProperty<Color?> get glassInkOverlay =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.white.withValues(alpha: 0.14);
      }
      if (states.contains(WidgetState.hovered)) {
        return Colors.white.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.focused)) {
        return Colors.white.withValues(alpha: 0.1);
      }
      return null;
    });

/// Card / painel com Liquid Glass (`liquid_glass_renderer`).
///
/// Superfícies de conteúdo usam FakeGlass por padrão (sem `toImageSync` por
/// card). [lite] permanece por compatibilidade e força o mesmo caminho.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = AppRadii.card,
    this.padding,
    this.tint,
    this.onTap,
    this.shadowColor,
    this.lite = false,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final VoidCallback? onTap;
  final Color? shadowColor;

  /// Compat: força FakeGlass (já é o caminho padrão de [LumenGlassRole.surface]).
  final bool lite;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentPadding = padding ?? EdgeInsets.zero;

    Widget content = Padding(padding: contentPadding, child: child);
    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: lumenGlassShadow(
          isDark: isDark,
          shadowColor: shadowColor,
        ),
      ),
      child: LumenGlass(
        role: LumenGlassRole.surface,
        cornerRadius: borderRadius,
        tint: tint,
        forceLite: lite,
        child: content,
      ),
    );
  }
}

/// Padding de scroll para campos em [GlassSheet] — folga sob o input + CTA.
///
/// O [GlassSheet] já ergue o painel com o inset inferior; este padding é fixo
/// (não soma o teclado de novo) para [Scrollable.ensureVisible] /
/// [lumenEnsureSheetFieldVisible] manter o campo acima do teclado.
const EdgeInsets lumenSheetFieldScrollPadding = EdgeInsets.fromLTRB(
  20,
  20,
  20,
  120,
);

/// Fração da área útil acima do teclado/home indicator.
const double lumenSheetMaxHeightFraction = 0.92;

/// Altura mínima útil da gaveta com teclado aberto (debug + testes).
const double lumenSheetMinUsableHeight = 280;

/// Inset inferior único: teclado se aberto, senão home indicator.
///
/// Nunca some teclado + SafeArea + home indicator — isso esmagava a gaveta.
double lumenSheetBottomInset({
  required double keyboardBottom,
  required double viewPaddingBottom,
}) {
  return keyboardBottom > 0 ? keyboardBottom : viewPaddingBottom;
}

/// Teto da gaveta acima do [lumenSheetBottomInset].
double lumenSheetMaxHeight({
  required double screenHeight,
  required double bottomInset,
  double fraction = lumenSheetMaxHeightFraction,
}) {
  return (screenHeight - bottomInset).clamp(0.0, double.infinity) * fraction;
}

/// Rola o scroll pai até o campo focado ficar visível acima do teclado.
///
/// Agenda um segundo passe após o teclado animar — o primeiro frame ainda
/// costuma ter `viewInsets` antigo e o campo ficaria coberto.
void lumenEnsureSheetFieldVisible(BuildContext fieldContext) {
  final reduce = MediaQuery.disableAnimationsOf(fieldContext);
  void reveal() {
    if (!fieldContext.mounted) return;
    Scrollable.ensureVisible(
      fieldContext,
      alignment: 0.15,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    reveal();
    Future<void>.delayed(
      reduce ? Duration.zero : const Duration(milliseconds: 320),
      reveal,
    );
  });
}

/// Abre um bottom sheet com o contrato único de teclado.
///
/// Contrato (obrigatório para forms e gavetas com teclado):
/// - Callers **não** aplicam `Padding(viewInsets)` nem `removeViewInsets`.
/// - **Não** passar `useSafeArea: true` — SafeArea do modal + teclado
///   esmagava a gaveta (desconto triplo). O inset fica em
///   [LumenKeyboardInset] / [GlassSheet].
/// - Forms glass: [GlassSheet] sem `expandChild: true`.
/// - Sheets Material / Draggable: envolver com [LumenKeyboardInset].
/// - Campos: [lumenSheetFieldScrollPadding] + [lumenEnsureSheetFieldVisible].
/// - Sempre [useRootNavigator]: a [GlassNavBar] mora fora dos Navigators
///   das abas; modal na aba ficava **atrás** da tab bar e cobria o CTA.
Future<T?> showLumenSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useSafeArea = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  assert(
    !useSafeArea,
    'showLumenSheet: useSafeArea: true + teclado esmaga a gaveta. '
    'Deixe false; LumenKeyboardInset/GlassSheet cuidam do inset.',
  );
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    routeSettings: routeSettings,
    builder: builder,
  );
}

/// Só o contrato de teclado/home indicator — sem glass.
///
/// Usar com [showLumenSheet] quando o conteúdo **não** é [GlassSheet]
/// (Des-Trava Material, digest com [DraggableScrollableSheet], etc.).
class LumenKeyboardInset extends StatelessWidget {
  const LumenKeyboardInset({
    super.key,
    required this.child,
    this.fraction = lumenSheetMaxHeightFraction,
  });

  final Widget child;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = lumenSheetBottomInset(
      keyboardBottom: media.viewInsets.bottom,
      viewPaddingBottom: media.viewPadding.bottom,
    );
    final maxHeight = lumenSheetMaxHeight(
      screenHeight: media.size.height,
      bottomInset: bottomInset,
      fraction: fraction,
    );
    assert(
      media.viewInsets.bottom == 0 || maxHeight >= lumenSheetMinUsableHeight,
      'LumenKeyboardInset: área útil $maxHeight < $lumenSheetMinUsableHeight '
      'com teclado — revise useSafeArea/Padding duplicado no caller.',
    );

    return AnimatedPadding(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        key: const Key('lumen-keyboard-inset'),
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: child,
        ),
      ),
    );
  }
}

/// Envelope de bottom sheet com Liquid Glass (FakeGlass legível).
///
/// Teclado via [LumenKeyboardInset] (ver [showLumenSheet]). Forms: scroll
/// único; **não** use [expandChild] em formulários longos.
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.padding,
    this.showHandle = true,
    this.expandChild = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showHandle;

  /// Preenche a altura disponível. Só para layouts que rolam por conta
  /// própria — forms longos devem deixar `false` (scroll do [GlassSheet]).
  final bool expandChild;

  static const EdgeInsets defaultPadding = EdgeInsets.fromLTRB(
    AppSpacing.sheetH,
    AppSpacing.sheetTop,
    AppSpacing.sheetH,
    AppSpacing.sheetBottom,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const topRadius = BorderRadius.vertical(
      top: Radius.circular(AppRadii.sheet),
    );

    final handle = showHandle
        ? <Widget>[
            Center(
              child: Container(
                width: AppSheetHandle.width,
                height: AppSheetHandle.height,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.handle),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ]
        : const <Widget>[];

    final paddedChild = Padding(
      padding: padding ?? defaultPadding,
      child: child,
    );

    // expandChild: header fixo + body que preenche.
    // Default: um scroll só (handle + conteúdo) — sem Flexible/min Column.
    final Widget body;
    if (expandChild) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...handle,
          Expanded(child: paddedChild),
        ],
      );
    } else {
      body = SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...handle,
            paddedChild,
          ],
        ),
      );
    }

    return LumenKeyboardInset(
      child: ClipRRect(
        borderRadius: topRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: topRadius,
            boxShadow: lumenGlassShadow(
              isDark: isDark,
              role: LumenGlassRole.sheet,
            ),
          ),
          child: LumenGlass(
            role: LumenGlassRole.sheet,
            cornerRadius: AppRadii.sheet,
            child: body,
          ),
        ),
      ),
    );
  }
}
