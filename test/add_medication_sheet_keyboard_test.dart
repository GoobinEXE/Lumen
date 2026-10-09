import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:noa/core/localization/locale_provider.dart';
import 'package:noa/core/providers.dart';
import 'package:noa/core/theme/lumen_glass_style.dart';
import 'package:noa/features/medications/presentation/widgets/add_medication_sheet.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() async {
    debugLumenForceFakeGlass = true;
    SharedPreferences.setMockInitialValues(const {});
    await initializeDateFormatting('pt');
    l10n = lookupAppLocalizations(const Locale('pt'));
  });

  tearDown(() {
    debugLumenForceFakeGlass = false;
  });

  Future<void> openSheet(WidgetTester tester) async {
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
              data: mq.copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AddMedicationSheet.show(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'teclado não colapsa o sheet abaixo de um limiar útil e campo baixo fica acima do inset',
    (tester) async {
      await openSheet(tester);

      expect(find.text(l10n.newMedicationSheetTitle), findsOneWidget);
      final heightBefore =
          tester.getSize(find.byType(AddMedicationSheet)).height;

      const keyboard = 320.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      final sheet = tester.getSize(find.byType(AddMedicationSheet));
      // Área útil ~844 - 320; sheet permanece usável (não vira faixa minúscula).
      expect(sheet.height, greaterThan(280));
      expect(sheet.height, greaterThan(heightBefore * 0.45));

      final instructionsField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.labelText == l10n.medInstructionsLabel ||
                w.decoration?.hintText == l10n.medInstructionsHint),
      );
      expect(instructionsField, findsOneWidget);

      await tester.ensureVisible(instructionsField);
      await tester.tap(instructionsField);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final fieldRect = tester.getRect(instructionsField);
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      // Campo ativo permanece acima da região do teclado.
      expect(fieldRect.bottom, lessThanOrEqualTo(screenHeight - keyboard + 8));
      expect(find.text(l10n.newMedicationSheetTitle), findsOneWidget);
      expect(find.text(l10n.saveMedicationButton), findsOneWidget);
    },
  );
}
