import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:noa/core/localization/locale_provider.dart';
import 'package:noa/core/providers.dart';
import 'package:noa/core/theme/lumen_glass_style.dart';
import 'package:noa/core/widgets/glass_app_bar.dart';
import 'package:noa/core/widgets/glass_nav_bar.dart';
import 'package:noa/core/widgets/lumen_shell.dart';
import 'package:noa/features/home/presentation/home_ficha_screen.dart';
import 'package:noa/features/medications/presentation/medications_screen.dart';
import 'package:noa/features/routine_mood/presentation/daily_routine_screen.dart';
import 'package:noa/features/therapist_export/presentation/clinical_folder_screen.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() async {
    debugLumenForceFakeGlass = true;
    SharedPreferences.setMockInitialValues(const {
      'noa_onboarding_done_v1': true,
    });
    await initializeDateFormatting('pt');
    l10n = lookupAppLocalizations(const Locale('pt'));
  });

  tearDown(() {
    debugLumenForceFakeGlass = false;
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    double keyboardBottom = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          activeLocaleProvider.overrideWithValue(const Locale('pt', 'BR')),
        ],
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                disableAnimations: true,
                viewInsets: EdgeInsets.only(bottom: keyboardBottom),
                viewPadding: mq.viewPadding.copyWith(bottom: 34),
                padding: mq.padding.copyWith(
                  bottom: keyboardBottom > 0 ? 0 : 34,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const LumenShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder navLabel(String label) => find.text(label).last;

  bool onScreen(WidgetTester tester, Finder finder) {
    final screen =
        Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio);
    for (final element in finder.evaluate()) {
      final box = element.renderObject;
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (rect.left >= -1 &&
          rect.left < screen.width - 8 &&
          rect.overlaps(screen)) {
        return true;
      }
    }
    return false;
  }

  testWidgets('raízes das quatro abas não usam GlassAppBar', (tester) async {
    await pumpShell(tester);

    expect(find.byType(HomeFichaScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HomeFichaScreen),
        matching: find.byType(GlassAppBar),
      ),
      findsNothing,
    );

    for (final entry in [
      (l10n.navRoutine, DailyRoutineScreen),
      (l10n.navMeds, MedicationsScreen),
      (l10n.navClinicalFolder, ClinicalFolderScreen),
    ]) {
      await tester.tap(navLabel(entry.$1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final screen = find.byType(entry.$2);
      expect(onScreen(tester, screen), isTrue);
      expect(
        find.descendant(
          of: screen,
          matching: find.byType(GlassAppBar),
        ),
        findsNothing,
      );
    }
  });

  testWidgets('aba ativa tem Semantics selected e lente sobre o slot', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(navLabel(l10n.navMeds));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final node = tester.getSemantics(navLabel(l10n.navMeds));
    expect(node.label, l10n.navMeds);
    expect(node.hint, l10n.navOpensTabHint(l10n.navMeds));
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isSelected, Tristate.isTrue);

    final lens = find.byKey(GlassNavBar.lensKey);
    expect(lens, findsOneWidget);
    final medsLabel = navLabel(l10n.navMeds);
    final lensBox = tester.renderObject(lens) as RenderBox;
    final labelBox = tester.renderObject(medsLabel) as RenderBox;
    final lensRect = lensBox.localToGlobal(Offset.zero) & lensBox.size;
    final labelRect = labelBox.localToGlobal(Offset.zero) & labelBox.size;
    expect(lensRect.overlaps(labelRect), isTrue);
  });

  testWidgets(
    'GlassNavBar não sobe quando o teclado abre (shell sem resize)',
    (tester) async {
      await pumpShell(tester);
      final nav = find.byType(GlassNavBar);
      expect(nav, findsOneWidget);
      final before = tester.getRect(nav);

      await pumpShell(tester, keyboardBottom: 320);
      final after = tester.getRect(find.byType(GlassNavBar));

      // Com resizeToAvoidBottomInset: false a cápsula permanece no fundo
      // da tela (viewPadding), não cola acima do teclado.
      expect(after.bottom, closeTo(before.bottom, 1));
      expect(after.top, closeTo(before.top, 1));
    },
  );

  testWidgets('com disableAnimations a lente troca de slot de imediato', (
    tester,
  ) async {
    await pumpShell(tester);

    final lens = find.byKey(GlassNavBar.lensKey);
    final homeLabel = navLabel(l10n.navHome);
    final homeBox = tester.renderObject(homeLabel) as RenderBox;
    final homeRect = homeBox.localToGlobal(Offset.zero) & homeBox.size;
    var lensBox = tester.renderObject(lens) as RenderBox;
    var lensRect = lensBox.localToGlobal(Offset.zero) & lensBox.size;
    expect(lensRect.overlaps(homeRect), isTrue);

    await tester.tap(navLabel(l10n.navClinicalFolder));
    await tester.pump(); // um frame — sem animação pendente

    final clinicLabel = navLabel(l10n.navClinicalFolder);
    final clinicBox = tester.renderObject(clinicLabel) as RenderBox;
    final clinicRect = clinicBox.localToGlobal(Offset.zero) & clinicBox.size;
    lensBox = tester.renderObject(lens) as RenderBox;
    lensRect = lensBox.localToGlobal(Offset.zero) & lensBox.size;
    expect(lensRect.overlaps(clinicRect), isTrue);
    expect(lensRect.overlaps(homeRect), isFalse);
  });
}
