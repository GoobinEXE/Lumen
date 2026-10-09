import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../../core/localization/l10n_labels.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../medications/domain/medication_log.dart';
import '../../medications/presentation/providers/medication_providers.dart';
import '../../routine_mood/domain/mood_entry.dart';
import '../../routine_mood/domain/routine_snapshot.dart';
import '../../routine_mood/presentation/routine_providers.dart';
import '../../state_of_mind/domain/state_of_mind_entry.dart';
import '../../state_of_mind/domain/state_of_mind_labels.dart';
import '../../tasks/domain/task_item.dart';
import '../../tasks/presentation/task_providers.dart';
import '../../../integrations/health/models/daily_recovery_snapshot.dart';
import '../../../integrations/health/models/sleep_record.dart';
import '../domain/profile_feed_item.dart';

/// Teto de itens no feed, por desempenho (ListView.builder cobre o resto).
const int kProfileFeedMaxItems = 90;

/// Monta o feed cronológico reverso do perfil a partir de tudo que o Lumen
/// guardou localmente e do que o app de saúde do aparelho espelhou.
///
/// Função pura: sem Riverpod nem BuildContext, para teste direto em Dart.
List<ProfileFeedItem> buildProfileFeed({
  required AppLocalizations l10n,
  required String languageCode,
  required List<MoodEntry> moodEntries,
  required List<RoutineSnapshot> snapshots,
  required List<SleepRecord> sleepRecords,
  required List<DailyRecoverySnapshot> recoverySnapshots,
  required List<MedicationLog> medicationLogs,
  required List<TaskItem> tasks,
  int maxItems = kProfileFeedMaxItems,
}) {
  final items = <ProfileFeedItem>[];

  for (final entry in moodEntries) {
    final focus = entry.focus.label(l10n);
    final energy = entry.energy.label(l10n);
    items.add(
      ProfileFeedItem(
        id: 'checkin_${entry.id}',
        timestamp: entry.timestamp,
        kind: ProfileFeedKind.checkIn,
        title: entry.valenceLabel(l10n),
        detail: '$focus · $energy',
        source: entry.emotionSource == StateOfMindSource.appleHealth
            ? ProfileFeedSource.health
            : ProfileFeedSource.local,
      ),
    );
  }

  for (final snapshot in snapshots) {
    final anchor = snapshot.mainFocusAnchor.trim();
    final reflection = snapshot.eveningReflection.trim();
    items.add(
      ProfileFeedItem(
        id: 'routine_${snapshot.id}',
        timestamp: snapshot.savedAt,
        kind: ProfileFeedKind.routine,
        title: anchor.isEmpty ? l10n.profileFeedRoutineTitle : anchor,
        detail: reflection.isEmpty ? null : reflection,
      ),
    );

    final som = snapshot.stateOfMind;
    if (som != null) {
      final labels = som.labels
          .map((id) => StateOfMindLabels.label(id, languageCode))
          .where((t) => t.isNotEmpty)
          .join(', ');
      items.add(
        ProfileFeedItem(
          id: 'som_${snapshot.id}',
          timestamp: som.timestamp,
          kind: ProfileFeedKind.stateOfMind,
          title: som.valenceLabel(l10n),
          detail: labels.isEmpty ? null : labels,
          source: som.source == StateOfMindSource.appleHealth
              ? ProfileFeedSource.health
              : ProfileFeedSource.local,
        ),
      );
    }
  }

  for (final sleep in sleepRecords) {
    items.add(
      ProfileFeedItem(
        id: 'sleep_${sleep.date.toIso8601String()}',
        timestamp: sleep.wakeTime,
        kind: ProfileFeedKind.sleep,
        title: l10n.profileFeedSleepTitle(sleep.totalHours.toStringAsFixed(1)),
        detail: l10n.profileFeedSleepDetail(sleep.qualityScore),
        source: ProfileFeedSource.health,
      ),
    );
  }

  for (final recovery in recoverySnapshots) {
    final parts = <String>[];
    if (recovery.hrvMs != null) {
      parts.add(l10n.profileFeedRecoveryHrv(recovery.hrvMs!.toStringAsFixed(0)));
    }
    if (recovery.steps != null) {
      parts.add(l10n.profileFeedRecoverySteps(recovery.steps!));
    }
    if (parts.isEmpty) continue;
    items.add(
      ProfileFeedItem(
        id: 'recovery_${recovery.date.toIso8601String()}',
        timestamp: recovery.date,
        kind: ProfileFeedKind.recovery,
        title: l10n.profileFeedRecoveryTitle,
        detail: parts.join(' · '),
        source: ProfileFeedSource.health,
      ),
    );
  }

  for (final log in medicationLogs) {
    if (!log.isTaken && !log.skipped) continue;
    items.add(
      ProfileFeedItem(
        id: 'dose_${log.id}',
        timestamp: log.takenAt ?? log.scheduledTime,
        kind: ProfileFeedKind.dose,
        title: log.medicationName,
        detail: log.isTaken
            ? l10n.profileFeedDoseTaken
            : l10n.profileFeedDoseSkipped,
        source: log.source == MedicationLogSource.appleHealth
            ? ProfileFeedSource.health
            : ProfileFeedSource.local,
      ),
    );
  }

  for (final task in tasks) {
    if (!task.active) continue;
    final key = task.completedPeriodKey;
    if (key == null || key.isEmpty) continue;
    final when = _taskCompletionDate(key);
    if (when == null) continue;
    items.add(
      ProfileFeedItem(
        id: 'task_${task.id}_$key',
        timestamp: when,
        kind: ProfileFeedKind.task,
        title: task.title,
        detail: l10n.profileFeedTaskDone,
      ),
    );
  }

  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  if (items.length > maxItems) {
    return items.sublist(0, maxItems);
  }
  return items;
}

