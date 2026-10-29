/// Tokens de espaçamento e raio (compartilhados iOS glass / Android M3).
class AppSpacing {
  AppSpacing._();

  /// Altura dos ícones e rótulos, no tamanho da barra nativa iOS.
  /// O indicador de Home entra à parte, lido do aparelho.
  static const double navBar = 49;

  /// Folga interna da lente deslizante na [GlassNavBar] (iOS).
  static const double navLensInset = 4;
  static const double screenH = 20;
  static const double screenV = 16;
  static const double sheetH = 20;
  static const double sheetTop = 12;
  static const double sheetBottom = 16;
  static const double card = 16;
  static const double section = 24;
}

class AppRadii {
  AppRadii._();

  static const double card = 24;
  /// Pill iOS / Liquid Glass.
  static const double button = 28;
  /// Material 3 filled / elevated (shape medium).
  static const double buttonMaterial = 12;
  static const double input = 18;
  static const double chip = 999;
  static const double pill = 999;
  static const double sheet = 36;
  static const double handle = 2;
}

class AppSheetHandle {
  AppSheetHandle._();

  static const double width = 36;
  static const double height = 4;
}
