import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../domain/routine_snapshot.dart';

class RoutineSnapshotCard extends StatelessWidget {
  const RoutineSnapshotCard({
    super.key,
    required this.snapshot,
    this.showDate = false,
  });

  final RoutineSnapshot snapshot;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = AppColors.mutedText(isDark);
    final locale = l10n.localeName;
    final clock = DateFormat('HH:mm', locale).format(snapshot.savedAt);
    final when = showDate
        ? '${DateFormat.yMMMd(locale).format(snapshot.savedAt)} · $clock'
        : clock;
    final anchor = snapshot.mainFocusAnchor.trim().isEmpty
        ? l10n.exportRoutineAnchorEmpty
        : snapshot.mainFocusAnchor.trim();
    final habits = snapshot.completedHabits.toList()..sort();

    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            when,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(anchor, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.exportRoutineWater(snapshot.waterGlasses),
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            habits.isEmpty
                ? l10n.exportRoutineHabitsNone
                : l10n.exportRoutineHabits(habits.join(', ')),
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            snapshot.tookPrescribedMedication
                ? l10n.exportRoutineMedYes
                : l10n.exportRoutineMedNo,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          if (snapshot.eveningReflection.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.exportRoutineReflection(snapshot.eveningReflection.trim()),
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if ((snapshot.therapistNotes?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              l10n.exportRoutineNotes(snapshot.therapistNotes!.trim()),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
