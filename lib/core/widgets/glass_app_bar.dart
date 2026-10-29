import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/lumen_glass_level.dart';
import '../theme/lumen_glass_style.dart';
import 'glass_nav_bar.dart';

/// App bar: cápsula Liquid Glass no iOS; [AppBar] Material 3 no Android.
///
/// Preferência iOS: overlay em [Stack] (ver [GlassScaffold]). O slot
/// `Scaffold.appBar` ainda funciona como PreferredSize.
///
/// Contrato com o scaffold (espelha [GlassNavBar]):
/// - Inset de layout vem de [reservedTop] (= status + [preferredSize]).
/// - No iOS o [GlassScaffold] **empura** o body abaixo da cápsula.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  /// Título na barra. `null` = só leading/actions (ex.: Perfil).
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  /// Padding vertical ao redor da cápsula (LTRB top+bottom).
  static const double verticalGap = 8;

  /// Altura da cápsula (sem status bar).
  static const double capsuleHeight = kToolbarHeight - 8;

  /// Espaço a reservar acima do conteúdo (status + altura preferida da barra).
  static double reservedTop(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    final bar = lumenUsesMaterialChrome()
        ? kToolbarHeight
        : kToolbarHeight + verticalGap;
    return top + bar;
  }

  @override
  Size get preferredSize => lumenUsesMaterialChrome()
      ? const Size.fromHeight(kToolbarHeight)
      : const Size.fromHeight(kToolbarHeight + verticalGap);

  @override
  Widget build(BuildContext context) {
    if (lumenUsesMaterialChrome()) {
      return AppBar(
        title: title,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final level = LumenGlassScope.levelOf(context);
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final showLeading = leading != null ||
        (automaticallyImplyLeading && canPop);
    final titleWidget = title;
    final contrast = lumenGlassNeedsContrastBorder(level);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: contrast
                ? Border.all(
                    color: AppColors.glassBorder(isDark),
                    width: 1,
                  )
                : null,
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
                middle: titleWidget == null
                    ? null
                    : DefaultTextStyle(
                        style: Theme.of(context).appBarTheme.titleTextStyle ??
                            Theme.of(context).textTheme.titleLarge!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: titleWidget,
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

/// Scaffold com app bar — overlay glass no iOS; [AppBar] no slot Material.
///
/// Contrato iOS:
/// - Body começa depois de [GlassAppBar.reservedTop] (Padding físico).
/// - [MediaQuery.padding.top] do body zera o topo já consumido.
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
    final fab = floatingActionButton;

    if (lumenUsesMaterialChrome()) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: bar,
        floatingActionButton: fab == null
            ? null
            : Padding(
                padding: EdgeInsets.only(
                  bottom: GlassNavBar.fabClearance(context),
                ),
                child: fab,
              ),
        body: body,
      );
    }

    final media = MediaQuery.of(context);
    final clearTop = bar != null && extendBodyBehindAppBar
        ? GlassAppBar.reservedTop(context)
        : 0.0;

    return Scaffold(
      extendBody: true,
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
          if (bar != null) ...[
            Positioned(
              top: clearTop - 12,
              left: 0,
              right: 0,
              height: 12,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).scaffoldBackgroundColor.withValues(
                              alpha: 0.55,
                            ),
                        Theme.of(context).scaffoldBackgroundColor.withValues(
                              alpha: 0,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: bar,
            ),
          ],
        ],
      ),
    );
  }
}
