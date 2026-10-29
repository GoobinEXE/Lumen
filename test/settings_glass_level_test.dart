import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:noa/core/localization/locale_provider.dart';
import 'package:noa/core/providers.dart';
import 'package:noa/core/theme/glass_level_provider.dart';
import 'package:noa/features/settings/presentation/settings_screen.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {
      'noa_onboarding_done_v1': true,
    });
    await initializeDateFormatting('pt');
    l10n = lookupAppLocalizations(const Locale('pt'));
  });

  Future<void> pumpSettings(WidgetTester tester) async {
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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'iOS: mostra Aparência do vidro e persiste a escolha',
    (tester) async {
      await pumpSettings(tester);

      expect(find.text(l10n.settingsGlassTitle), findsOneWidget);
      expect(find.text(l10n.settingsGlassSystem), findsOneWidget);

      await tester.tap(find.text(l10n.settingsGlassSolid));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(glassLevelPrefKey), 'solid');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Android: não mostra Aparência do vidro',
    (tester) async {
      await pumpSettings(tester);

      expect(find.text(l10n.settingsGlassTitle), findsNothing);
      expect(find.text(l10n.settingsThemeTitle), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}
