import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'app_colors.dart';

/// Papéis de superfície liquid glass no Lumen.
enum LumenGlassRole {
  /// Cards de hub / painéis.
  surface,

  /// Bottom sheets e modais.
  sheet,

  /// Barra inferior do shell.
  navBar,

  /// App bar flutuante.
  appBar,

  /// Pills / chips (sempre leve).
  chip,
}

/// Força FakeGlass em testes / diagnóstico (sem shader contínuo).
bool debugLumenForceFakeGlass = false;

/// Android: tokens/API do caminho “lite” (sem refração real no chrome).
///
/// Blur de BackdropFilter volta só em nav/app bar/sheet — poucas camadas.
/// Cards e chips densos ficam em [LumenGlassLite] (ver
/// [lumenGlassPreferLitePaint]).
bool lumenGlassAndroidLite() {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

/// Paint direto ([LumenGlassLite]) sem BackdropFilter.
///
/// - Chips: sempre (check-in / wraps densos) nas duas plataformas.
/// - Android surfaces: lite (N cards no scroll).
/// - Android nav/app bar/sheet: FakeGlass com blur moderado (1–2 camadas).
/// - iOS chrome: refração; surfaces/sheets: FakeGlass com blur.
bool lumenGlassPreferLitePaint(LumenGlassRole role) {
  if (role == LumenGlassRole.chip) return true;
  if (lumenGlassAndroidLite()) {
    return role == LumenGlassRole.surface;
  }
  return false;
}

/// Se este papel deve usar [FakeGlass] (sem refração).
///
/// Cards/painéis ([LumenGlassRole.surface]), chips e sheets ficam em
/// FakeGlass: o `liquid_glass_renderer` real chama `toImageSync` com o matte
/// transform da árvore; em lista scrollável / PageView / form longo isso vira
/// Infinity/NaN ou texto ilegível.
///
/// No Android o chrome (nav, app bar) também fica em FakeGlass: a refração
/// real recomposita a cada frame do [PageView] e congela a troca de aba.
/// No iOS a refração continua no chrome.
bool lumenGlassUseFake({
  required BuildContext context,
  required LumenGlassRole role,
  bool forceLite = false,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final androidChrome = lumenGlassAndroidLite() &&
      (role == LumenGlassRole.navBar || role == LumenGlassRole.appBar);
  return debugLumenForceFakeGlass ||
      forceLite ||
      reduceMotion ||
      androidChrome ||
      role == LumenGlassRole.chip ||
      role == LumenGlassRole.surface ||
      role == LumenGlassRole.sheet;
}

double lumenGlassRadius(LumenGlassRole role, {double? override}) {
  return override ??
      switch (role) {
        LumenGlassRole.navBar => 24.5,
        LumenGlassRole.appBar => 22,
        LumenGlassRole.sheet => 32,
        LumenGlassRole.chip => 16,
        LumenGlassRole.surface => 20,
      };
}

LiquidShape lumenGlassShape(LumenGlassRole role, {double? cornerRadius}) {
  return LiquidRoundedSuperellipse(
    borderRadius: lumenGlassRadius(role, override: cornerRadius),
  );
}

/// Settings compartilhados `liquid_glass_renderer` — tint baixo (não JPEG).
LiquidGlassSettings lumenGlassSettings({
  required BuildContext context,
  required LumenGlassRole role,
  Color? tint,
  bool forceLite = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final useFake = lumenGlassUseFake(
    context: context,
    role: role,
    forceLite: forceLite,
  );
  final androidLite = lumenGlassAndroidLite();
  final preferLite = lumenGlassPreferLitePaint(role);
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  // iOS chrome: tint baixo (refração). Android: meio-termo translúcido
  // (sheet um pouco mais fechado para leitura de form).
  final baseAlpha = androidLite
      ? switch (role) {
          LumenGlassRole.navBar => isDark ? 0.40 : 0.46,
          LumenGlassRole.appBar => isDark ? 0.46 : 0.52,
          LumenGlassRole.sheet => isDark ? 0.76 : 0.80,
          LumenGlassRole.chip => isDark ? 0.28 : 0.34,
          LumenGlassRole.surface => isDark ? 0.36 : 0.42,
        }
      : switch (role) {
          LumenGlassRole.navBar => isDark ? 0.10 : 0.07,
          LumenGlassRole.appBar => isDark ? 0.16 : 0.12,
          LumenGlassRole.sheet => isDark ? 0.78 : 0.88,
          LumenGlassRole.chip => isDark ? 0.20 : 0.16,
          LumenGlassRole.surface => isDark ? 0.16 : 0.12,
        };

  var glassColor = (isDark ? const Color(0xFF2A2A32) : Colors.white)
      .withValues(alpha: baseAlpha);
  if (tint != null) {
    glassColor = Color.alphaBlend(
      tint.withValues(alpha: isDark ? 0.14 : 0.18),
      glassColor,
    );
  }

  final thickness = useFake
      ? 8.0
      : switch (role) {
          // Nav mais fina = mais transparente; app bar mantém peso.
          LumenGlassRole.navBar => 16.0,
          LumenGlassRole.appBar => 22.0,
          LumenGlassRole.sheet => 26.0,
          LumenGlassRole.surface => 18.0,
          LumenGlassRole.chip => 10.0,
        };

  // Blur só fora do paint lite (e com reduzir movimento = 0).
  // Android chrome/sheet: σ um pouco menor que iOS (1–2 BackdropFilters).
  final blur = (preferLite || reduceMotion)
      ? 0.0
      : androidLite
          ? switch (role) {
              LumenGlassRole.navBar => 10.0,
              LumenGlassRole.appBar => 8.0,
              LumenGlassRole.sheet => 10.0,
              LumenGlassRole.surface => 0.0,
              LumenGlassRole.chip => 0.0,
            }
          : useFake
              ? switch (role) {
                  LumenGlassRole.chip => 6.0,
                  LumenGlassRole.navBar => 12.0,
                  _ => 10.0,
                }
              : switch (role) {
                  LumenGlassRole.navBar => 10.0,
                  LumenGlassRole.appBar => 8.0,
                  LumenGlassRole.sheet => 10.0,
                  LumenGlassRole.surface => 6.0,
                  LumenGlassRole.chip => 4.0,
                };

  return LiquidGlassSettings(
    glassColor: glassColor,
    thickness: thickness,
    blur: blur,
    chromaticAberration: useFake ? 0 : 0.008,
    lightIntensity: role == LumenGlassRole.chip ? 0.35 : 0.55,
    ambientStrength: isDark ? 0.12 : 0.08,
    refractiveIndex: useFake ? 1.0 : 1.18,
    saturation: preferLite && androidLite ? 1.0 : 1.15,
  );
}

/// Vidro Android lite: mesmos tokens do FakeGlass, sem BackdropFilter.
class LumenGlassLite extends StatelessWidget {
  const LumenGlassLite({
    super.key,
    required this.settings,
    required this.shape,
    required this.child,
  });

  final LiquidGlassSettings settings;
  final LiquidShape shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: LumenGlassLitePainter(
        settings: settings,
        shape: shape,
      ),
      child: ClipPath(
        clipper: _LumenGlassShapeClipper(shape),
        child: child,
      ),
    );
  }
}

/// Painter público (testes) — cor + aro especular sem MaskFilter.blur.
///
/// Só [BlendMode.srcOver] com alpha: translucidez sem BackdropFilter.
/// multiply/screen/hardLight forçam cópia de backdrop no Impeller Android.
class LumenGlassLitePainter extends CustomPainter {
  const LumenGlassLitePainter({
    required this.settings,
    required this.shape,
  });

  final LiquidGlassSettings settings;
  final LiquidShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);
    _paintColor(canvas, path);
    _paintSpecular(canvas, path, rect);
  }

  void _paintColor(Canvas canvas, Path path) {
    final paint = Paint()
      ..color = settings.effectiveGlassColor
      ..blendMode = BlendMode.srcOver
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  void _paintSpecular(Canvas canvas, Path path, Rect bounds) {
    final lightIntensity = settings.effectiveLightIntensity.clamp(0.0, 1.0);
    final ambientStrength = settings.effectiveAmbientStrength.clamp(0.0, 1.0);
    final thicknessFactor =
        (settings.effectiveThickness / 5).clamp(0.0, 1.0);
    final alpha = Curves.easeOut.transform(lightIntensity);
    final color = Colors.white.withValues(alpha: alpha * thicknessFactor);
    final rad = settings.lightAngle;
    final x = math.cos(rad);
    final y = math.sin(rad);
    final squareBounds = Rect.fromCircle(
      center: bounds.center,
      radius: bounds.size.longestSide / 2,
    );
    final lightCoverage = uiLerp(.3, .5, lightIntensity);
    final aspectAdjustment = 1 - 1 / (bounds.size.aspectRatio == 0
        ? 1
        : bounds.size.aspectRatio);
    final alignmentWithShortestSide =
        (bounds.size.aspectRatio < 1 ? y : x).abs();
    final gradientScale =
        aspectAdjustment * (1 - alignmentWithShortestSide);
    final inset = uiLerp(0, .5, gradientScale.clamp(0.0, 1.0));
    final secondInset =
        uiLerp(lightCoverage, .5, gradientScale.clamp(0.0, 1.0));
    final shader = LinearGradient(
      colors: [
        color,
        color.withValues(alpha: ambientStrength),
        color.withValues(alpha: ambientStrength),
        color,
      ],
      stops: [inset, secondInset, 1 - secondInset, 1 - inset],
      begin: Alignment(x, y),
      end: Alignment(-x, -y),
    ).createShader(squareBounds);

    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = uiLerp(1, 2, lightIntensity)
      ..color = color.withValues(alpha: color.a * 0.3)
      ..blendMode = BlendMode.srcOver;
    canvas.drawPath(path, paint);
  }

  static double uiLerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant LumenGlassLitePainter oldDelegate) {
    return oldDelegate.settings != settings || oldDelegate.shape != shape;
  }
}

