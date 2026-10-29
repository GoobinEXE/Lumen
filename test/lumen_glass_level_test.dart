import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/theme/lumen_glass_level.dart';
import 'package:noa/core/theme/lumen_glass_style.dart';

void main() {
  test('resolveLumenGlassLevel: reduce transparency força solid', () {
    expect(
      resolveLumenGlassLevel(
        reduceTransparency: true,
        highContrast: true,
      ),
      LumenGlassLevel.solid,
    );
  });

  test('resolveLumenGlassLevel: high contrast vira tinted', () {
    expect(
      resolveLumenGlassLevel(
        reduceTransparency: false,
        highContrast: true,
      ),
      LumenGlassLevel.tinted,
    );
  });

  test('resolveLumenGlassLevel: padrão clear', () {
    expect(
      resolveLumenGlassLevel(
        reduceTransparency: false,
        highContrast: false,
      ),
      LumenGlassLevel.clear,
    );
  });

  test('preferência explícita ganha da acessibilidade', () {
    expect(
      resolveLumenGlassLevel(
        reduceTransparency: true,
        highContrast: true,
        preference: LumenGlassLevel.clear,
      ),
      LumenGlassLevel.clear,
    );
  });

  testWidgets('solid força FakeGlass no chrome', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        home: LumenGlassScope(
          level: LumenGlassLevel.solid,
          reduceTransparency: true,
          child: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(
      lumenGlassUseFake(
        context: captured,
        role: LumenGlassRole.navBar,
      ),
      isTrue,
    );
    final settings = lumenGlassSettings(
      context: captured,
      role: LumenGlassRole.navBar,
    );
    expect(settings.blur, 0);
  });

  testWidgets('tinted pede borda de contraste', (tester) async {
    expect(lumenGlassNeedsContrastBorder(LumenGlassLevel.tinted), isTrue);
    expect(lumenGlassNeedsContrastBorder(LumenGlassLevel.solid), isTrue);
    expect(lumenGlassNeedsContrastBorder(LumenGlassLevel.clear), isFalse);
  });
}
