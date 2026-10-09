import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/core/theme/glass_surface.dart';
import 'package:noa/core/theme/lumen_glass_style.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('lumenSheetBottomInset / maxHeight', () {
    test('teclado ganha do home indicator — um inset só', () {
      expect(
        lumenSheetBottomInset(keyboardBottom: 320, viewPaddingBottom: 34),
        320,
      );
      expect(
        lumenSheetBottomInset(keyboardBottom: 0, viewPaddingBottom: 34),
        34,
      );
    });

    test('maxHeight com teclado grande ainda passa do limiar útil', () {
      const screen = 844.0;
      const keyboard = 320.0;
      final inset = lumenSheetBottomInset(
        keyboardBottom: keyboard,
        viewPaddingBottom: 34,
      );
      final maxH = lumenSheetMaxHeight(
        screenHeight: screen,
        bottomInset: inset,
      );
      expect(maxH, greaterThanOrEqualTo(lumenSheetMinUsableHeight));
      expect(maxH, closeTo((screen - keyboard) * 0.92, 0.01));
    });
  });

  testWidgets(
    'LumenKeyboardInset com teclado mantém altura útil e não soma SafeArea',
    (tester) async {
      debugLumenForceFakeGlass = true;
      addTearDown(() => debugLumenForceFakeGlass = false);

      const keyboard = 320.0;
      const homeIndicator = 34.0;
      const screenH = 844.0;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            final base = MediaQuery.of(context);
            return MediaQuery(
              data: base.copyWith(
                size: const Size(390, screenH),
                viewInsets: const EdgeInsets.only(bottom: keyboard),
                viewPadding: const EdgeInsets.only(bottom: homeIndicator),
                padding: EdgeInsets.zero,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          // Sem Scaffold: o body do Scaffold zera viewInsets e mascara o
          // contrato (no modal real o sheet ainda vê o teclado).
          home: LumenKeyboardInset(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  key: const Key('sheet-body'),
                  width: double.infinity,
                  height: constraints.maxHeight,
                  child: const ColoredBox(color: Colors.teal),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final inset = tester.widget<ConstrainedBox>(
        find.byKey(const Key('lumen-keyboard-inset')),
      );
      final expected = (screenH - keyboard) * lumenSheetMaxHeightFraction;
      expect(
        inset.constraints.maxHeight,
        greaterThanOrEqualTo(lumenSheetMinUsableHeight),
      );
      expect(inset.constraints.maxHeight, closeTo(expected, 1));
      // Teclado venceu o home indicator (não descontou 320+34).
      expect(
        inset.constraints.maxHeight,
        isNot(closeTo((screenH - keyboard - homeIndicator) * 0.92, 1)),
      );

      final size = tester.getSize(find.byKey(const Key('sheet-body')));
      expect(size.height, greaterThanOrEqualTo(lumenSheetMinUsableHeight));
    },
  );

  test('lib/ não reintroduz anti-padrões de teclado em sheet', () {
    final root = Directory('lib');
    expect(root.existsSync(), isTrue, reason: 'rode o teste na raiz do app');

    final violations = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = entity.path.replaceAll(r'\', '/');
      final src = entity.readAsStringSync();

      // Fonte da verdade do contrato — pode usar viewInsets internamente.
      if (rel.endsWith('lib/core/theme/glass_surface.dart')) continue;

      if (src.contains('expandChild: true')) {
        violations.add('$rel: expandChild: true em form (esmaga com teclado)');
      }

      if (src.contains('GlassSheet(') &&
          src.contains('viewInsetsOf') &&
          RegExp(r'EdgeInsets\.only\(\s*bottom:').hasMatch(src)) {
        violations.add(
          '$rel: GlassSheet + Padding(viewInsets) no caller (desconto duplo)',
        );
      }

      if (src.contains('showLumenSheet') &&
          src.contains('useSafeArea: true')) {
        violations.add(
          '$rel: showLumenSheet(..., useSafeArea: true) — proibido',
        );
      }

      // Forms glass devem abrir pelo helper, não pelo modal cru.
      if (src.contains('GlassSheet(') &&
          src.contains('showModalBottomSheet') &&
          !src.contains('showLumenSheet')) {
        violations.add(
          '$rel: GlassSheet aberto com showModalBottomSheet (use showLumenSheet)',
        );
      }
    }

    final surface = File('lib/core/theme/glass_surface.dart').readAsStringSync();
    if (!surface.contains('useRootNavigator: useRootNavigator') &&
        !surface.contains('useRootNavigator: true')) {
      violations.add(
        'glass_surface.dart: showLumenSheet precisa de useRootNavigator '
        '(senão a gaveta fica atrás da GlassNavBar)',
      );
    }

    expect(
      violations,
      isEmpty,
      reason: 'Anti-padrões de sheet/teclado:\n${violations.join('\n')}',
    );
  });

  test(
    'shell, GlassScaffold e abas raiz desligam resizeToAvoidBottomInset',
    () {
      const required = [
        'lib/core/widgets/lumen_shell.dart',
        'lib/core/widgets/glass_app_bar.dart',
        'lib/features/medications/presentation/medications_screen.dart',
        'lib/features/home/presentation/home_ficha_screen.dart',
        'lib/features/routine_mood/presentation/daily_routine_screen.dart',
        'lib/features/therapist_export/presentation/clinical_folder_screen.dart',
      ];
      for (final path in required) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        expect(
          file.readAsStringSync().contains('resizeToAvoidBottomInset: false'),
          isTrue,
          reason: '$path deve ter resizeToAvoidBottomInset: false '
              '(senão tab bar sobe com o teclado)',
        );
      }
    },
  );
}
