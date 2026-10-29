import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:noa/core/theme/glass_surface.dart';
import 'package:noa/core/theme/lumen_glass_style.dart';
import 'package:noa/core/widgets/glass_chip.dart';

void main() {
  testWidgets(
    'iOS: chrome refrata; sheet/chip FakeGlass; surface não é papel de vidro',
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

      expect(lumenUsesLiquidGlass(), isTrue);
      expect(lumenUsesMaterialChrome(), isFalse);
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
      expect(
        lumenGlassUseFake(context: captured, role: LumenGlassRole.navBar),
        isFalse,
      );
      expect(
        lumenGlassUseFake(context: captured, role: LumenGlassRole.appBar),
        isFalse,
      );
      expect(lumenGlassPreferLitePaint(LumenGlassRole.chip), isTrue);
      expect(lumenGlassPreferLitePaint(LumenGlassRole.surface), isFalse);
      final iosNav = lumenGlassSettings(
        context: captured,
        role: LumenGlassRole.navBar,
      );
      expect(iosNav.blur, greaterThan(0));
      expect(iosNav.saturation, 1.15);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Android: gate Material; glass lite desligado',
    (tester) async {
      expect(lumenUsesLiquidGlass(), isFalse);
      expect(lumenUsesMaterialChrome(), isTrue);
      expect(lumenGlassPreferLitePaint(LumenGlassRole.surface), isFalse);
      expect(lumenGlassPreferLitePaint(LumenGlassRole.chip), isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'Android: GlassSurface monta Card Material, sem LumenGlassLite',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassSurface(
              child: SizedBox(
                width: 200,
                height: 80,
                child: Text('material'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(LumenGlassLite), findsNothing);
      expect(find.byType(FakeGlass), findsNothing);
      expect(find.text('material'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'iOS: GlassSurface é sólido (sem LumenGlass / FakeGlass); chip usa lite',
    (tester) async {
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
      expect(find.byType(FakeGlass), findsNothing);
      expect(find.byType(LumenGlassLite), findsOneWidget);
      final surface = tester.widget<GlassSurface>(find.byType(GlassSurface));
      expect(surface.lite, isFalse);
      expect(lumenGlassPreferLitePaint(LumenGlassRole.surface), isFalse);
      expect(lumenGlassPreferLitePaint(LumenGlassRole.chip), isTrue);
      expect(lumenGlassPreferLitePaint(LumenGlassRole.navBar), isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'iOS: sombra de surface tem blur 20',
    (tester) async {
      final shadows = lumenGlassShadow(isDark: true);
      expect(shadows.single.blurRadius, 20);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Android: GlassChip monta FilterChip',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassChip(label: 'chip', selected: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FilterChip), findsOneWidget);
      expect(find.byType(LumenGlassLite), findsNothing);
      expect(find.text('chip'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
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
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('contato'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
