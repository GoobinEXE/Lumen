import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../domain/medication.dart';
import '../domain/medication_log.dart';
import 'providers/medication_providers.dart';
import 'widgets/add_medication_sheet.dart';
import 'widgets/medication_card.dart';

class MedicationsScreen extends ConsumerStatefulWidget {
  const MedicationsScreen({super.key});

  @override
  ConsumerState<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends ConsumerState<MedicationsScreen> {
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todayMedicationLogsProvider.notifier).refreshAppleHealthDoses();
    });
  }

  Future<void> _importFromHealth() async {
    if (_importing) return;
    setState(() => _importing = true);
    final l10n = ref.read(appLocalizationsProvider);
    try {
      final available = await ref.read(appleHealthMedsAvailableProvider.future);
      if (!mounted) return;
      if (!available) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.importHealthUnavailable)));
        return;
      }
      final count = await ref
          .read(todayMedicationLogsProvider.notifier)
          .importFromAppleHealth();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0 ? l10n.importHealthCount(count) : l10n.importHealthNone,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medsAsync = ref.watch(medicationsListProvider);
    final logsAsync = ref.watch(todayMedicationLogsProvider);

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.medicationsAppBarTitle),
          actions: [
            IconButton(
              tooltip: l10n.importFromHealthTooltip,
              onPressed: _importing ? null : _importFromHealth,
              icon: _importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.health),
            ),
            IconButton(
              tooltip: l10n.registerMedicationTooltip,
              icon: const Icon(AppIcons.add),
              onPressed: () => AddMedicationSheet.show(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.screenV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.medsGuiltFreeTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.medsGuiltFreeSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.mutedText(isDark),
                ),
              ),

              const SizedBox(height: 16),
              _TodayCurve(
                logs: logsAsync.value ?? const [],
                meds: medsAsync.value ?? const [],
              ),
              const SizedBox(height: 20),

              Text(
                l10n.dosesTodayTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              FadeSwap(
                child: () {
                  if (logsAsync.isLoading || medsAsync.isLoading) {
                    return const SlotSkeleton(
                      key: ValueKey('doses-loading'),
                      height: 160,
                      bars: 3,
                    );
                  }
                  if (logsAsync.hasError) {
                    return Text(
                      key: const ValueKey('doses-error'),
                      l10n.errorLoadingDoses('${logsAsync.error}'),
                    );
                  }
                  final logs = logsAsync.value ?? [];
                  final meds = medsAsync.value ?? [];
                  final doses = <({Medication med, MedicationLog log})>[];
                  for (final log in logs) {
                    for (final med in meds) {
                      if (med.id == log.medicationId) {
                        doses.add((med: med, log: log));
                        break;
                      }
                    }
                  }
                  if (doses.isEmpty || meds.isEmpty) {
                    return Card(
                      key: const ValueKey('doses-empty'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              AppIcons.medicationFilled,
                              size: 36,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noMedsScheduledToday,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => AddMedicationSheet.show(context),
                              child: Text(l10n.registerFirstMedButton),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    key: const ValueKey('doses-data'),
                    shrinkWrap: true,
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: doses.length,
                    itemBuilder: (_, index) {
                      final dose = doses[index];
                      return MedicationCard(
                        key: ValueKey(dose.log.id),
                        medication: dose.med,
                        log: dose.log,
                      );
                    },
                  );
                }(),
              ),

              const SizedBox(height: 24),

              Text(
                l10n.medsStockSectionTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              FadeSwap(
                child: medsAsync.when(
                  loading: () => const SlotSkeleton(
                    key: ValueKey('stock-loading'),
                    height: 48,
                    bars: 1,
                  ),
                  error: (err, stack) =>
                      const SizedBox(key: ValueKey('stock-error'), height: 48),
                  data: (meds) {
                    return ListView.builder(
                      key: const ValueKey('stock-data'),
                      shrinkWrap: true,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: meds.length,
                      itemBuilder: (_, index) {
                        final med = meds[index];
                        final isLow = med.needsRefillWarning;
                        return ListTile(
                          tileColor: isDark
                              ? AppColors.cardDark
                              : AppColors.cardLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.input),
                            side: BorderSide(
                              color: isLow
                                  ? AppColors.unstuck.withValues(alpha: 0.45)
                                  : (isDark
                                        ? AppColors.cardBorderDark
                                        : AppColors.cardBorderLight),
                            ),
                          ),
                          leading: Icon(
                            AppIcons.forMedicationShape(med.shapeIcon),
                            size: 22,
                            color: isLow
                                ? AppColors.unstuck
                                : (isDark
                                      ? AppColors.primary
                                      : AppColors.primary),
                          ),
                          onTap: () =>
                              AddMedicationSheet.show(context, existing: med),
                          title: Text(
                            '${med.name} ${med.dosage}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            isLow
                                ? l10n.medsRxAlertRemaining(med.remainingStock)
                                : l10n.medsStockCount(
                                    med.remainingStock,
                                    med.totalStock,
                                  ),
                            style: TextStyle(
                              fontSize: 12,
                              color: isLow
                                  ? AppColors.unstuck
                                  : AppColors.mutedText(isDark),
                              fontWeight: isLow ? FontWeight.bold : null,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(AppIcons.edit, size: 20),
                                tooltip: l10n.editMedicationTooltip,
                                onPressed: () => AddMedicationSheet.show(
                                  context,
                                  existing: med,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(AppIcons.delete, size: 20),
                                tooltip: l10n.deleteMedConfirmButton,
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(l10n.deleteMedConfirmTitle),
                                      content: Text(
                                        l10n.deleteMedConfirmBody(med.name),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(l10n.cancelButton),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(
                                            l10n.deleteMedConfirmButton,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true || !context.mounted) {
                                    return;
                                  }
                                  await ref
                                      .read(
                                        todayMedicationLogsProvider.notifier,
                                      )
                                      .deleteMedication(med.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => AddMedicationSheet.show(context),
          icon: const Icon(AppIcons.add),
          label: Text(l10n.newMedicationButton),
        ),
      ),
    );
  }
}

class _TodayCurve extends StatelessWidget {
  const _TodayCurve({required this.logs, required this.meds});

  final List<MedicationLog> logs;
  final List<Medication> meds;

  @override
  Widget build(BuildContext context) {
    final taken = logs.where((l) => l.isTaken).toList();
    if (taken.isEmpty) return const SizedBox.shrink();
    final log = taken.first;
    Medication? med;
    for (final candidate in meds) {
      if (candidate.id == log.medicationId) {
        med = candidate;
        break;
      }
    }
    final hours = med?.durationHours ?? 10;
    final start = log.takenAt!;
    final end = start.add(Duration(hours: hours));
    final now = DateTime.now();
    final span = end.difference(start).inMinutes.clamp(1, 24 * 60);
    final progress = now.difference(start).inMinutes / span;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.medicationName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          RepaintBoundary(
            child: SizedBox(
              height: 46,
              child: CustomPaint(
                painter: _CurvePainter(progress.clamp(0, 1).toDouble()),
                size: const Size(double.infinity, 46),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.05,
        size.width * 0.62,
        size.height * 0.2,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.35,
        size.width,
        size.height * 0.85,
      );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.peak, AppColors.unstuck],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
    final metric = path.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent == null) return;
    canvas.drawCircle(tangent.position, 6, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
