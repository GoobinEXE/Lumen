import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:noa/core/localization/locale_provider.dart';
import 'package:noa/core/providers.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/routine_mood/presentation/routine_providers.dart';
import 'package:noa/features/therapist_export/presentation/clinical_folder_screen.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smoke/widget da Pasta clínica (Fase 0.3): o toggle "Ocultar notas
/// íntimas" existe, começa ligado por padrão (seguro) e, ao desligar,
/// revela a seção "Para a terapia" com pauta/fechamento do snapshot —
/// sem disparar nenhum share real (WhatsApp/PDF ficam intocados).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (call) async => 'America/Sao_Paulo',
    );
    await initializeDateFormatting('pt');
    l10n = lookupAppLocalizations(const Locale('pt'));
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      null,
    );
  });

  /// Snapshot de hoje com pauta e fechamento, para o toggle ter algo para
  /// revelar/esconder. Formato igual ao `RoutineSnapshot.toMap()`.
  Map<String, dynamic> snapshotMapOf(DateTime savedAt) => {
    'id': 'snap-intimo',
    'savedAt': savedAt.toIso8601String(),
    'mainFocusAnchor': 'Fechar relatório',
    'eveningReflection': 'Fechei o dia exausto, mas terminei a tarefa.',
    'microHabits': <String>[],
    'completedHabits': <String>[],
    'waterGlasses': 2,
    'tookPrescribedMedication': true,
    'therapistNotes': 'Falar sobre ansiedade antes de dormir.',
  };

  Future<void> pumpClinicalFolder(WidgetTester tester) async {
    final now = DateTime.now();
    final key = 'noa_daily_routine_${now.year}_${now.month}_${now.day}';
    SharedPreferences.setMockInitialValues({
      'noa_onboarding_done_v1': true,
      key: jsonEncode([snapshotMapOf(now)]),
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('noa_onboarding_done_v1', true);
    await prefs.setString(key, jsonEncode([snapshotMapOf(now)]));

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
          recentRoutineSnapshotsProvider.overrideWith(
            (ref) async => [
              RoutineSnapshot.fromMap(snapshotMapOf(now)),
            ],
          ),
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
          home: const ClinicalFolderScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'mostra o toggle de notas íntimas, desligado por padrão',
    (tester) async {
      await pumpClinicalFolder(tester);

      final toggleFinder = find.byType(SwitchListTile);
      expect(toggleFinder, findsOneWidget);
      expect(find.text(l10n.hideIntimateNotes), findsOneWidget);
      expect(find.text(l10n.hideIntimateNotesHelp), findsOneWidget);

      final switchTile = tester.widget<SwitchListTile>(toggleFinder);
      expect(switchTile.value, isTrue);

      // Padrão seguro: pauta/fechamento não aparecem na pasta.
      expect(find.text(l10n.therapyNotesSectionTitle), findsNothing);
    },
  );

  testWidgets(
    'desligar o toggle revela a seção de pauta/fechamento para a terapia',
    (tester) async {
      await pumpClinicalFolder(tester);

      expect(find.text(l10n.therapyNotesSectionTitle), findsNothing);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isFalse);

      // Com o toggle desligado, a seção "Para a terapia" aparece com a
      // pauta e o fechamento do snapshot do dia.
      expect(find.text(l10n.therapyNotesSectionTitle), findsOneWidget);
      expect(
        find.textContaining('Fechei o dia exausto'),
        findsWidgets,
      );
      expect(
        find.textContaining('Falar sobre ansiedade antes de dormir'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'religar o toggle esconde de novo a pauta/fechamento',
    (tester) async {
      await pumpClinicalFolder(tester);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text(l10n.therapyNotesSectionTitle), findsOneWidget);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
      expect(find.text(l10n.therapyNotesSectionTitle), findsNothing);
    },
  );

  testWidgets(
    'mostra chips de estilo do PDF e o botão de compartilhar',
    (tester) async {
      await pumpClinicalFolder(tester);

      expect(find.text(l10n.pdfStyleSectionLabel), findsOneWidget);
      expect(find.text(l10n.pdfStyleClinicalLabel), findsOneWidget);
      expect(find.text(l10n.pdfStyleLumenLabel), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(l10n.sharePdfButton),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l10n.sharePdfButton), findsOneWidget);
      expect(find.text(l10n.viewPdfButton), findsOneWidget);
    },
  );
}