class _LumenGlassShapeClipper extends CustomClipper<Path> {
  const _LumenGlassShapeClipper(this.shape);

  final LiquidShape shape;

  @override
  Path getClip(Size size) => shape.getOuterPath(Offset.zero & size);

  @override
  bool shouldReclip(covariant _LumenGlassShapeClipper oldClipper) {
    return oldClipper.shape != shape;
  }
}

/// Envelope glass: [LiquidGlass.withOwnLayer], [FakeGlass] ou [LumenGlassLite].
class LumenGlass extends StatelessWidget {
  const LumenGlass({
    super.key,
    required this.role,
    required this.child,
    this.cornerRadius,
    this.tint,
    this.forceLite = false,
    this.interactive = false,
  });

  final LumenGlassRole role;
  final Widget child;
  final double? cornerRadius;
  final Color? tint;
  final bool forceLite;

  /// Envolve com [GlassGlow] (nav / CTAs).
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final settings = lumenGlassSettings(
      context: context,
      role: role,
      tint: tint,
      forceLite: forceLite,
    );
    final shape = lumenGlassShape(role, cornerRadius: cornerRadius);
    final fake = lumenGlassUseFake(
      context: context,
      role: role,
      forceLite: forceLite,
    );
    final content = interactive
        ? GlassGlow(
            glowColor: AppColors.primary.withValues(alpha: 0.28),
            glowRadius: 0.85,
            child: child,
          )
        : child;

