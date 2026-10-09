import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/lumen_glass_style.dart';
import 'glass_nav_bar.dart';

/// App bar translúcida estilo iOS — sem look Material 3.
///
/// Preferência: overlay em [Stack] (ver [GlassScaffold]). O slot
/// `Scaffold.appBar` ainda funciona como PreferredSize.
///
/// Contrato com o scaffold (espelha [GlassNavBar]):
/// - Inset de layout vem de [reservedTop].
/// - O [GlassScaffold] **empura** o body abaixo da cápsula — texto/gráfico
///   nunca ficam sob a barra (nem no scroll inicial).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  /// Padding vertical ao redor da cápsula (LTRB top+bottom).
  static const double verticalGap = 8;

  /// Altura da cápsula (sem status bar).
  static const double capsuleHeight = kToolbarHeight - 8;

  /// Espaço a reservar acima do conteúdo (status bar + gaps + cápsula).
  ///
  /// `viewPadding.top + verticalGap + capsuleHeight` =
  /// `viewPadding.top + kToolbarHeight`.
  static double reservedTop(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return top + kToolbarHeight;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + verticalGap);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final showLeading = leading != null ||
        (automaticallyImplyLeading && canPop);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            boxShadow: lumenGlassShadow(
              isDark: isDark,
              role: LumenGlassRole.appBar,
            ),
          ),
          child: LumenGlass(
            role: LumenGlassRole.appBar,
            cornerRadius: AppRadii.button,
            child: SizedBox(
              height: capsuleHeight,
              child: NavigationToolbar(
                leading: showLeading
                    ? (leading ??
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              CupertinoIcons.back,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ))
                    : null,
                middle: DefaultTextStyle(
                  style: Theme.of(context).appBarTheme.titleTextStyle ??
                      Theme.of(context).textTheme.titleLarge!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: title,
                ),
                trailing: actions == null || actions!.isEmpty
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                centerMiddle: false,
                middleSpacing: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Scaffold com app bar em overlay visual — body **abaixo** da cápsula.
///
/// Contrato:
/// - Body começa depois de [GlassAppBar.reservedTop] (Padding físico).
///   Texto/gráfico não ficam sob a barra.
/// - [MediaQuery.padding.top] do body zera o topo já consumido pelo Padding
///   (listas usam só [AppSpacing.screenV], sem somar reservedTop de novo).
/// - Teclado: `resizeToAvoidBottomInset: false` — só sheets reagem.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final bar = appBar;
    final media = MediaQuery.of(context);
    final clearTop = bar != null && extendBodyBehindAppBar
        ? GlassAppBar.reservedTop(context)
        : 0.0;

    final fab = floatingActionButton;
    return Scaffold(
      extendBody: true,
      // Teclado: só sheets (showLumenSheet) reagem — chrome empilhado não sobe.
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: fab == null
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: GlassNavBar.fabClearance(context),
              ),
              child: fab,
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.only(top: clearTop),
            child: MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(top: 0),
                viewPadding: media.viewPadding.copyWith(top: 0),
              ),
              child: body,
            ),
          ),
          if (bar != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: bar,
            ),
        ],
      ),
    );
  }
}
