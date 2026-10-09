import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:noa/core/localization/locale_provider.dart';
import 'package:noa/core/providers.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/presentation/task_editor_sheet.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    await initializeDateFormatting('pt');
    l10n = lookupAppLocalizations(const Locale('pt'));
  });

  Future<void> pumpEditor(WidgetTester tester, {TaskItem? existing}) async {
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(390, 1600);
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
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => TaskEditorSheet.show(context, existing: existing),
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
    'tarefa com horário mostra nota + link de horário silencioso e nota de app fechado',
    (tester) async {
      final withTime = TaskItem(
        id: 't1',
        title: 'Tomar água',
        timeOfDay: '09:00',
      );
      await pumpEditor(tester, existing: withTime);

      expect(find.text(l10n.taskQuietHoursEditorNote), findsOneWidget);
      expect(find.text(l10n.taskQuietHoursEditorLink), findsOneWidget);
      expect(find.text(l10n.taskReminderClosedAppNote), findsOneWidget);

      await tester.tap(find.text(l10n.taskQuietHoursEditorLink));
      await tester.pumpAndSettle();

      expect(find.text(l10n.taskQuietHoursTitle), findsOneWidget);
    },
  );

  testWidgets(
    'tarefa sem horário não mostra nota de horário silencioso nem de app fechado',
    (tester) async {
      final withoutTime = TaskItem(id: 't2', title: 'Ler um pouco');
      await pumpEditor(tester, existing: withoutTime);

      expect(find.text(l10n.taskQuietHoursEditorNote), findsNothing);
      expect(find.text(l10n.taskQuietHoursEditorLink), findsNothing);
      expect(find.text(l10n.taskReminderClosedAppNote), findsNothing);
    },
  );
}
