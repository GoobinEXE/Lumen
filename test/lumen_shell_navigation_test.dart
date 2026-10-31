import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:noa/features/calendar/presentation/routine_calendar_screen.dart';
import 'package:noa/features/home/presentation/home_ficha_screen.dart';
import 'package:noa/features/medications/presentation/medications_screen.dart';
import 'package:noa/features/medications/service/medication_notification_bus.dart';
import 'package:noa/features/profile/presentation/profile_screen.dart';
import 'package:noa/features/routine_mood/presentation/daily_routine_screen.dart';
import 'package:noa/features/settings/presentation/settings_screen.dart';
import 'package:noa/features/tasks/presentation/tasks_hub_screen.dart';
import 'package:noa/features/tasks/service/task_notification_bus.dart';
import 'package:noa/features/therapist_export/presentation/clinical_folder_screen.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  void resetNotificationBuses() {
    MedicationNotificationBus.openMedications.value = 0;
    TaskNotificationBus.openRoutine.value = 0;
    TaskNotificationBus.openTasks.value = 0;
  }

  setUp(() async {
    resetNotificationBuses();
    debugLumenForceFakeGlass = true;
    SharedPreferences.setMockInitialValues(const {
      'noa_onboarding_done_v1': true,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => 'America/Sao_Paulo',
    );
    await initializeDateFormatting('pt');
    l10n = lookupAppLocalizations(const Locale('pt'));
  });

  tearDown(() {
    resetNotificationBuses();
    debugLumenForceFakeGlass = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      null,
    );
  });

  Future<void> pumpShell(WidgetTester tester) async {
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
          sleepHistoryProvider.overrideWith((ref) async => const []),
          recoveryHistoryProvider.overrideWith((ref) async => const []),
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
          home: const LumenShell(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder appBarTitle(String title) {
    // Telas empilhadas usam GlassAppBar (PreferredSize), não Material AppBar.
    return find.descendant(
      of: find.byType(GlassAppBar),
      matching: find.text(title),
    );
  }

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

  Finder navLabel(String label) => find.text(label).last;

  /// Leva o alvo para a área tocável (glass overlay fora do caminho).
  /// ListView lazy: arrasta até o alvo existir no tree e ficar tocável.
  Future<void> revealForTap(
    WidgetTester tester,
    Finder target, {
    required Finder scrollable,
  }) async {
    final h =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    for (var i = 0; i < 20; i++) {
      if (target.evaluate().isNotEmpty && onScreen(tester, target)) {
        final box = tester.renderObject(target.first) as RenderBox;
        final center = box.localToGlobal(box.size.center(Offset.zero));
        if (center.dy > 90 && center.dy < h - 100) return;
      }
      await tester.drag(scrollable, const Offset(0, -240));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  testWidgets('abas laterais só montam na primeira visita', (tester) async {
    await pumpShell(tester);

    expect(find.byType(HomeFichaScreen), findsOneWidget);
    expect(find.byType(DailyRoutineScreen), findsNothing);
    expect(find.byType(MedicationsScreen), findsNothing);
    expect(find.byType(ClinicalFolderScreen), findsNothing);

    await tester.tap(navLabel(l10n.navRoutine));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(DailyRoutineScreen), findsOneWidget);
    expect(find.byType(MedicationsScreen), findsNothing);
  });

  testWidgets('push/pop não remonta a GlassNavBar', (tester) async {
    await pumpShell(tester);

    final before = tester.element(find.byType(GlassNavBar));
    await tester.tap(find.byTooltip(l10n.profileOpenTooltip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final afterPush = tester.element(find.byType(GlassNavBar));
    expect(identical(before, afterPush), isTrue);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(onScreen(tester, find.byType(ProfileScreen)), isTrue);
    expect(find.text(l10n.profileScreenTitle), findsNothing);

    Navigator.of(tester.element(find.byType(ProfileScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final afterPop = tester.element(find.byType(GlassNavBar));
    expect(identical(before, afterPop), isTrue);
  });

  testWidgets('toque duplo em Dia não aumenta a pilha', (tester) async {
    await pumpShell(tester);

    await tester.tap(navLabel(l10n.navRoutine));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(navLabel(l10n.navRoutine));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final screen = find.byType(DailyRoutineScreen);
    expect(screen, findsOneWidget);
    expect(onScreen(tester, screen), isTrue);
    expect(Navigator.of(tester.element(screen)).canPop(), isFalse);
  });

  testWidgets('toque em Dia e depois em Remédios mostra Remédios', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(navLabel(l10n.navRoutine));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(navLabel(l10n.navMeds));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final meds = find.byType(MedicationsScreen);
    final routine = find.byType(DailyRoutineScreen);
    expect(onScreen(tester, meds), isTrue);
    expect(onScreen(tester, routine), isFalse);
  });

  testWidgets('atalho da home troca para a aba Dia', (tester) async {
    await pumpShell(tester);

    final anchor = find.text(l10n.homeDayAnchorTitle);
    final homeScroll = find.descendant(
      of: find.byType(HomeFichaScreen),
      matching: find.byType(Scrollable),
    );
    // Lista da ficha é lazy: com a GlassNavBar flutuante o card fica
    // abaixo do cacheExtent até rolar.
    await tester.scrollUntilVisible(anchor, 300, scrollable: homeScroll);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(anchor);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final screen = find.byType(DailyRoutineScreen);
    expect(onScreen(tester, screen), isTrue);
    expect(Navigator.of(tester.element(screen)).canPop(), isFalse);
  });

  testWidgets('aba Pasta clínica abre as exportações', (tester) async {
    await pumpShell(tester);

    await tester.tap(navLabel(l10n.navClinicalFolder));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final screen = find.byType(ClinicalFolderScreen);
    expect(onScreen(tester, screen), isTrue);
    expect(find.text(l10n.sendWhatsAppTitle), findsWidgets);
  });

  testWidgets('ícone de perfil na Home abre o Meu Perfil', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip(l10n.profileOpenTooltip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(onScreen(tester, find.byType(ProfileScreen)), isTrue);
    expect(find.text(l10n.profileScreenTitle), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ProfileScreen),
        matching: find.byTooltip(l10n.settingsOpenTooltip),
      ),
      findsOneWidget,
    );
  });

  Finder profileSettingsGear() => find.descendant(
        of: find.byType(ProfileScreen),
        matching: find.byTooltip(l10n.settingsOpenTooltip),
      );

  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump(); // post-frame callbacks (openTasksHub etc.)
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('engrenagem do Perfil abre Configurações', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip(l10n.profileOpenTooltip));
    await settleRoute(tester);
    await tester.tap(profileSettingsGear());
    await settleRoute(tester);

    final title = appBarTitle(l10n.settingsScreenTitle);
    expect(onScreen(tester, title), isTrue);
    expect(find.text(l10n.settingsThemeTitle), findsOneWidget);
    expect(find.text(l10n.settingsLanguageTitle), findsOneWidget);
  });

  testWidgets(
    'botão "Ver todas as tarefas" na Dia empilha o Hub na aba Início',
    (tester) async {
      await pumpShell(tester);

      await tester.tap(navLabel(l10n.navRoutine));
      await settleRoute(tester);

      final openTasksButton = find.text(l10n.tasksHubOpenFromDay);
      expect(openTasksButton, findsOneWidget);
      final routineScroll = find
          .descendant(
            of: find.byType(DailyRoutineScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await revealForTap(
        tester,
        openTasksButton,
        scrollable: routineScroll,
      );
      await tester.tap(openTasksButton);
      await settleRoute(tester);

      // Destino canônico: TasksHub empilhado na aba Início, não na Dia.
      final tasksTitle = appBarTitle(l10n.tasksHubTitle);
      expect(onScreen(tester, tasksTitle), isTrue);

      final navigator = Navigator.of(tester.element(tasksTitle));
      expect(navigator.canPop(), isTrue);

      // A Dia saiu de cena: a pilha visível é a da aba Início.
      expect(onScreen(tester, find.byType(DailyRoutineScreen)), isFalse);

      navigator.pop();
      await settleRoute(tester);
      expect(onScreen(tester, find.byType(HomeFichaScreen).first), isTrue);
    },
  );

  testWidgets('card de Tarefas na Home abre o mesmo Hub da Dia', (
    tester,
  ) async {
    await pumpShell(tester);

    final tasksCard = find.text(l10n.homeTasksTitle);
    final homeScroll = find.descendant(
      of: find.byType(HomeFichaScreen),
      matching: find.byType(Scrollable),
    );
    await revealForTap(tester, tasksCard, scrollable: homeScroll);
    await tester.tap(tasksCard);
    await settleRoute(tester);

    final tasksTitle = appBarTitle(l10n.tasksHubTitle);
    expect(onScreen(tester, tasksTitle), isTrue);
    expect(Navigator.of(tester.element(tasksTitle)).canPop(), isTrue);
    expect(find.byType(TasksHubScreen), findsOneWidget);
  });

  testWidgets('card de Meus dias na Home empilha o calendário na Início', (
    tester,
  ) async {
    await pumpShell(tester);

    final calendarCard = find.text(l10n.homeMyDaysTitle);
    final homeScroll = find.descendant(
      of: find.byType(HomeFichaScreen),
      matching: find.byType(Scrollable),
    );
    await revealForTap(tester, calendarCard, scrollable: homeScroll);
    await tester.tap(calendarCard);
    await settleRoute(tester);

    final calendarTitle = appBarTitle(l10n.routineCalendarTitle);
    expect(onScreen(tester, calendarTitle), isTrue);
    expect(Navigator.of(tester.element(calendarTitle)).canPop(), isTrue);
    expect(find.byType(RoutineCalendarScreen), findsOneWidget);
  });

  testWidgets(
    'tap em Tarefas na Home abre sem depender de frame de scroll',
    (tester) async {
      await pumpShell(tester);

      final home = find.byType(HomeFichaScreen);
      final tasksCard = find.text(l10n.homeTasksTitle);
      final homeScroll = find.descendant(
        of: home,
        matching: find.byType(Scrollable),
      );
      await revealForTap(tester, tasksCard, scrollable: homeScroll);
      await tester.pumpAndSettle();

      await tester.tap(tasksCard);

      expect(Navigator.of(tester.element(home)).canPop(), isTrue);

      await tester.pump();
      expect(find.byType(TasksHubScreen), findsOneWidget);
      expect(onScreen(tester, appBarTitle(l10n.tasksHubTitle)), isTrue);
    },
  );

  testWidgets(
    'tap em Meus dias na Home abre sem depender de frame de scroll',
    (tester) async {
      await pumpShell(tester);

      final home = find.byType(HomeFichaScreen);
      final calendarCard = find.text(l10n.homeMyDaysTitle);
      final homeScroll = find.descendant(
        of: home,
        matching: find.byType(Scrollable),
      );
      await revealForTap(tester, calendarCard, scrollable: homeScroll);
      await tester.pumpAndSettle();

      await tester.tap(calendarCard);

      expect(Navigator.of(tester.element(home)).canPop(), isTrue);

      await tester.pump();
      expect(find.byType(RoutineCalendarScreen), findsOneWidget);
      expect(onScreen(tester, appBarTitle(l10n.routineCalendarTitle)), isTrue);
    },
  );

  testWidgets(
    'toques repetidos em Tarefas não empilham vários Hubs',
    (tester) async {
      await pumpShell(tester);

      final home = find.byType(HomeFichaScreen);
      final homeScroll = find.descendant(
        of: home,
        matching: find.byType(Scrollable),
      );
      await revealForTap(
        tester,
        find.text(l10n.homeTasksTitle),
        scrollable: homeScroll,
      );
      await tester.pumpAndSettle();

      final context = tester.element(home);
      for (var i = 0; i < 5; i++) {
        openTasksHub(context);
      }
      await settleRoute(tester);

      expect(find.byType(TasksHubScreen), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(TasksHubScreen))).canPop(),
        isTrue,
      );
    },
  );

  testWidgets(
    'Configurações → Pasta clínica esvazia a pilha de origem ao voltar',
    (tester) async {
      await pumpShell(tester);

      await tester.tap(find.byTooltip(l10n.profileOpenTooltip));
      await settleRoute(tester);
      await tester.tap(profileSettingsGear());
      await settleRoute(tester);

      final clinicalTile = find.text(l10n.settingsClinicalExportTitle).first;
      final settingsScroll = find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(Scrollable),
      );
      await revealForTap(
        tester,
        clinicalTile,
        scrollable: settingsScroll,
      );
      await tester.tap(clinicalTile);
      await settleRoute(tester);

      final clinical = find.byType(ClinicalFolderScreen);
      expect(onScreen(tester, clinical), isTrue);
      // A troca de aba já esvaziou a pilha de origem: nada de Configurações
      // ou Perfil sobrevive escondido atrás da Pasta clínica.
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsNothing);

      // Voltar para a aba Início mostra a própria raiz, sem resquício da
      // pilha anterior (Perfil/Configurações ficando empilhado por trás).
      await tester.tap(navLabel(l10n.navHome));
      await settleRoute(tester);

      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsNothing);
      final homeScreen = find.byType(HomeFichaScreen);
      expect(homeScreen, findsOneWidget);
      expect(Navigator.of(tester.element(homeScreen)).canPop(), isFalse);
    },
  );

  testWidgets('alarme de remédio abre a aba na hora', (tester) async {
    await pumpShell(tester);

    MedicationNotificationBus.requestOpenMedications();
    await tester.pump();

    final meds = find.byType(MedicationsScreen);
    expect(meds, findsOneWidget);
    expect(onScreen(tester, meds), isTrue);
    expect(onScreen(tester, find.byType(HomeFichaScreen)), isFalse);
  });

  testWidgets(
    'segundo alarme de remédio em seguida não puxa de volta para a aba',
    (tester) async {
      await pumpShell(tester);

      MedicationNotificationBus.requestOpenMedications();
      await tester.pump();
      expect(onScreen(tester, find.byType(MedicationsScreen)), isTrue);

      await tester.tap(navLabel(l10n.navHome));
      await tester.pump();
      expect(onScreen(tester, find.byType(HomeFichaScreen)), isTrue);

      MedicationNotificationBus.requestOpenMedications();
      await tester.pump();

      expect(onScreen(tester, find.byType(HomeFichaScreen)), isTrue);
      expect(onScreen(tester, find.byType(MedicationsScreen)), isFalse);
    },
  );

  testWidgets('alarme de tarefa abre o hub na Início sem esperar frame', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(navLabel(l10n.navMeds));
    await tester.pump();
    expect(onScreen(tester, find.byType(MedicationsScreen)), isTrue);

    TaskNotificationBus.requestOpenTasks();

    final home = find.byType(HomeFichaScreen, skipOffstage: false);
    expect(home, findsOneWidget);
    expect(Navigator.of(tester.element(home)).canPop(), isTrue);

    await tester.pump();
    expect(find.byType(TasksHubScreen), findsOneWidget);
    expect(onScreen(tester, find.byType(TasksHubScreen)), isTrue);
    expect(onScreen(tester, find.byType(MedicationsScreen)), isFalse);
  });

  testWidgets(
    'segundo alarme de tarefa em seguida não reabre o hub',
    (tester) async {
      await pumpShell(tester);

      TaskNotificationBus.requestOpenTasks();
      await tester.pump();
      expect(find.byType(TasksHubScreen), findsOneWidget);

      Navigator.of(tester.element(find.byType(TasksHubScreen))).pop();
      await tester.pump();
      expect(find.byType(TasksHubScreen), findsNothing);

      TaskNotificationBus.requestOpenTasks();
      await tester.pump();

      expect(find.byType(TasksHubScreen), findsNothing);
      final home = find.byType(HomeFichaScreen);
      expect(home, findsOneWidget);
      expect(Navigator.of(tester.element(home)).canPop(), isFalse);
    },
  );

  testWidgets('alarme de rotina abre a aba Dia', (tester) async {
    await pumpShell(tester);

    TaskNotificationBus.requestOpenRoutine();
    await tester.pump();

    final routine = find.byType(DailyRoutineScreen);
    expect(onScreen(tester, routine), isTrue);
    expect(Navigator.of(tester.element(routine)).canPop(), isFalse);
  });

  testWidgets(
    'alarme de remédio que chegou antes do shell ainda abre a aba',
    (tester) async {
      MedicationNotificationBus.requestOpenMedications();
      await pumpShell(tester);

      final meds = find.byType(MedicationsScreen);
      expect(meds, findsOneWidget);
      expect(onScreen(tester, meds), isTrue);
    },
  );

  testWidgets(
    'alarme de tarefa que chegou antes do shell ainda abre o hub',
    (tester) async {
      TaskNotificationBus.requestOpenTasks();
      await pumpShell(tester);

      expect(find.byType(TasksHubScreen), findsOneWidget);
      expect(onScreen(tester, find.byType(TasksHubScreen)), isTrue);
      expect(
        Navigator.of(tester.element(find.byType(TasksHubScreen))).canPop(),
        isTrue,
      );
    },
  );
}