    // Paint direto: chips (e surfaces Android) sem BackdropFilter.
    if (lumenGlassPreferLitePaint(role)) {
      return LumenGlassLite(
        settings: settings,
        shape: shape,
        child: content,
      );
    }

    // GlassGlow no toque; LiquidStretch (motor) fica fora do caminho quente —
    // springs impedem pumpAndSettle e custam GPU na nav.
    return LiquidGlass.withOwnLayer(
      settings: settings,
      fake: fake,
      shape: shape,
      child: content,
    );
  }
}

/// Sombra de contato suave (fora do shader).
List<BoxShadow> lumenGlassShadow({
  required bool isDark,
  Color? shadowColor,
  LumenGlassRole role = LumenGlassRole.surface,
}) {
  final alpha = switch (role) {
    LumenGlassRole.navBar => isDark ? 0.18 : 0.06,
    LumenGlassRole.sheet => isDark ? 0.32 : 0.12,
    LumenGlassRole.appBar => isDark ? 0.20 : 0.07,
    LumenGlassRole.chip => isDark ? 0.14 : 0.05,
    LumenGlassRole.surface => isDark ? 0.24 : 0.07,
  };
  final lite = lumenGlassAndroidLite();
  final blurRadius = lite
      ? (role == LumenGlassRole.chip ? 6.0 : 10.0)
      : (role == LumenGlassRole.chip ? 10.0 : 20.0);
  return [
    BoxShadow(
      color: (shadowColor ?? (isDark ? Colors.black : AppColors.shadow))
          .withValues(alpha: alpha),
      blurRadius: blurRadius,
      offset: Offset(0, role == LumenGlassRole.chip ? 3 : 6),
    ),
  ];
}