/// Converte a chave de janela da tarefa (`2026-10-03`, `B2026-09-30`,
/// `2026-W40`, `2026-10`) em um instante representativo do dia concluído.
DateTime? _taskCompletionDate(String key) {
  final day = RegExp(r'^B?(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (day != null) {
    return DateTime(
      int.parse(day.group(1)!),
      int.parse(day.group(2)!),
      int.parse(day.group(3)!),
      12,
    );
  }
  final week = RegExp(r'^(\d{4})-W(\d{2})$').firstMatch(key);
  if (week != null) {
    final year = int.parse(week.group(1)!);
    final weekNumber = int.parse(week.group(2)!);
    final jan4 = DateTime(year, 1, 4);
    final week1Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
    return week1Monday.add(Duration(days: (weekNumber - 1) * 7, hours: 12));
  }
  final month = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(key);
  if (month != null) {
    return DateTime(int.parse(month.group(1)!), int.parse(month.group(2)!), 1, 12);
  }
  return null;
}

/// Feed do perfil. Saúde recusada não quebra nada: entra o que for local.
final profileFeedProvider =
    FutureProvider<List<ProfileFeedItem>>((ref) async {
  final l10n = ref.watch(appLocalizationsProvider);
  final languageCode = ref.watch(activeLocaleProvider).languageCode;

  final moodEntries = ref.watch(moodEntriesProvider).value ?? const [];
  final tasks = ref.watch(tasksListProvider).value ?? const [];
  final snapshots =
      await ref.watch(recentRoutineSnapshotsProvider.future);

  // Capear fontes antes do merge — evita materializar anos de logs.
  final allMedLogs =
      await ref.watch(medicationRepositoryProvider).getAllLogs();
  final medLogs = allMedLogs.length > kProfileFeedMaxItems
      ? allMedLogs.sublist(allMedLogs.length - kProfileFeedMaxItems)
      : allMedLogs;
  final cappedMood = moodEntries.length > kProfileFeedMaxItems
      ? moodEntries.sublist(0, kProfileFeedMaxItems)
      : moodEntries;
  final cappedSnapshots = snapshots.length > kProfileFeedMaxItems
      ? snapshots.sublist(snapshots.length - kProfileFeedMaxItems)
      : snapshots;

  List<SleepRecord> sleep = const [];
  try {
    sleep = await ref.watch(sleepHistoryProvider.future);
  } catch (_) {
    sleep = const [];
  }

  List<DailyRecoverySnapshot> recovery = const [];
  try {
    recovery = await ref.watch(recoveryHistoryProvider.future);
  } catch (_) {
    recovery = const [];
  }

  return buildProfileFeed(
    l10n: l10n,
    languageCode: languageCode,
    moodEntries: cappedMood,
    snapshots: cappedSnapshots,
    sleepRecords: sleep,
    recoverySnapshots: recovery,
    medicationLogs: medLogs,
    tasks: tasks,
  );
});
