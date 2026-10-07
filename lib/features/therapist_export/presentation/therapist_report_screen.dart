import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../routine_mood/domain/routine_export.dart';
import '../domain/export_period.dart';
import '../../routine_mood/presentation/daily_routine_screen.dart';
import '../service/therapist_pdf_generator.dart';

class TherapistReportScreen extends ConsumerWidget {
  const TherapistReportScreen({
    super.key,
    this.periodDays = 7,
    this.hideIntimateNotes = false,
  });

  final int periodDays;
  final bool hideIntimateNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final sleepAsync = ref.watch(clinicalSleepHistoryProvider);
    final moodAsync = ref.watch(moodEntriesProvider);
    final recoveryAsync = ref.watch(clinicalRecoveryHistoryProvider);
    final routineAsync = ref.watch(recentRoutineSnapshotsProvider);
    final routineSnapshots = routineAsync.value ?? const [];
    final now = DateTime.now();
    final appleSomCount = appleHealthSomDaysInPeriod(
      snapshots: routineSnapshots,
      now: now,
      periodDays: periodDays,
    );
    final routineLines = routineExportLines(
      snapshots: routineSnapshots,
      now: now,
      periodDays: periodDays,
      hideIntimateNotes: hideIntimateNotes,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading =
        sleepAsync.isLoading || moodAsync.isLoading || routineAsync.isLoading;
    final hasError = sleepAsync.hasError || moodAsync.hasError;
    final pageBorder = isDark
        ? AppColors.cardBorderDark
        : AppColors.cardBorderLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.therapistReportAppBarTitle),
        actions: [
          IconButton(
            tooltip: l10n.privacyInfoTooltip,
            icon: const Icon(Icons.shield_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.privacyDialogTitle),
                  content: Text(l10n.privacyDialogBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.understoodButton),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FadeSwap(
        child: isLoading
            ? const Center(
                key: ValueKey('report-loading'),
                child: CircularProgressIndicator(),
              )
            : hasError
            ? Center(
                key: const ValueKey('report-error'),
                child: Text(
                  l10n.errorLoadingData(
                    '${sleepAsync.error ?? moodAsync.error}',
                  ),
                ),
              )
            : PdfPreview(
                key: const ValueKey('report-pdf'),
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfFileName: l10n.pdfFileName,
                padding: const EdgeInsets.all(16),
                previewPageMargin: const EdgeInsets.all(16),
                scrollViewDecoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                ),
                pdfPreviewPageDecoration: BoxDecoration(
                  color: AppColors.cardLight,
                  border: Border.all(color: pageBorder),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : AppColors.shadow)
                          .withValues(alpha: isDark ? 0.28 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                actionBarTheme: PdfActionBarTheme(
                  backgroundColor: isDark
                      ? AppColors.cardDark
                      : AppColors.cardLight,
                  iconColor: isDark ? AppColors.textLight : AppColors.textDark,
                  elevation: 0,
                  height: 56,
                  textStyle: TextStyle(
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                build: (format) => TherapistPdfGenerator.generateReport(
                  patientName: l10n.patientDisplayName,
                  sleepRecords: sleepAsync.value ?? [],
                  moodEntries: moodAsync.value ?? [],
                  recoverySnapshots: recoveryAsync.asData?.value ?? [],
                  appleHealthSomCount: appleSomCount,
                  routineLines: routineLines,
                  periodDays: periodDays,
                  l10n: l10n,
                ),
                loadingWidget: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        l10n.compilingMetricsMessage,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
