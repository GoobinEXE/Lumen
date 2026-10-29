import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'lumen_glass_style.dart';

/// Tema Lumen — iOS: engine Material invisível sob Liquid Glass;
/// Android: Material 3 visível (chrome, cards, ripple, NavigationBar).
class AppTheme {
  static const _cupertinoTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
    },
  );

  static const _materialTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
    },
  );

  static bool get _materialChrome => lumenUsesMaterialChrome();

  static ButtonStyle _elevatedStyle({
    required Color background,
    required Color foreground,
    required bool materialChrome,
  }) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return background.withValues(alpha: 0.4);
        }
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return foreground.withValues(alpha: 0.7);
        }
        return foreground;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.white.withValues(alpha: 0.14);
        }
        return null;
      }),
      elevation: WidgetStatePropertyAll(materialChrome ? 1.0 : 0.0),
      shadowColor: materialChrome
          ? null
          : const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: materialChrome ? null : NoSplash.splashFactory,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 56)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            materialChrome ? AppRadii.buttonMaterial : AppRadii.button,
          ),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  static ButtonStyle _outlinedStyle({
    required Color foreground,
    required Color border,
    required bool materialChrome,
  }) {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return foreground.withValues(alpha: 0.4);
        }
        return foreground;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final alpha = states.contains(WidgetState.disabled) ? 0.3 : 1.0;
        return BorderSide(color: border.withValues(alpha: alpha));
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return foreground.withValues(alpha: 0.1);
        }
        return null;
      }),
      splashFactory: materialChrome ? null : NoSplash.splashFactory,
      elevation: const WidgetStatePropertyAll(0),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            materialChrome ? AppRadii.buttonMaterial : AppRadii.button,
          ),
        ),
      ),
    );
  }

  static ButtonStyle _textStyle({
    required Color foreground,
    required bool materialChrome,
  }) {
    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return foreground.withValues(alpha: 0.4);
        }
        return foreground;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return foreground.withValues(alpha: 0.1);
        }
        return null;
      }),
      splashFactory: materialChrome ? null : NoSplash.splashFactory,
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
    );
  }

  static TextTheme _textTheme({
    required Color primary,
    required Color muted,
  }) {
    return TextTheme(
      displaySmall: TextStyle(
        color: primary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.22,
        letterSpacing: -0.6,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.4,
      ),
      headlineSmall: TextStyle(
        color: primary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.32,
        letterSpacing: -0.35,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: -0.1,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: TextStyle(
        color: primary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: muted,
        fontSize: 15,
        height: 1.47,
      ),
      bodySmall: TextStyle(
        color: muted,
        fontSize: 13,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: primary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      labelMedium: TextStyle(
        color: muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: muted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static ColorScheme _lightScheme({required bool materialChrome}) {
    if (!materialChrome) {
      return const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySoft,
        secondary: AppColors.accent,
        surface: AppColors.backgroundLight,
        onSurface: AppColors.textDark,
        onSurfaceVariant: AppColors.textMuted,
        error: AppColors.danger,
      );
    }
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      error: AppColors.danger,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.textDark,
      onSurfaceVariant: AppColors.textMuted,
    ).copyWith(
      primaryContainer: AppColors.primarySoft,
      secondaryContainer: AppColors.accentSoft,
      surfaceContainerLowest: AppColors.backgroundLight,
      surfaceContainerLow: AppColors.cardLight,
      surfaceContainer: AppColors.surfaceContainerLight,
      surfaceContainerHigh: AppColors.surfaceContainerHighLight,
      surfaceContainerHighest: AppColors.surfaceContainerHighestLight,
    );
  }

  static ColorScheme _darkScheme({required bool materialChrome}) {
    if (!materialChrome) {
      return ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primary.withValues(alpha: 0.35),
        secondary: AppColors.accent,
        secondaryContainer: AppColors.accent.withValues(alpha: 0.25),
        surface: AppColors.backgroundDark,
        onSurface: AppColors.textLight,
        onSurfaceVariant: AppColors.textMutedDark,
        error: AppColors.danger,
      );
    }
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      error: AppColors.danger,
      surface: AppColors.backgroundDark,
      onSurface: AppColors.textLight,
      onSurfaceVariant: AppColors.textMutedDark,
    ).copyWith(
      primaryContainer: AppColors.primary.withValues(alpha: 0.35),
      secondaryContainer: AppColors.accent.withValues(alpha: 0.25),
      surfaceContainerLowest: AppColors.backgroundDark,
      surfaceContainerLow: AppColors.cardDark,
      surfaceContainer: AppColors.surfaceContainerDark,
      surfaceContainerHigh: AppColors.surfaceContainerHighDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
    );
  }

  static ThemeData get lightTheme => themeFor(
        brightness: Brightness.light,
        materialChrome: _materialChrome,
      );

  static ThemeData get darkTheme => themeFor(
        brightness: Brightness.dark,
        materialChrome: _materialChrome,
      );

  static ThemeData iosEngineTheme({required Brightness brightness}) =>
      themeFor(brightness: brightness, materialChrome: false);

  static ThemeData androidTheme({required Brightness brightness}) =>
      themeFor(brightness: brightness, materialChrome: true);

  static ThemeData themeFor({
    required Brightness brightness,
    required bool materialChrome,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _textTheme(
      primary: isDark ? AppColors.textLight : AppColors.textDark,
      muted: isDark ? AppColors.textMutedDark : AppColors.textMuted,
    );
    final scheme = isDark
        ? _darkScheme(materialChrome: materialChrome)
        : _lightScheme(materialChrome: materialChrome);
    final scaffold = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      splashFactory:
          materialChrome ? InkSparkle.splashFactory : NoSplash.splashFactory,
      highlightColor:
          materialChrome ? null : Colors.transparent,
      splashColor: materialChrome ? null : Colors.transparent,
      hoverColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      focusColor: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      cupertinoOverrideTheme: CupertinoThemeData(
        primaryColor: AppColors.primary,
        brightness: brightness,
      ),
      colorScheme: scheme,
      pageTransitionsTheme:
          materialChrome ? _materialTransitions : _cupertinoTransitions,
      scaffoldBackgroundColor: scaffold,
      dividerColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
        thickness: 0.5,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: materialChrome ? 2 : 0,
        backgroundColor: materialChrome
            ? scheme.inverseSurface
            : AppColors.cardDark.withValues(alpha: isDark ? 0.94 : 0.92),
        contentTextStyle: TextStyle(
          color: materialChrome ? scheme.onInverseSurface : AppColors.textLight,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            materialChrome ? AppRadii.buttonMaterial : AppRadii.button,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: materialChrome
            ? scheme.surfaceContainerHighest
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04)),
        selectedColor: materialChrome
            ? scheme.secondaryContainer
            : (isDark
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.primarySoft),
        labelStyle: TextStyle(
          color: isDark ? AppColors.textLight : AppColors.textDark,
          fontSize: 13,
        ),
        secondaryLabelStyle: TextStyle(
          color: isDark ? AppColors.textLight : AppColors.textDark,
          fontSize: 13,
        ),
        side: BorderSide.none,
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: materialChrome
            ? scheme.surfaceContainerLow
            : Colors.transparent,
        elevation: materialChrome ? 0 : 0,
        shadowColor: materialChrome ? null : Colors.transparent,
        surfaceTintColor:
            materialChrome ? scheme.surfaceTint : Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: materialChrome ? scheme.surface : Colors.transparent,
        surfaceTintColor:
            materialChrome ? scheme.surfaceTint : Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: materialChrome ? 1 : 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textLight : AppColors.textDark,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: isDark
            ? AppColors.primary.withValues(alpha: 0.28)
            : AppColors.primarySoft,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedStyle(
          background: AppColors.primary,
          foreground: Colors.white,
          materialChrome: materialChrome,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _elevatedStyle(
          background: AppColors.primary,
          foreground: Colors.white,
          materialChrome: materialChrome,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedStyle(
          foreground: AppColors.primary,
          border: AppColors.primary.withValues(alpha: 0.45),
          materialChrome: materialChrome,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textStyle(
          foreground: AppColors.primary,
          materialChrome: materialChrome,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: materialChrome ? 3 : 0,
        focusElevation: materialChrome ? 4 : 0,
        hoverElevation: materialChrome ? 4 : 0,
        highlightElevation: materialChrome ? 6 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            materialChrome ? 16 : AppRadii.button,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: materialChrome
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : (isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.55)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(
            color: materialChrome
                ? scheme.outlineVariant
                : (isDark
                    ? AppColors.cardBorderDark
                    : AppColors.glassBorderLight.withValues(alpha: 0.8)),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(
            color: materialChrome
                ? scheme.outlineVariant
                : (isDark
                    ? AppColors.cardBorderDark
                    : AppColors.glassBorderLight.withValues(alpha: 0.8)),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
        ),
        hintStyle: TextStyle(
          color: (isDark ? AppColors.textMutedDark : AppColors.textMuted)
              .withValues(alpha: 0.7),
        ),
        errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: materialChrome
            ? scheme.surfaceContainerHigh
            : (isDark
                ? AppColors.cardDark.withValues(alpha: 0.94)
                : AppColors.cardLight.withValues(alpha: 0.92)),
        elevation: materialChrome ? 3 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            materialChrome ? scheme.surfaceContainerLow : Colors.transparent,
        elevation: materialChrome ? 1 : 0,
        modalBackgroundColor:
            materialChrome ? scheme.surfaceContainerLow : Colors.transparent,
        surfaceTintColor:
            materialChrome ? scheme.surfaceTint : Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),
      textTheme: textTheme,
    );
  }
}
