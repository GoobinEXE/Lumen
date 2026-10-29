import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/lumen_glass_style.dart';

/// Destino de uma aba na [GlassNavBar].
class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.hint,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Hint de acessibilidade (ex.: "Abre a aba Dia").
  final String? hint;
}

/// Dock do shell — Liquid Glass no iOS; [NavigationBar] Material 3 no Android.
///
/// Contrato com o shell:
/// - iOS: [PageView] full-bleed atrás da cápsula; inset via [reservedBottom].
/// - Android: barra Material na borda inferior (sem cápsula flutuante).
/// - [position] fracionário (0..n−1) acompanha o swipe.
///
/// Haptic da troca de aba fica no shell ([LumenShell]).
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.destinations,
    required this.position,
    required this.onSelected,
  });

  final List<GlassNavDestination> destinations;
  final double position;
  final ValueChanged<int> onSelected;

  static const double horizontalInset = 20;
  static const double bottomGap = 10;
  static const double contentGap = 10;
  static const double barHeight = AppSpacing.navBar;
  static const double materialBarHeight = 72;
  static const Key lensKey = Key('nav-lens');

  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
    if (lumenUsesMaterialChrome()) {
      return materialBarHeight * scale;
    }
    return barHeight * scale;
  }

  /// Espaço a reservar sob o conteúdo.
  ///
  /// iOS: home indicator + gap + cápsula (overlay full-bleed).
  /// Android: o [Scaffold.bottomNavigationBar] já empurra o body — só folga
  /// de scroll (`contentGap`).
  static double reservedBottom(BuildContext context) {
    if (lumenUsesMaterialChrome()) {
      return contentGap;
    }
    final indicator = MediaQuery.viewPaddingOf(context).bottom;
    return indicator + bottomGap + heightFor(context) + contentGap;
  }

  /// Folga extra sob FABs.
  ///
  /// iOS: cápsula overlay — o [Scaffold] da página só limpa o home indicator.
  /// Android: body já fica acima da [NavigationBar] — zero.
  static double fabClearance(BuildContext context) {
    if (lumenUsesMaterialChrome()) {
      return 0;
    }
    return bottomGap + heightFor(context) + contentGap;
  }

  /// Inset horizontal da dock no shell (0 no Material edge-to-edge).
  static double shellHorizontalInset() {
    return lumenUsesMaterialChrome() ? 0 : horizontalInset;
  }

  /// Gap sob a dock até o home indicator (0 no Material).
  static double shellBottomGap() {
    return lumenUsesMaterialChrome() ? 0 : bottomGap;
  }

  @override
  Widget build(BuildContext context) {
    assert(destinations.length >= 2, 'GlassNavBar precisa de ao menos 2 abas');
    final count = destinations.length;
    final selected = position.round().clamp(0, count - 1);

    if (lumenUsesMaterialChrome()) {
      return NavigationBar(
        height: heightFor(context),
        selectedIndex: selected,
        onDestinationSelected: onSelected,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
              tooltip: destination.hint,
            ),
        ],
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = heightFor(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final useFake = lumenGlassUseFake(
      context: context,
      role: LumenGlassRole.navBar,
    );
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 220);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (!width.isFinite || width <= 0) {
            return const SizedBox.shrink();
          }
          final slot = width / count;
          final lensPad = AppSpacing.navLensInset;
          final lensW = (slot - lensPad * 2).clamp(0.0, width);
          final lensH = (height - lensPad * 2).clamp(0.0, height);
          final lensLeft = position.clamp(0, count - 1) * slot + lensPad;

          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : AppColors.shadow)
                      .withValues(alpha: isDark ? 0.22 : 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: _NavDockChrome(
              useFake: useFake,
              isDark: isDark,
              height: height,
              lensLeft: lensLeft,
              lensWidth: lensW,
              lensHeight: lensH,
              child: Row(
                children: [
                  for (var i = 0; i < count; i++)
                    _NavSlot(
                      destination: destinations[i],
                      selected: i == selected,
                      duration: duration,
                      onTap: () => onSelected(i),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Cápsula + indicador. O chrome de vidro fica atrás; a [child] (itens) por cima.
class _NavDockChrome extends StatelessWidget {
  const _NavDockChrome({
    required this.useFake,
    required this.isDark,
    required this.height,
    required this.lensLeft,
    required this.lensWidth,
    required this.lensHeight,
    required this.child,
  });

  final bool useFake;
  final bool isDark;
  final double height;
  final double lensLeft;
  final double lensWidth;
  final double lensHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = height / 2;
    final lensRadius = lensHeight / 2;
    final settings = lumenGlassSettings(
      context: context,
      role: LumenGlassRole.navBar,
    );

    final indicator = Positioned(
      key: GlassNavBar.lensKey,
      left: lensLeft,
      top: (height - lensHeight) / 2,
      width: lensWidth,
      height: lensHeight,
      child: useFake
          ? DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(lensRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.14 : 0.38),
                    Colors.white.withValues(alpha: isDark ? 0.06 : 0.16),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.55),
                ),
              ),
            )
          : LiquidGlass.grouped(
              shape: LiquidRoundedSuperellipse(borderRadius: lensRadius),
              child: const SizedBox.expand(),
            ),
    );

    final rim = Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.42),
              width: 0.75,
            ),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );

    final items = Positioned.fill(child: child);
    final shape = LiquidRoundedSuperellipse(borderRadius: radius);
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [indicator, rim, items],
    );

    if (useFake) {
      // FakeGlass com blur moderado (1 cápsula). Chips/surfaces densos
      // ficam em LumenGlassLite — ver lumenGlassPreferLitePaint.
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: FakeGlass(
          settings: settings,
          shape: shape,
          child: stack,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: LiquidGlassLayer(
        settings: settings,
        child: LiquidGlassBlendGroup(
          blend: 18,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GlassGlow(
                  glowColor: Colors.white.withValues(alpha: 0.16),
                  glowRadius: 0.65,
                  child: LiquidGlass.grouped(
                    shape: LiquidRoundedSuperellipse(borderRadius: radius),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              indicator,
              rim,
              items,
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.destination,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = AppColors.mutedText(isDark);
    final active = AppColors.primary;
    final idle = muted;
    final labelStyle =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: true,
        label: destination.label,
        hint: destination.hint,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ExcludeSemantics(
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSlide(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    offset: selected ? const Offset(0, -0.04) : Offset.zero,
                    child: AnimatedScale(
                      scale: selected ? 1.08 : 1.0,
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      child: _NavGlyph(
                        icon: selected
                            ? destination.selectedIcon
                            : destination.icon,
                        color: selected ? active : idle,
                        duration: duration,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: Curves.easeOut,
                    style: labelStyle.copyWith(
                      fontSize: 10,
                      letterSpacing: selected ? -0.1 : 0,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? active : idle,
                    ),
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavGlyph extends ImplicitlyAnimatedWidget {
  const _NavGlyph({
    required this.icon,
    required this.color,
    required super.duration,
  }) : super(curve: Curves.easeOut);

  final IconData icon;
  final Color color;

  @override
  ImplicitlyAnimatedWidgetState<_NavGlyph> createState() => _NavGlyphState();
}

class _NavGlyphState extends AnimatedWidgetBaseState<_NavGlyph> {
  ColorTween? _color;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _color =
        visitor(
              _color,
              widget.color,
              (dynamic value) => ColorTween(begin: value as Color),
            )
            as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    return Icon(widget.icon, size: 22, color: _color?.evaluate(animation));
  }
}
