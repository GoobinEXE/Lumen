import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:noa/core/theme/glass_surface.dart';
import 'package:noa/core/theme/lumen_glass_style.dart';
import 'package:noa/core/widgets/glass_chip.dart';

void main() {
  testWidgets(
    'surface, chip e sheet usam FakeGlass; chrome iOS refrata, Android não',
    (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        lumenGlassUseFake(context: captured, role: LumenGlassRole.surface),
        isTrue,
      );
      expect(
        lumenGlassUseFake(context: captured, role: LumenGlassRole.chip),
        isTrue,
      );
      expect(
        lumenGlassUseFake(context: captured, role: LumenGlassRole.sheet),
        isTrue,
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        expect(
          lumenGlassUseFake(context: captured, role: LumenGlassRole.navBar),
          isFalse,
        );
        expect(
          lumenGlassUseFake(context: captured, role: LumenGlassRole.appBar),
          isFalse,
        );
        expect(lumenGlassAndroidLite(), isFalse);
        final iosSurface = lumenGlassSettings(
          context: captured,
          role: LumenGlassRole.surface,
        );
        expect(iosSurface.blur, greaterThan(0));
        expect(iosSurface.saturation, 1.15);

        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        expect(
          lumenGlassUseFake(context: captured, role: LumenGlassRole.navBar),
          isTrue,
        );
        expect(
          lumenGlassUseFake(context: captured, role: LumenGlassRole.appBar),
          isTrue,
        );
        expect(lumenGlassAndroidLite(), isTrue);
        expect(lumenGlassPreferLitePaint(LumenGlassRole.surface), isTrue);
        expect(lumenGlassPreferLitePaint(LumenGlassRole.chip), isTrue);
        expect(lumenGlassPreferLitePaint(LumenGlassRole.navBar), isFalse);
        expect(lumenGlassPreferLitePaint(LumenGlassRole.sheet), isFalse);

        final androidSurface = lumenGlassSettings(
          context: captured,
          role: LumenGlassRole.surface,
        );
        final androidChip = lumenGlassSettings(
          context: captured,
          role: LumenGlassRole.chip,
        );
        final androidNav = lumenGlassSettings(
          context: captured,
          role: LumenGlassRole.navBar,
        );
        final androidSheet = lumenGlassSettings(
          context: captured,
          role: LumenGlassRole.sheet,
        );
        expect(androidSurface.blur, 0);
        expect(androidChip.blur, 0);
        expect(androidSurface.saturation, 1.0);
        expect(androidNav.blur, greaterThan(0));
        expect(androidSheet.blur, greaterThan(0));
        expect(androidNav.saturation, 1.15);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'Android lite: GlassSurface monta LumenGlassLite, sem FakeGlass',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GlassSurface(
                child: SizedBox(
                  width: 200,
                  height: 80,
                  child: Text('lite'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(LumenGlassLite), findsOneWidget);
        expect(find.byType(FakeGlass), findsNothing);
        expect(find.text('lite'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'iOS: GlassSurface não usa LumenGlassLite; chip usa (scroll denso)',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  GlassSurface(
                    child: SizedBox(
                      width: 200,
                      height: 80,
                      child: Text('ios'),
                    ),
                  ),
                  GlassChip(label: 'chip-lite'),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('ios'), findsOneWidget);
        expect(find.text('chip-lite'), findsOneWidget);
        // Surface mantém FakeGlass; só o chip vai para paint lite.
        expect(find.byType(LumenGlassLite), findsOneWidget);
        expect(lumenGlassPreferLitePaint(LumenGlassRole.surface), isFalse);
        expect(lumenGlassPreferLitePaint(LumenGlassRole.chip), isTrue);
        expect(lumenGlassPreferLitePaint(LumenGlassRole.navBar), isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  test('Android lite: sombra de surface tem blur 10', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final shadows = lumenGlassShadow(isDark: true);
      expect(shadows.single.blurRadius, 10);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'Android lite: surface/chip translúcidos (sem placa opaca)',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        late BuildContext captured;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                captured = context;
                return const Scaffold(
                  body: GlassSurface(
                    child: SizedBox(
                      width: 120,
                      height: 48,
                      child: Text('chip'),
                    ),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        final surface = lumenGlassSettings(
          context: captured,
          role: LumenGlassRole.surface,
        );
        final chip = lumenGlassSettings(
          context: captured,
          role: LumenGlassRole.chip,
        );
        expect(surface.glassColor.a, lessThan(0.55));
        expect(surface.glassColor.a, greaterThan(0.25));
        expect(chip.glassColor.a, lessThan(0.45));
        expect(find.byType(LumenGlassLite), findsOneWidget);
        expect(find.text('chip'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'GlassSurface em Column scrollável não dispara Infinity/NaN toInt',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  GlassSurface(
                    child: SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: Text('contato'),
                    ),
                  ),
                  SizedBox(height: 800),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('contato'), findsOneWidget);
    },
  );
}
