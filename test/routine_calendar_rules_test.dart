import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/routine_mood/data/micro_habits_prefs.dart';
import 'package:noa/features/routine_mood/data/routine_repository.dart';
import 'package:noa/features/routine_mood/domain/daily_routine_state.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/integrations/calendar/device_calendar.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.prism.lumen/calendar_bridge');
  final l10n = lookupAppLocalizations(const Locale('pt'));

  RoutineSnapshot shot({
    required String id,
    required DateTime savedAt,
    StateOfMindEntry? stateOfMind,
    List<String> habits = const ['Água'],
  }) {
    return RoutineSnapshot.capture(
      id: id,
      savedAt: savedAt,
      draft: DailyRoutineState(
        date: DateTime(savedAt.year, savedAt.month, savedAt.day),
        mainFocusAnchor: '  $id  ',
        microHabits: habits,
        stateOfMind: stateOfMind,
      ),
    );
  }

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('a janela da rotina usa o dia e ignora item que não é mapa', () async {
    SharedPreferences.setMockInitialValues({
      'noa_daily_routine_2026_9_19': jsonEncode([
        {
          'id': 'velho',
          'savedAt': '2026-09-19T21:00:00.000',
          'mainFocusAnchor': 'Ontem',
        },
      ]),
      'noa_daily_routine_2026_9_20': jsonEncode([
        null,
        {
          'id': 'manha',
          'savedAt': '2026-09-20T08:00:00.000',
          'mainFocusAnchor': 'Manhã',
        },
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);

    final since = repo.snapshotsSince(DateTime(2026, 9, 20, 18));

    expect(since.map((item) => item.id), ['manha']);
    expect(repo.getSnapshotsForDate(DateTime(2026, 9, 20)), hasLength(1));
  });

  test(
    'JSON quebrado não marca o dia e o hábito salvo vira o modelo',
    () async {
      SharedPreferences.setMockInitialValues({
        'noa_daily_routine_2026_9_21': '{',
        'noa_mood_entries_v2': '[]',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = RoutineRepository(prefs);

      expect(repo.markedDays(), isEmpty);
      expect(repo.getSnapshotsForDate(DateTime(2026, 9, 21)), isEmpty);

      await repo.appendSnapshot(
        shot(
          id: 'tarde',
          savedAt: DateTime(2026, 9, 21, 16),
          habits: const ['Caminhar'],
        ),
      );

      expect(getMicroHabitsTemplate(prefs, l10n), ['Caminhar']);
      expect(repo.markedDays(), {DateTime(2026, 9, 21)});
    },
  );

  test(
    'lista vazia de hábitos permanece vazia e JSON ruim volta ao padrão',
    () async {
      SharedPreferences.setMockInitialValues({microHabitsTemplateKey: '[]'});
      final emptyPrefs = await SharedPreferences.getInstance();
      expect(getMicroHabitsTemplate(emptyPrefs, l10n), isEmpty);

      SharedPreferences.setMockInitialValues({microHabitsTemplateKey: '{'});
      final brokenPrefs = await SharedPreferences.getInstance();
      final fallback = getMicroHabitsTemplate(brokenPrefs, l10n);

      expect(fallback, hasLength(4));
      expect(fallback, contains(l10n.microHabitStretch));
    },
  );

  test('o id do evento gruda só no salvamento certo', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = RoutineRepository(prefs);
    final morning = DateTime(2026, 9, 22, 9);
    final evening = DateTime(2026, 9, 22, 20);
    await repo.appendSnapshot(shot(id: 'a', savedAt: morning));
    await repo.appendSnapshot(shot(id: 'b', savedAt: evening));

    await repo.setCalendarEventId(
      savedAt: evening,
      snapshotId: 'b',
      eventId: 'evt-b',
    );
    await repo.setCalendarEventId(
      savedAt: evening,
      snapshotId: 'sumiu',
      eventId: 'evt-x',
    );

    final day = repo.getSnapshotsForDate(evening);
    expect(day.firstWhere((item) => item.id == 'a').calendarEventId, isNull);
    expect(day.firstWhere((item) => item.id == 'b').calendarEventId, 'evt-b');
  });

  test(
    'State of Mind da Apple conta o dia uma vez dentro de 14 dias',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = RoutineRepository(prefs);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 12);
      StateOfMindEntry apple(DateTime at) {
        return StateOfMindEntry(
          valence: 0.2,
          timestamp: at,
          source: StateOfMindSource.appleHealth,
        );
      }

      await repo.appendSnapshot(
        shot(id: 'hoje-1', savedAt: today, stateOfMind: apple(today)),
      );
      await repo.appendSnapshot(
        shot(
          id: 'hoje-2',
          savedAt: today.add(const Duration(hours: 2)),
          stateOfMind: apple(today),
        ),
      );
      await repo.appendSnapshot(
        shot(
          id: 'lumen',
          savedAt: today.subtract(const Duration(days: 1)),
          stateOfMind: StateOfMindEntry(valence: 0, timestamp: today),
        ),
      );
      await repo.appendSnapshot(
        shot(
          id: 'limite',
          savedAt: today.subtract(const Duration(days: 13)),
          stateOfMind: apple(today.subtract(const Duration(days: 13))),
        ),
      );
      await repo.appendSnapshot(
        shot(
          id: 'velho',
          savedAt: today.subtract(const Duration(days: 14)),
          stateOfMind: apple(today.subtract(const Duration(days: 14))),
        ),
      );

      expect(repo.countAppleHealthStateOfMind(), 2);
    },
  );

  test(
    'âncora em branco usa o título genérico e reflexão vazia fica de fora',
    () {
      final snapshot = RoutineSnapshot(
        id: 's',
        savedAt: DateTime(2026, 9, 22, 9),
        mainFocusAnchor: '   ',
        eveningReflection: '   ',
        waterGlasses: 2,
      );

      expect(routineCalendarTitle(l10n, snapshot), 'Rotina');
      final notes = routineCalendarNotes(l10n, snapshot);
      expect(notes, contains('Água: 2 copos'));
      expect(notes, contains('Medicação prescrita: não tomada'));
      expect(notes, isNot(contains('Como o dia fechou')));
    },
  );

  test('recusa do calendário não pede acesso de novo', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var requests = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'hasAccess') return false;
          if (call.method == 'requestAccess') {
            requests++;
            return false;
          }
          return null;
        });

    final calendar = DeviceCalendar();
    final first = await calendar.createRoutineEvent(
      prefs: prefs,
      title: 'Rotina',
      start: DateTime(2026, 9, 22, 9),
      notes: '',
    );
    final second = await calendar.createRoutineEvent(
      prefs: prefs,
      title: 'Rotina',
      start: DateTime(2026, 9, 22, 9),
      notes: '',
    );

    expect(first, isNull);
    expect(second, isNull);
    expect(requests, 1);
    expect(prefs.getBool(calendarAccessPromptedKey), isTrue);
  });

  test(
    'com acesso o evento dura 30 minutos e falha do canal volta nulo',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final start = DateTime(2026, 9, 22, 9);
      Map<dynamic, dynamic>? payload;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'hasAccess') return true;
            if (call.method == 'createEvent') {
              payload = Map<dynamic, dynamic>.from(call.arguments as Map);
              return 'evt-1';
            }
            return null;
          });

      final created = await DeviceCalendar().createRoutineEvent(
        prefs: prefs,
        title: 'Escrever',
        start: start,
        notes: 'água',
      );

      expect(created, 'evt-1');
      expect(payload?['title'], 'Escrever');
      expect(payload?['startMs'], start.millisecondsSinceEpoch);
      expect(
        payload?['endMs'],
        start.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(code: 'calendar');
          });
      final failed = await DeviceCalendar().createRoutineEvent(
        prefs: prefs,
        title: 'Escrever',
        start: start,
        notes: '',
      );
      expect(failed, isNull);
    },
  );
}
