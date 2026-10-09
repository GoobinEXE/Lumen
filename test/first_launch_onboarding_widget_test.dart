import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:noa/core/localization/locale_provider.dart';
import 'package:noa/core/providers.dart';
import 'package:noa/core/widgets/glass_chip.dart';
import 'package:noa/features/onboarding/data/onboarding_prefs.dart';
import 'package:noa/features/onboarding/domain/onboarding_profile_draft.dart';
import 'package:noa/features/onboarding/presentation/first_launch_onboarding.dart';
import 'package:noa/features/onboarding/presentation/onboarding_profile_form.dart';
import 'package:noa/features/profile/data/user_profile_repository.dart';
import 'package:noa/features/profile/domain/profile_demographics.dart';
import 'package:noa/features/profile/domain/user_profile.dart';
import 'package:noa/features/profile/domain/voice_tone_profile.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt');
    l10n = lookupAppLocalizations(const Locale('pt'));
  });

  Widget wrap(Widget home, SharedPreferences prefs) {
    return ProviderScope(
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
        home: home,
      ),
    );
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final finder = find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(finder, findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('wizard em tela cheia: pular saúde e acessos até o perfil', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrap(
        Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => FirstLaunchOnboarding.maybeShow(context, ref),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
        prefs,
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Passo 1: boas-vindas + privacidade, em rota própria (não é sheet).
    expect(find.text(l10n.onboardingWelcomeTitle), findsOneWidget);
    expect(find.text(l10n.onboardingPrivacyTitle), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text(l10n.onboardingStepLabel(1, 4)), findsOneWidget);
    await tapButton(tester, l10n.onboardingNext);

    // Passo 2: saúde — "Agora não" segue sem importar nada.
    expect(find.text(l10n.onboardingHealthTitle), findsOneWidget);
    await tapButton(tester, l10n.onboardingSkip);

    // Passo 3: acessos — pular não trava o fluxo.
    expect(find.text(l10n.onboardingPermissionsTitle), findsOneWidget);
    expect(find.text(l10n.onboardingStatusSkipped), findsNWidgets(3));
    await tapButton(tester, l10n.onboardingSkip);

    // Passo 4: perfil — sem Health, concluir fica travado até preencher tudo.
    expect(find.text(l10n.onboardingProfileTitle), findsOneWidget);
    expect(find.text(l10n.onboardingProfileBody), findsOneWidget);
    final finish = find.widgetWithText(ElevatedButton, l10n.onboardingFinish);
    expect(finish, findsOneWidget);
    expect(tester.widget<ElevatedButton>(finish).onPressed, isNull);
    expect(find.textContaining(l10n.onboardingBirthDateLabel), findsWidgets);

    // Voltar com o gesto do sistema vai pro passo anterior, não fecha.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingPermissionsTitle), findsOneWidget);
    expect(prefs.getBool(onboardingDoneKey), isNot(isTrue));
  });

  testWidgets('voltar ao passo de saúde depois de pular ainda oferece ligar', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const FirstLaunchOnboarding(), prefs));
    await tester.pumpAndSettle();

    await tapButton(tester, l10n.onboardingNext);
    await tapButton(tester, l10n.onboardingSkip);
    expect(find.text(l10n.onboardingPermissionsTitle), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(l10n.onboardingHealthTitle), findsOneWidget);
    final connect = find.widgetWithText(
      ElevatedButton,
      l10n.onboardingHealthYes,
    );
    expect(connect, findsOneWidget);
    expect(tester.widget<ElevatedButton>(connect).onPressed, isNotNull);
    expect(find.widgetWithText(TextButton, l10n.onboardingSkip), findsOneWidget);
  });

  testWidgets('formulário com lacunas do Health só pede o que faltou', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final base = UserProfile(id: 'u1', updatedAt: DateTime(2026, 10, 6));
    var draft = OnboardingProfileDraft.fromProfile(
      base,
      demographics: ProfileDemographics(
        birthDate: DateTime(1998, 5, 20),
        biologicalSex: 'female',
      ),
    );

    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: SingleChildScrollView(
            child: OnboardingProfileForm(
              draft: draft,
              onChanged: (next) => draft = next,
              l10n: l10n,
            ),
          ),
        ),
        prefs,
      ),
    );
    await tester.pumpAndSettle();

    // Campos que vieram do Health aparecem marcados e já preenchidos.
    expect(find.text(l10n.onboardingFromHealthTag), findsNWidgets(2));
    expect(find.text(l10n.onboardingBirthDatePick), findsNothing);
    expect(draft.missingFields, {
      OnboardingProfileField.name,
      OnboardingProfileField.voiceTone,
      OnboardingProfileField.heightCm,
      OnboardingProfileField.weightKg,
    });

    await tester.enterText(
      find.widgetWithText(TextField, l10n.profileNameLabel),
      'Ana',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.onboardingHeightLabel),
      '1,68',
    );
    await tester.enterText(
      find.widgetWithText(TextField, l10n.onboardingWeightLabel),
      '62,5',
    );
    await tester.pumpAndSettle();
    // 1,68 é metro, não centímetro: erro visível e campo ainda pendente.
    expect(find.text(l10n.onboardingInvalidNumber), findsOneWidget);
    expect(draft.missingFields, {
      OnboardingProfileField.voiceTone,
      OnboardingProfileField.heightCm,
    });

    await tester.enterText(
      find.widgetWithText(TextField, l10n.onboardingHeightLabel),
      '168',
    );
    await tester.tap(find.widgetWithText(GlassChip, l10n.voiceToneRelaxed));
    await tester.pumpAndSettle();

    expect(find.text(l10n.onboardingInvalidNumber), findsNothing);
    expect(draft.isComplete, isTrue);
    expect(draft.voiceToneProfile, VoiceToneProfile.relaxed);
    expect(draft.heightCm, 168);
    expect(draft.weightKg, 62.5);

    final profile = draft.applyTo(base);
    expect(profile.trimmedName, 'Ana');
    expect(profile.importedFromHealth, isTrue);

    final repo = UserProfileRepository(prefs);
    await repo.save(profile);
    expect(repo.read().biologicalSex, 'female');
  });
}
