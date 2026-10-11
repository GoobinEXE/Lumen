import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/profile/domain/profile_feed_item.dart';
import 'package:noa/features/profile/presentation/profile_feed_providers.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
import 'package:noa/features/tasks/domain/task_period.dart';
import 'package:noa/integrations/health/models/daily_recovery_snapshot.dart';
import 'package:noa/integrations/health/models/sleep_record.dart';
import 'package:noa/l10n/app_localizations_pt.dart';

void main() {
  final l10n = AppLocalizationsPt();

  List<ProfileFeedItem> build({
    List<MoodEntry> mood = const [],
    List<RoutineSnapshot> snapshots = const [],
    List<SleepRecord> sleep = const [],
    List<DailyRecoverySnapshot> recovery = const [],
    List<MedicationLog> logs = const [],
    List<TaskItem> tasks = const [],
    int maxItems = kProfileFeedMaxItems,
  }) {
    return buildProfileFeed(
      l10n: l10n,
      languageCode: 'pt',
      moodEntries: mood,
      snapshots: snapshots,
      sleepRecords: sleep,
      recoverySnapshots: recovery,
      medicationLogs: logs,
      tasks: tasks,
      maxItems: maxItems,
    );
  }

  test('ordena do mais recente para o mais antigo', () {
    final feed = build(
      mood: [
        MoodEntry(
          id: 'a',
          timestamp: DateTime(2026, 10, 1, 9),
          valence: 4,
          energy: EnergyLevel.balanced,
          focus: FocusState.focused,
        ),
        MoodEntry(
          id: 'b',
          timestamp: DateTime(2026, 10, 3, 9),
          valence: 2,
          energy: EnergyLevel.low,
          focus: FocusState.scattered,
        ),
      ],
    );

    expect(feed.length, 2);
    expect(feed.first.id, 'checkin_b');
    expect(feed.last.id, 'checkin_a');
    expect(feed.first.timestamp.isAfter(feed.last.timestamp), isTrue);
  });

  test('cada fonte vira o seu kind, e SoM do snapshot entra separado', () {
    final feed = build(
      mood: [
        MoodEntry(
          id: 'm',
          timestamp: DateTime(2026, 10, 2, 8),
          valence: 3,
          energy: EnergyLevel.balanced,
          focus: FocusState.focused,
        ),
      ],
      snapshots: [
        RoutineSnapshot(
          id: 's',
          savedAt: DateTime(2026, 10, 2, 10),
          mainFocusAnchor: 'Escrever',
          stateOfMind: StateOfMindEntry(
            valence: 0.5,
            labels: const {'calm'},
            timestamp: DateTime(2026, 10, 2, 11),
          ),
        ),
      ],
      sleep: [
        SleepRecord(
          date: DateTime(2026, 10, 2),
          bedtime: DateTime(2026, 10, 1, 23),
          wakeTime: DateTime(2026, 10, 2, 7),
          totalSleep: const Duration(hours: 8),
        ),
      ],
      recovery: [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 2),
          hrvMs: 55,
          steps: 8000,
        ),
      ],
      logs: [
        MedicationLog(
          id: 'd',
          medicationId: 'med',
          medicationName: 'Ritalina',
          scheduledTime: DateTime(2026, 10, 2, 9),
          takenAt: DateTime(2026, 10, 2, 9, 5),
        ),
      ],
      tasks: [
        const TaskItem(
          id: 't',
          title: 'Beber água',
          completedPeriodKey: '2026-10-02',
        ),
      ],
    );

    final kinds = feed.map((e) => e.kind).toSet();
    expect(kinds, {
      ProfileFeedKind.checkIn,
      ProfileFeedKind.routine,
      ProfileFeedKind.stateOfMind,
      ProfileFeedKind.sleep,
      ProfileFeedKind.recovery,
      ProfileFeedKind.dose,
      ProfileFeedKind.task,
    });
  });

  test('sono e recuperação marcam origem no app de saúde', () {
    final feed = build(
      sleep: [
        SleepRecord(
          date: DateTime(2026, 10, 2),
          bedtime: DateTime(2026, 10, 1, 23),
          wakeTime: DateTime(2026, 10, 2, 7),
          totalSleep: const Duration(hours: 7),
        ),
      ],
      recovery: [
        DailyRecoverySnapshot(date: DateTime(2026, 10, 2), steps: 5000),
      ],
    );

    expect(feed.every((e) => e.source == ProfileFeedSource.health), isTrue);
  });

  test('dose pendente não entra; só tomada ou pulada', () {
    final feed = build(
      logs: [
        MedicationLog(
          id: 'pending',
          medicationId: 'med',
          medicationName: 'Dose A',
          scheduledTime: DateTime(2026, 10, 2, 9),
        ),
        MedicationLog(
          id: 'skipped',
          medicationId: 'med',
          medicationName: 'Dose B',
          scheduledTime: DateTime(2026, 10, 2, 12),
          skipped: true,
        ),
      ],
    );

    expect(feed.length, 1);
    expect(feed.single.id, 'dose_skipped');
  });

  test('respeita o teto de itens', () {
    final mood = List<MoodEntry>.generate(
      10,
      (i) => MoodEntry(
        id: 'm$i',
        timestamp: DateTime(2026, 10, 1).add(Duration(hours: i)),
        valence: 3,
        energy: EnergyLevel.balanced,
        focus: FocusState.focused,
      ),
    );

    final feed = build(mood: mood, maxItems: 4);
    expect(feed.length, 4);
    // Mantém os mais recentes.
    expect(feed.first.id, 'checkin_m9');
  });

  test('chave de semana, quinzena e mês vira o meio-dia da âncora', () {
    final yearTurn = TaskPeriod.window(
      recurrence: TaskRecurrence.weekly,
      now: DateTime(2025, 12, 31, 18),
    );
    final october = TaskPeriod.window(
      recurrence: TaskRecurrence.weekly,
      now: DateTime(2026, 10, 7, 15),
    );
    final fortnight = TaskPeriod.window(
      recurrence: TaskRecurrence.biweekly,
      now: DateTime(2026, 10, 7, 11),
    );
    final month = TaskPeriod.window(
      recurrence: TaskRecurrence.monthly,
      now: DateTime(2026, 10, 31, 23),
    );

    expect(yearTurn.periodKey, '2026-W01');
    expect(yearTurn.start, DateTime(2025, 12, 29));
    expect(october.periodKey, '2026-W41');
    expect(october.start, DateTime(2026, 10, 5));
    expect(fortnight.periodKey, 'B2026-10-05');
    expect(month.periodKey, '2026-10');

    final feed = build(
      tasks: [
        TaskItem(
          id: 'ano',
          title: 'Fechar o ano',
          recurrence: TaskRecurrence.weekly,
          completedPeriodKey: yearTurn.periodKey,
        ),
        TaskItem(
          id: 'out',
          title: 'Relatório',
          recurrence: TaskRecurrence.weekly,
          completedPeriodKey: october.periodKey,
        ),
        TaskItem(
          id: 'quinzena',
          title: 'Revisão',
          recurrence: TaskRecurrence.biweekly,
          completedPeriodKey: fortnight.periodKey,
        ),
        TaskItem(
          id: 'mes',
          title: 'Conta',
          recurrence: TaskRecurrence.monthly,
          completedPeriodKey: month.periodKey,
        ),
      ],
    );

    DateTime at(String id) =>
        feed.firstWhere((item) => item.id == id).timestamp;

    expect(feed, hasLength(4));
    expect(at('task_ano_2026-W01'), DateTime(2025, 12, 29, 12));
    expect(at('task_out_2026-W41'), DateTime(2026, 10, 5, 12));
    expect(at('task_quinzena_B2026-10-05'), DateTime(2026, 10, 5, 12));
    expect(at('task_mes_2026-10'), DateTime(2026, 10, 1, 12));
    expect(feed.first.timestamp, DateTime(2026, 10, 5, 12));
    expect(feed.last.timestamp, DateTime(2025, 12, 29, 12));
  });

  test('chave ilegível e tarefa pausada não entram no feed', () {
    final feed = build(
      tasks: const [
        TaskItem(id: 'lixo', title: 'Nada', completedPeriodKey: '2026-W1'),
        TaskItem(id: 'texto', title: 'Nada', completedPeriodKey: 'semana'),
        TaskItem(
          id: 'pausada',
          title: 'Ler',
          active: false,
          completedPeriodKey: '2026-10-02',
        ),
        TaskItem(id: 'aberta', title: 'Caminhar', completedPeriodKey: ''),
      ],
    );

    expect(feed, isEmpty);
  });

  test('recuperação sem HRV e sem passos fica de fora', () {
    final feed = build(
      recovery: [
        DailyRecoverySnapshot(
          date: DateTime(2026, 10, 2),
          restingHeartRate: 62,
          exerciseMinutes: 20,
        ),
      ],
    );

    expect(feed, isEmpty);
  });

  test('check-in e dose do app de saúde marcam a origem', () {
    final feed = build(
      mood: [
        MoodEntry(
          id: 'local',
          timestamp: DateTime(2026, 10, 2, 8),
          valence: 3,
          energy: EnergyLevel.balanced,
          focus: FocusState.focused,
        ),
        MoodEntry(
          id: 'apple',
          timestamp: DateTime(2026, 10, 2, 19),
          valence: 4,
          energy: EnergyLevel.energized,
          focus: FocusState.focused,
          emotionSource: StateOfMindSource.appleHealth,
        ),
      ],
      logs: [
        MedicationLog(
          id: 'tomada',
          medicationId: 'med',
          medicationName: 'Lisdex',
          scheduledTime: DateTime(2026, 10, 2, 9),
          takenAt: DateTime(2026, 10, 2, 9, 40),
          source: MedicationLogSource.appleHealth,
        ),
        MedicationLog(
          id: 'pulada',
          medicationId: 'med',
          medicationName: 'Lisdex',
          scheduledTime: DateTime(2026, 10, 2, 21),
          skipped: true,
        ),
      ],
    );

    final appleCheckIn = feed.firstWhere((item) => item.id == 'checkin_apple');
    final localCheckIn = feed.firstWhere((item) => item.id == 'checkin_local');
    final taken = feed.firstWhere((item) => item.id == 'dose_tomada');
    final skipped = feed.firstWhere((item) => item.id == 'dose_pulada');

    expect(appleCheckIn.source, ProfileFeedSource.health);
    expect(localCheckIn.source, ProfileFeedSource.local);
    expect(taken.source, ProfileFeedSource.health);
    expect(taken.timestamp, DateTime(2026, 10, 2, 9, 40));
    expect(taken.detail, l10n.profileFeedDoseTaken);
    expect(skipped.source, ProfileFeedSource.local);
    expect(skipped.timestamp, DateTime(2026, 10, 2, 21));
    expect(skipped.detail, l10n.profileFeedDoseSkipped);
  });

  test(
    'âncora em branco usa o título da rotina e SoM sem rótulo não inventa detalhe',
    () {
      final feed = build(
        snapshots: [
          RoutineSnapshot(
            id: 's',
            savedAt: DateTime(2026, 10, 2, 22),
            mainFocusAnchor: '   ',
            eveningReflection: '  ',
            stateOfMind: StateOfMindEntry(
              timestamp: DateTime(2026, 10, 2, 22, 5),
              source: StateOfMindSource.appleHealth,
            ),
          ),
        ],
      );

      final routine = feed.firstWhere((item) => item.id == 'routine_s');
      final som = feed.firstWhere((item) => item.id == 'som_s');
      expect(routine.title, l10n.profileFeedRoutineTitle);
      expect(routine.detail, isNull);
      expect(som.detail, isNull);
      expect(som.source, ProfileFeedSource.health);
      expect(som.timestamp, DateTime(2026, 10, 2, 22, 5));
    },
  );
}
