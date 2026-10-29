import 'package:flutter/material.dart';

/// Paleta Lumen — Organic Biophilic (tokens compartilhados iOS glass / Android M3):
/// - Fundo sage-stone / carvão quente, sem lilás
/// - Cor viva só em CTAs e no assistente Des-Trava
/// - Accent sage/terra para ênfase secundária
class AppColors {
  static const Color primary = Color(0xFF1FAF8A);
  static const Color primaryLight = Color(0xFF3DDC97);
  static const Color primarySoft = Color(0xFFE3F4EE);

  static const Color accent = Color(0xFF5F7A6C);
  static const Color accentSoft = Color(0xFFE8EEEA);

  static const Color unstuck = Color(0xFFFF8A5C);
  static const Color unstuckSoft = Color(0xFFFFF0EA);

  static const Color peak = Color(0xFFE6B325);

  static const Color shadow = Color(0xFF5C635E);

  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFF4E5);
  static const Color danger = Color(0xFFD9534F);
  static const Color dangerSoft = Color(0xFFFDECEA);
  static const Color success = Color(0xFF2E856E);
  static const Color successSoft = Color(0xFFE3F4EE);

  static const Color glassFillLight = Color(0xF0FFFFFF);
  static const Color glassFillDark = Color(0xD91C211E);
  static const Color glassBorderLight = Color(0xFFD8E0DA);
  static const Color glassBorderDark = Color(0x14FFFFFF);
  static const double glassBlurSigma = 20.0;

  static const Color focusStateGood = Color(0xFF2E856E);
  static const Color focusStateHyper = Color(0xFFD97706);
  static const Color focusStateScattered = Color(0xFFE08E45);
  static const Color focusStateParalyzed = Color(0xFFD9534F);

  static const Color sleepDeep = Color(0xFF23395B);
  static const Color sleepRem = Color(0xFF53599A);
  static const Color sleepLight = Color(0xFF80A1D4);
  static const Color sleepAwake = Color(0xFFE5989B);

  static const Color backgroundLight = Color(0xFFF2F5F3);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFD8E0DA);
  static const Color textDark = Color(0xFF1A1F1C);
  static const Color textMuted = Color(0xFF5C635E);

  static const Color backgroundDark = Color(0xFF141816);
  static const Color cardDark = Color(0xFF1C211E);
  static const Color cardBorderDark = Color(0x14FFFFFF);
  static const Color textLight = Color(0xFFF2F5F3);
  static const Color textMutedDark = Color(0xFF9AA39C);

  static const Color surfaceContainerLight = Color(0xFFE8EEEA);
  static const Color surfaceContainerHighLight = Color(0xFFDEE6E1);
  static const Color surfaceContainerHighestLight = Color(0xFFD4DCD7);
  static const Color surfaceContainerDark = Color(0xFF222824);
  static const Color surfaceContainerHighDark = Color(0xFF282E2A);
  static const Color surfaceContainerHighestDark = Color(0xFF2E3430);

  static Color glassFill(bool isDark) =>
      isDark ? glassFillDark : glassFillLight;

  static Color glassBorder(bool isDark) =>
      isDark ? glassBorderDark : glassBorderLight;

  static Color mutedText(bool isDark) => isDark ? textMutedDark : textMuted;
}
