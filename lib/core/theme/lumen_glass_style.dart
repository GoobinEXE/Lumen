import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'app_colors.dart';
import 'lumen_glass_level.dart';

/// Papéis de superfície liquid glass no Lumen (só iOS).
///
/// HIG: vidro na camada de navegação/controles ([navBar], [appBar], [sheet],
/// [chip]). Conteúdo ([surface]) é sólido via [GlassSurface] — o papel
/// permanece para sombra/compat.
enum LumenGlassRole {
  /// Cards de hub / painéis (conteúdo sólido; sem refração).
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

/// Liquid Glass é identidade visual só do iOS.
bool lumenUsesLiquidGlass() {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
}

/// Android (e demais): chrome e superfícies Material 3.
bool lumenUsesMaterialChrome() => !lumenUsesLiquidGlass();

/// Compat legado — preferir [lumenUsesMaterialChrome].
@Deprecated('Use lumenUsesMaterialChrome() / lumenUsesLiquidGlass()')
bool lumenGlassAndroidLite() {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

/// Paint direto ([LumenGlassLite]) sem BackdropFilter — só no caminho glass iOS.
///
/// Chips densos (check-in) usam lite; surfaces/sheets usam FakeGlass; chrome
/// iOS refrata.
bool lumenGlassPreferLitePaint(LumenGlassRole role) {
  if (lumenUsesMaterialChrome()) return false;
  return role == LumenGlassRole.chip;
}

/// Se este papel deve usar [FakeGlass] (sem refração). Só faz sentido no iOS.
///
/// Sheets e chips ficam em FakeGlass (lista/form longo). Chrome refrata em
/// [LumenGlassLevel.clear]/ [LumenGlassLevel.solid] força FakeGlass.
bool lumenGlassUseFake({
  required BuildContext context,
  required LumenGlassRole role,
  bool forceLite = false,
  LumenGlassLevel? level,
}) {
  if (lumenUsesMaterialChrome()) return true;
  final resolved = level ?? LumenGlassScope.levelOf(context);
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return debugLumenForceFakeGlass ||
      forceLite ||
      reduceMotion ||
      resolved == LumenGlassLevel.solid ||
      role == LumenGlassRole.chip ||
      role == LumenGlassRole.surface ||
      role == LumenGlassRole.sheet;
}

/// Borda reforçada no chrome quando o nível pede contraste.
bool lumenGlassNeedsContrastBorder(LumenGlassLevel level) {
  return level == LumenGlassLevel.tinted || level == LumenGlassLevel.solid;
}

double lumenGlassRadius(LumenGlassRole role, {double? override}) {
  return override ??
      switch (role) {
        LumenGlassRole.navBar => 24.5,
        LumenGlassRole.appBar => 22,
        LumenGlassRole.sheet => 36,
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
  LumenGlassLevel? level,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final resolved = level ?? LumenGlassScope.levelOf(context);
  final useFake = lumenGlassUseFake(
    context: context,
    role: role,
    forceLite: forceLite,
    level: resolved,
  );
  final preferLite = lumenGlassPreferLitePaint(role);
  final reduceMotion = MediaQuery.disableAnimationsOf(context);

  final clearAlpha = switch (role) {
    LumenGlassRole.navBar => isDark ? 0.10 : 0.07,
    LumenGlassRole.appBar => isDark ? 0.16 : 0.12,
    LumenGlassRole.sheet => isDark ? 0.94 : 0.97,
    LumenGlassRole.chip => isDark ? 0.20 : 0.16,
    LumenGlassRole.surface => isDark ? 0.16 : 0.12,
  };
  final tintedAlpha = switch (role) {
    LumenGlassRole.navBar => isDark ? 0.28 : 0.22,
    LumenGlassRole.appBar => isDark ? 0.34 : 0.28,
    LumenGlassRole.sheet => isDark ? 0.96 : 0.98,
    LumenGlassRole.chip => isDark ? 0.32 : 0.26,
    LumenGlassRole.surface => isDark ? 0.30 : 0.24,
  };
  final solidAlpha = switch (role) {
    LumenGlassRole.sheet => isDark ? 0.98 : 1.0,
    LumenGlassRole.chip => isDark ? 0.88 : 0.92,
    _ => isDark ? 0.92 : 0.94,
  };
  final baseAlpha = switch (resolved) {
    LumenGlassLevel.clear => clearAlpha,
    LumenGlassLevel.tinted => tintedAlpha,
    LumenGlassLevel.solid => solidAlpha,
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
      ? (resolved == LumenGlassLevel.solid ? 4.0 : 8.0)
      : switch (role) {
          LumenGlassRole.navBar => resolved == LumenGlassLevel.tinted ? 20.0 : 16.0,
          LumenGlassRole.appBar => resolved == LumenGlassLevel.tinted ? 26.0 : 22.0,
          LumenGlassRole.sheet => 26.0,
          LumenGlassRole.surface => 18.0,
          LumenGlassRole.chip => 10.0,
        };

  final blur = (preferLite || reduceMotion || resolved == LumenGlassLevel.solid)
      ? 0.0
      : useFake
          ? switch (role) {
              LumenGlassRole.chip => 6.0,
              LumenGlassRole.navBar => 12.0,
              LumenGlassRole.sheet => 24.0,
              _ => 10.0,
            }
          : switch (role) {
              LumenGlassRole.navBar => 10.0,
              LumenGlassRole.appBar => 8.0,
              LumenGlassRole.sheet => 20.0,
              LumenGlassRole.surface => 6.0,
              LumenGlassRole.chip => 4.0,
            };

  return LiquidGlassSettings(
    glassColor: glassColor,
    thickness: thickness,
    blur: blur,
    chromaticAberration:
        useFake || resolved != LumenGlassLevel.clear ? 0 : 0.008,
    lightIntensity: role == LumenGlassRole.chip ? 0.35 : 0.55,
    ambientStrength: isDark ? 0.12 : 0.08,
    refractiveIndex: useFake ? 1.0 : (resolved == LumenGlassLevel.tinted ? 1.12 : 1.18),
    saturation: resolved == LumenGlassLevel.tinted ? 1.08 : 1.15,
  );
}

/// Paint lite iOS (chips densos): tokens do FakeGlass, sem BackdropFilter.
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
    final rawAspect = bounds.size.aspectRatio;
    final aspect = rawAspect.isNaN || rawAspect == 0 ? 1.0 : rawAspect;
    final aspectAdjustment = 1 - 1 / aspect;
    final alignmentWithShortestSide = (aspect < 1 ? y : x).abs();
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
    final level = LumenGlassScope.levelOf(context);
    final settings = lumenGlassSettings(
      context: context,
      role: role,
      tint: tint,
      forceLite: forceLite,
      level: level,
    );
    final shape = lumenGlassShape(role, cornerRadius: cornerRadius);
    final fake = lumenGlassUseFake(
      context: context,
      role: role,
      forceLite: forceLite,
      level: level,
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
  final blurRadius = role == LumenGlassRole.chip ? 10.0 : 20.0;
  return [
    BoxShadow(
      color: (shadowColor ?? (isDark ? Colors.black : AppColors.shadow))
          .withValues(alpha: alpha),
      blurRadius: blurRadius,
      offset: Offset(0, role == LumenGlassRole.chip ? 3 : 6),
    ),
  ];
}
