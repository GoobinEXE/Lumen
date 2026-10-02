import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/theme/responsive.dart';
import '../../../../core/widgets/async_placeholders.dart';
import '../../domain/medication.dart';
import '../../domain/medication_log.dart';
import '../providers/medication_providers.dart';
import 'efficacy_window_bar.dart';

class MedicationCard extends ConsumerStatefulWidget {
  final Medication medication;
  final MedicationLog log;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.log,
  });

  @override
  ConsumerState<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends ConsumerState<MedicationCard> {
  bool _busyTaken = false;
  bool _busySnooze = false;

  Medication get medication => widget.medication;
  MedicationLog get log => widget.log;

  Future<void> _markTaken() async {
    if (_busyTaken || _busySnooze) return;
    HapticFeedback.lightImpact();
    setState(() => _busyTaken = true);
    final l10n = ref.read(appLocalizationsProvider);
    final timeFormat = DateFormat.Hm(l10n.localeName);
    try {
      await ref.read(todayMedicationLogsProvider.notifier).markTaken(log.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.medTakenRegisteredSnack(
              medication.name,
              timeFormat.format(DateTime.now()),
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyTaken = false);
    }
  }

  Future<void> _snooze() async {
    if (_busyTaken || _busySnooze) return;
    HapticFeedback.lightImpact();
    setState(() => _busySnooze = true);
    final l10n = ref.read(appLocalizationsProvider);
    try {
      await ref
          .read(todayMedicationLogsProvider.notifier)
          .snooze(log.id, medication.name, minutes: 15);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.snooze15mSnack),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _busySnooze = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final narrow = isNarrow(context);
    final timeFormat = DateFormat.Hm(l10n.localeName);

    final isTaken = log.isTaken;
    final isSkipped = log.skipped;
    final isSnoozed = !isSkipped && log.isSnoozed;
    final actionsBusy = _busyTaken || _busySnooze;

    final takeButton = Semantics(
      button: true,
      label: l10n.takeNowButton,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(0, 56),
        ),
        onPressed: actionsBusy ? null : _markTaken,
        icon: _busyTaken
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check, size: 18),
        label: Text(
          l10n.takeNowButton,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );

    final snoozeButton = Semantics(
      button: true,
      label: l10n.snooze15mButton,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white70 : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(0, kMinTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
        ),
        onPressed: actionsBusy ? null : _snooze,
        child: BusyButtonChild(
          busy: _busySnooze,
          spinnerColor: isDark ? Colors.white70 : Colors.black87,
          spinnerSize: 18,
          label: Text(
            l10n.snooze15mButton,
            style: const TextStyle(fontSize: kMinBodySecondary),
          ),
        ),
      ),
    );

    final skipButton = Semantics(
      button: true,
      label: l10n.skipDoseTooltip,
      child: IconButton(
        tooltip: l10n.skipDoseTooltip,
        constraints: const BoxConstraints(
          minWidth: kMinTapTarget,
          minHeight: kMinTapTarget,
        ),
        icon: const Icon(
          Icons.close_rounded,
          size: 20,
          color: AppColors.textMuted,
        ),
        onPressed: actionsBusy ? null : () => _showSkipDialog(context, ref),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTaken
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : (isSnoozed
                              ? AppColors.warning.withValues(alpha: 0.15)
                              : AppColors.accent.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                  child: Icon(
                    AppIcons.forMedicationShape(medication.shapeIcon),
                    size: 24,
                    color: isTaken
                        ? AppColors.primary
                        : (isSnoozed ? AppColors.warning : AppColors.accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              medication.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(
                                  AppRadii.chip,
                                ),
                              ),
                              child: Text(
                                medication.dosage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: kMinBodySecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        medication.instructions,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: kMinBodySecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isTaken
                    ? AppColors.primarySoft.withValues(
                        alpha: isDark ? 0.2 : 0.8,
                      )
                    : (isSnoozed
                          ? AppColors.warning.withValues(
                              alpha: isDark ? 0.15 : 0.12,
                            )
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.04))),
                borderRadius: BorderRadius.circular(AppRadii.input),
                border: Border.all(
                  color: isTaken
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : (isSnoozed
                            ? AppColors.warning.withValues(alpha: 0.5)
                            : Colors.transparent),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isTaken
                        ? Icons.check_circle_rounded
                        : (isSnoozed
                              ? Icons.snooze_rounded
                              : Icons.schedule_rounded),
                    size: 18,
                    color: isTaken
                        ? AppColors.primary
                        : (isSnoozed ? AppColors.warning : AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isTaken
                          ? l10n.takenTodayAt(timeFormat.format(log.takenAt!))
                          : (isSkipped
                                ? l10n.doseSkippedStatus
                                : (isSnoozed
                                      ? l10n.snoozedUntilTime(
                                          timeFormat.format(log.snoozedUntil!),
                                        )
                                      : l10n.pendingScheduled(
                                          timeFormat.format(log.scheduledTime),
                                        ))),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isTaken
                            ? AppColors.primary
                            : (isSnoozed ? AppColors.warning : null),
                      ),
                    ),
                  ),
                  Text(
                    l10n.capsulesCount(medication.remainingStock),
                    style: TextStyle(
                      fontSize: kMinBodySecondary,
                      fontWeight: FontWeight.w600,
                      color: medication.needsRefillWarning
                          ? AppColors.unstuck
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: medication.needsRefillWarning
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.unstuckSoft,
                          borderRadius: BorderRadius.circular(AppRadii.input),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: AppColors.unstuck,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                l10n.controlledRxRemainingAlert(
                                  medication.remainingStock,
                                ),
                                style: const TextStyle(
                                  fontSize: kMinBodySecondary,
                                  color: AppColors.unstuck,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isSkipped
                  ? const SizedBox.shrink(key: ValueKey('skipped'))
                  : ConstrainedBox(
                      key: ValueKey(isTaken ? 'efficacy' : 'actions'),
                      constraints: const BoxConstraints(minHeight: 56),
                      child: isTaken
                          ? EfficacyWindowBar(
                              log: log,
                              durationHours: medication.durationHours,
                            )
                          : (narrow
                                ? Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: takeButton,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(child: snoozeButton),
                                          const SizedBox(width: 4),
                                          skipButton,
                                        ],
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(flex: 3, child: takeButton),
                                      const SizedBox(width: 8),
                                      Expanded(flex: 2, child: snoozeButton),
                                      const SizedBox(width: 4),
                                      skipButton,
                                    ],
                                  )),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSkipDialog(BuildContext context, WidgetRef ref) {
    final l10n = ref.read(appLocalizationsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.skipDoseDialogTitle),
        content: Text(l10n.skipDoseDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref
                  .read(todayMedicationLogsProvider.notifier)
                  .skip(log.id, l10n.skipReasonVoluntary);
              Navigator.pop(ctx);
            },
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
  }
}
