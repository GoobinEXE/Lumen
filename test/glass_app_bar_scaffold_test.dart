import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/theme/lumen_glass_style.dart';
import 'package:noa/core/widgets/glass_app_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugLumenForceFakeGlass = true;
  });

  tearDown(() {
    debugLumenForceFakeGlass = false;
  });

  testWidgets(
    'iOS: GlassScaffold empura o body abaixo da cápsula',
    (tester) async {
      const statusTop = 47.0;

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: statusTop);
      tester.view.viewPadding = const FakeViewPadding(top: statusTop);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await tester.pumpWidget(
        MaterialApp(
          home: GlassScaffold(
            appBar: const GlassAppBar(title: Text('Meu perfil')),
            body: Builder(
              builder: (context) {
                expect(MediaQuery.paddingOf(context).top, 0);
                return ColoredBox(
                  key: const Key('glass-body'),
                  color: Colors.red,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 16),
                    children: const [
                      Text('primeiro'),
                      SizedBox(height: 1200),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reserved =
          GlassAppBar.reservedTop(tester.element(find.byType(GlassAppBar)));
      expect(
        reserved,
        statusTop + kToolbarHeight + GlassAppBar.verticalGap,
      );

      final bodyBox =
          tester.renderObject(find.byKey(const Key('glass-body'))) as RenderBox;
      final bodyTop = bodyBox.localToGlobal(Offset.zero).dy;
      expect(bodyTop, closeTo(reserved, 1));

      final first = tester.getTopLeft(find.text('primeiro'));
      expect(first.dy, greaterThanOrEqualTo(reserved));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Android: GlassScaffold usa AppBar Material no slot do Scaffold',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlassScaffold(
            appBar: const GlassAppBar(title: Text('Meu perfil')),
            body: const Text('corpo'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Meu perfil'), findsOneWidget);
      expect(find.text('corpo'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
