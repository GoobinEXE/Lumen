import 'package:flutter_test/flutter_test.dart';
import 'package:noa/features/medications/domain/medication_log.dart';
import 'package:noa/features/profile/domain/profile_feed_item.dart';
import 'package:noa/features/profile/presentation/profile_feed_providers.dart';
import 'package:noa/features/routine_mood/domain/mood_entry.dart';
import 'package:noa/features/routine_mood/domain/routine_snapshot.dart';
import 'package:noa/features/state_of_mind/domain/state_of_mind_entry.dart';
import 'package:noa/features/tasks/domain/task_item.dart';
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
    expect(
      feed.first.timestamp.isAfter(feed.last.timestamp),
      isTrue,
    );
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
}
