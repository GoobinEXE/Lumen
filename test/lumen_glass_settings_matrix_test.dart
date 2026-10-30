import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/theme/lumen_glass_level.dart';
import 'package:noa/core/theme/lumen_glass_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BuildContext> pumpContext(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    LumenGlassLevel level = LumenGlassLevel.clear,
    bool reduceMotion = false,
  }) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeAnimationDuration: Duration.zero,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: LumenGlassScope(
            level: level,
            reduceTransparency: level == LumenGlassLevel.solid,
            child: Builder(
              builder: (context) {
                captured = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return captured;
  }

  test('raio do chrome e sombra do chip não seguem o card', () {
    expect(lumenGlassRadius(LumenGlassRole.navBar), 24.5);
    expect(lumenGlassRadius(LumenGlassRole.appBar), 22);
    expect(lumenGlassRadius(LumenGlassRole.sheet), 36);
    expect(lumenGlassRadius(LumenGlassRole.chip), 16);
    expect(lumenGlassRadius(LumenGlassRole.surface), 20);
    expect(lumenGlassRadius(LumenGlassRole.sheet, override: 12), 12);

    final chip = lumenGlassShadow(
      isDark: false,
      role: LumenGlassRole.chip,
    ).single;
    expect(chip.blurRadius, 10);
    expect(chip.offset, const Offset(0, 3));

    final nav = lumenGlassShadow(
      isDark: true,
      role: LumenGlassRole.navBar,
    ).single;
    expect(nav.blurRadius, 20);
    expect(nav.offset, const Offset(0, 6));
  });

  testWidgets(
    'iOS clear: nav e app bar refratam; sheet fica fosca; chip zera o blur',
    (tester) async {
      final context = await pumpContext(tester);

      final nav = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.navBar,
      );
      expect(
        lumenGlassUseFake(context: context, role: LumenGlassRole.navBar),
        isFalse,
      );
      expect(nav.thickness, 16);
      expect(nav.blur, 10);
      expect(nav.chromaticAberration, 0.008);
      expect(nav.refractiveIndex, 1.18);
      expect(nav.saturation, 1.15);
      expect(nav.lightIntensity, 0.55);
      expect(nav.ambientStrength, 0.08);
      expect(nav.glassColor.a, closeTo(0.07, 0.001));

      final bar = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.appBar,
      );
      expect(
        lumenGlassUseFake(context: context, role: LumenGlassRole.appBar),
        isFalse,
      );
      expect(bar.thickness, 22);
      expect(bar.blur, 8);
      expect(bar.chromaticAberration, 0.008);

      final sheet = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.sheet,
      );
      expect(
        lumenGlassUseFake(context: context, role: LumenGlassRole.sheet),
        isTrue,
      );
      expect(sheet.thickness, 8);
      expect(sheet.blur, 24);
      expect(sheet.chromaticAberration, 0);
      expect(sheet.refractiveIndex, 1);

      final chip = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.chip,
      );
      expect(lumenGlassPreferLitePaint(LumenGlassRole.chip), isTrue);
      expect(chip.blur, 0);
      expect(chip.thickness, 8);
      expect(chip.lightIntensity, 0.35);
      expect(chip.chromaticAberration, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'iOS tinted continua refratando, sem aberração e com índice menor',
    (tester) async {
      final context = await pumpContext(tester, level: LumenGlassLevel.tinted);

      expect(
        lumenGlassUseFake(context: context, role: LumenGlassRole.navBar),
        isFalse,
      );
      final nav = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.navBar,
      );
      expect(nav.thickness, 20);
      expect(nav.blur, 10);
      expect(nav.chromaticAberration, 0);
      expect(nav.refractiveIndex, 1.12);
      expect(nav.saturation, 1.08);
      expect(nav.glassColor.a, closeTo(0.22, 0.001));

      final bar = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.appBar,
      );
      expect(bar.thickness, 26);
      expect(bar.blur, 8);
      expect(bar.chromaticAberration, 0);
      expect(bar.refractiveIndex, 1.12);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'iOS solid zera blur e aberração e usa espessura 4',
    (tester) async {
      final context = await pumpContext(tester, level: LumenGlassLevel.solid);

      for (final role in [LumenGlassRole.navBar, LumenGlassRole.sheet]) {
        expect(lumenGlassUseFake(context: context, role: role), isTrue);
        final settings = lumenGlassSettings(context: context, role: role);
        expect(settings.blur, 0);
        expect(settings.thickness, 4);
        expect(settings.chromaticAberration, 0);
        expect(settings.refractiveIndex, 1);
      }

      final sheet = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.sheet,
      );
      expect(sheet.glassColor.a, closeTo(1, 0.001));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'iOS: reduzir movimento tira o blur da sheet que ainda é fosca',
    (tester) async {
      final still = await pumpContext(tester);
      expect(
        lumenGlassSettings(context: still, role: LumenGlassRole.sheet).blur,
        24,
      );

      final context = await pumpContext(tester, reduceMotion: true);
      expect(
        lumenGlassUseFake(context: context, role: LumenGlassRole.sheet),
        isTrue,
      );
      final sheet = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.sheet,
      );
      expect(sheet.blur, 0);
      expect(sheet.chromaticAberration, 0);
      expect(sheet.thickness, 8);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'iOS: forceLite e a flag de teste tiram a refração da nav',
    (tester) async {
      final context = await pumpContext(tester);
      final forced = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.navBar,
        forceLite: true,
      );
      expect(
        lumenGlassUseFake(
          context: context,
          role: LumenGlassRole.navBar,
          forceLite: true,
        ),
        isTrue,
      );
      expect(forced.thickness, 8);
      expect(forced.blur, 12);
      expect(forced.chromaticAberration, 0);
      expect(forced.refractiveIndex, 1);

      debugLumenForceFakeGlass = true;
      addTearDown(() => debugLumenForceFakeGlass = false);
      expect(
        lumenGlassUseFake(context: context, role: LumenGlassRole.navBar),
        isTrue,
      );
      final flagged = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.navBar,
      );
      expect(flagged.blur, 12);
      expect(flagged.chromaticAberration, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'iOS: tint só muda a cor; escuro sobe o alpha e o ambiente',
    (tester) async {
      final light = await pumpContext(tester);
      final plain = lumenGlassSettings(
        context: light,
        role: LumenGlassRole.navBar,
      );
      final tinted = lumenGlassSettings(
        context: light,
        role: LumenGlassRole.navBar,
        tint: const Color(0xFF1FAF8A),
      );
      expect(tinted.thickness, plain.thickness);
      expect(tinted.blur, plain.blur);
      expect(tinted.chromaticAberration, plain.chromaticAberration);
      expect(tinted.glassColor, isNot(plain.glassColor));

      final dark = await pumpContext(tester, brightness: Brightness.dark);
      final nav = lumenGlassSettings(
        context: dark,
        role: LumenGlassRole.navBar,
      );
      expect(nav.glassColor.a, closeTo(0.10, 0.001));
      expect(nav.ambientStrength, 0.12);
      expect(nav.blur, 10);
      expect(nav.chromaticAberration, 0.008);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Android não herda refração: nav blur 12, sheet 24, chip 6',
    (tester) async {
      final context = await pumpContext(tester);
      expect(lumenUsesMaterialChrome(), isTrue);
      expect(lumenGlassPreferLitePaint(LumenGlassRole.chip), isFalse);

      final nav = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.navBar,
      );
      expect(
        lumenGlassUseFake(context: context, role: LumenGlassRole.navBar),
        isTrue,
      );
      expect(nav.thickness, 8);
      expect(nav.blur, 12);
      expect(nav.chromaticAberration, 0);
      expect(nav.refractiveIndex, 1);
      expect(nav.glassColor.a, closeTo(0.07, 0.001));

      final sheet = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.sheet,
      );
      expect(sheet.blur, 24);
      expect(sheet.thickness, 8);

      final chip = lumenGlassSettings(
        context: context,
        role: LumenGlassRole.chip,
      );
      expect(chip.blur, 6);
      expect(chip.thickness, 8);
      expect(chip.lightIntensity, 0.35);

      final solid = await pumpContext(tester, level: LumenGlassLevel.solid);
      final solidNav = lumenGlassSettings(
        context: solid,
        role: LumenGlassRole.navBar,
      );
      expect(solidNav.blur, 0);
      expect(solidNav.thickness, 4);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'pintor lite não estoura em tamanho zero, faixa ou quadrado',
    (tester) async {
      final context = await pumpContext(tester);
      final painter = LumenGlassLitePainter(
        settings: lumenGlassSettings(
          context: context,
          role: LumenGlassRole.chip,
        ),
        shape: lumenGlassShape(LumenGlassRole.chip),
      );

      void paintAt(Size size) {
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), size);
        recorder.endRecording().dispose();
      }

      paintAt(Size.zero);
      paintAt(const Size(0, 48));
      paintAt(const Size(48, 0));
      paintAt(const Size(120, 36));
      paintAt(const Size(24, 80));
      paintAt(const Size(40, 40));

      expect(painter.shouldRepaint(painter), isFalse);
      expect(
        painter.shouldRepaint(
          LumenGlassLitePainter(
            settings: lumenGlassSettings(
              context: context,
              role: LumenGlassRole.navBar,
            ),
            shape: painter.shape,
          ),
        ),
        isTrue,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
