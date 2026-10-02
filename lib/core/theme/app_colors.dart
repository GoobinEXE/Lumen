import 'package:flutter/material.dart';

/// Soft Liquid Glass — paleta para neurodivergência e TDAH:
/// - Fundo sólido (creme / preto suave), sem auras
/// - Cor viva só em CTAs e no assistente Des-Trava
/// - Alto contraste de texto sem ruído visual
class AppColors {
  // Primárias (teal mais vivo, ainda calmo)
  static const Color primary = Color(0xFF1FAF8A);
  static const Color primaryLight = Color(0xFF3DDC97);
  static const Color primarySoft = Color(0xFFE0F7EF);

  // Acento (lavanda levemente mais saturada)
  static const Color accent = Color(0xFF8B7BC8);
  static const Color accentSoft = Color(0xFFF0EDF9);

  // Destaque do assistente Des-Trava (coral — não alarme)
  static const Color unstuck = Color(0xFFFF8A5C);
  static const Color unstuckSoft = Color(0xFFFFF0EA);

  // Status semânticos (alinhados à paleta, sem Material puro)
  /// Pico da curva de eficácia (dourado da janela do remédio).
  static const Color peak = Color(0xFFE6B325);

  /// Sombra compartilhada dos cards do resumo.
  static const Color shadow = Color(0xFF6E6B7B);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFF4E5);
  static const Color danger = Color(0xFFD9534F);
  static const Color dangerSoft = Color(0xFFFDECEA);
  static const Color success = Color(0xFF2E856E);
  static const Color successSoft = Color(0xFFE0F7EF);

  // Glass tokens
  static const Color glassFillLight = Color(0xEBFFFFFF); // ~0.92 white
  static const Color glassFillDark = Color(0xD9212127); // card dark, mostly opaque
  static const Color glassBorderLight = Color(0xFFE8E4DF);
  static const Color glassBorderDark = Color(0x14FFFFFF); // ~0.08 white
  static const double glassBlurSigma = 20.0;

  // Estados Mentais / Emoções (semântica de dados — não mudar)
  static const Color focusStateGood = Color(0xFF2E856E);
  static const Color focusStateHyper = Color(0xFFD97706);
  static const Color focusStateScattered = Color(0xFFE08E45);
  static const Color focusStateParalyzed = Color(0xFFD9534F);

  // Sono
  static const Color sleepDeep = Color(0xFF23395B);
  static const Color sleepRem = Color(0xFF53599A);
  static const Color sleepLight = Color(0xFF80A1D4);
  static const Color sleepAwake = Color(0xFFE5989B);

  // Superfícies (claro) — creme sólido, cards brancos
  static const Color backgroundLight = Color(0xFFF6F1FF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE8E4DF);
  static const Color textDark = Color(0xFF1A1A1E);
  static const Color textMuted = Color(0xFF6B6560);

  // Superfícies (escuro) — carvão sólido, não #000
  static const Color backgroundDark = Color(0xFF16161A);
  static const Color cardDark = Color(0xFF212127);
  static const Color cardBorderDark = Color(0x14FFFFFF);
  static const Color textLight = Color(0xFFF4F1EC);
  static const Color textMutedDark = Color(0xFFA39E97);

  static Color glassFill(bool isDark) =>
      isDark ? glassFillDark : glassFillLight;

  static Color glassBorder(bool isDark) =>
      isDark ? glassBorderDark : glassBorderLight;

  static Color mutedText(bool isDark) => isDark ? textMutedDark : textMuted;
}
