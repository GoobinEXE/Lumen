import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../medications/domain/medication_log.dart';
import '../../routine_mood/domain/mood_entry.dart';
import '../../routine_mood/presentation/routine_snapshot_card.dart';
import '../../state_of_mind/domain/state_of_mind_associations.dart';
import '../../state_of_mind/domain/state_of_mind_labels.dart';
import 'day_digest_providers.dart';

Future<void> showDayDigestSheet(BuildContext context, DateTime day) {
  return showLumenSheet<void>(
    context: context,
    builder: (context) => LumenKeyboardInset(
      child: DayDigestSheet(day: day),
    ),
  );
}

class DayDigestSheet extends ConsumerWidget {
  const DayDigestSheet({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final lang = ref.watch(activeLocaleProvider).languageCode;
    final digestAsync = ref.watch(dayDigestProvider(day));
    final label = DateFormat.yMMMMEEEEd(l10n.localeName).format(day);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.sheetTop,
              AppSpacing.screenH,
              AppSpacing.sheetBottom,
            ),
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l10n.dayDigestTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              digestAsync.when(
                loading: () => const FormSkeleton(),
                error: (err, _) => Text(l10n.errorWithDetails('$err')),
                data: (digest) {
                  if (digest.isEmpty) {
                    return Text(l10n.dayDigestEmpty);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Section(
                        title: l10n.dayDigestCheckInsTitle,
                        child: digest.checkIns.isEmpty
                            ? Text(l10n.dayDigestCheckInsEmpty)
                            : Column(
                                children: [
                                  for (final entry in digest.checkIns)
                                    _CheckInTile(
                                      entry: entry,
                                      languageCode: lang,
                                      noteLabel: l10n.dayDigestNoteLabel,
                                      isDark: isDark,
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        title: l10n.dayDigestSomTitle,
                        child: digest.latestStateOfMind == null
                            ? Text(l10n.dayDigestSomEmpty)
                            : _SomBlock(
                                labels: digest.latestStateOfMind!.labels,
                                associations:
                                    digest.latestStateOfMind!.associations,
                                languageCode: lang,
                              ),
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        title: l10n.dayDigestRoutineTitle,
                        child: digest.snapshots.isEmpty
                            ? Text(l10n.dayDigestRoutineEmpty)
                            : Column(
                                children: [
                                  for (final snapshot in digest.snapshots)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: RoutineSnapshotCard(
                                        snapshot: snapshot,
                                        showDate: true,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        title: l10n.dayDigestMedsTitle,
                        child: digest.medicationLogs.isEmpty
                            ? Text(l10n.dayDigestMedsEmpty)
                            : Column(
                                children: [
                                  for (final log in digest.medicationLogs)
                                    _MedTile(log: log, isDark: isDark),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        title: l10n.dayDigestTasksTitle,
                        child: digest.completedTaskTitles.isEmpty
                            ? Text(l10n.dayDigestTasksEmpty)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final title
                                      in digest.completedTaskTitles)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            AppIcons.tasks,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(title)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _CheckInTile extends StatelessWidget {
  const _CheckInTile({
    required this.entry,
    required this.languageCode,
    required this.noteLabel,
    required this.isDark,
  });

  final MoodEntry entry;
  final String languageCode;
  final String Function(String note) noteLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm(
      Localizations.localeOf(context).toString(),
    ).format(entry.timestamp);
    final labels = entry.emotionLabels
        .map((id) => StateOfMindLabels.label(id, languageCode))
        .where((t) => t.isNotEmpty)
        .join(', ');
    final note = entry.note?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.forValence(entry.valence), color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: Theme.of(context).textTheme.labelMedium),
                if (labels.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(labels),
                ],
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    noteLabel(note),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SomBlock extends StatelessWidget {
  const _SomBlock({
    required this.labels,
    required this.associations,
    required this.languageCode,
  });

  final Set<String> labels;
  final Set<String> associations;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final labelText = labels
        .map((id) => StateOfMindLabels.label(id, languageCode))
        .where((t) => t.isNotEmpty)
        .join(', ');
    final assocText = associations
        .map((id) => StateOfMindAssociations.label(id, languageCode))
        .where((t) => t.isNotEmpty)
        .join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText.isNotEmpty) Text(labelText),
        if (assocText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(assocText, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _MedTile extends StatelessWidget {
  const _MedTile({required this.log, required this.isDark});

  final MedicationLog log;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.Hm().format(log.scheduledTime);
    final status = log.isTaken && log.takenAt != null
        ? DateFormat.Hm().format(log.takenAt!)
        : time;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            AppIcons.medication,
            size: 20,
            color: log.isTaken
                ? AppColors.primary
                : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(log.medicationName)),
          Text(status, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
