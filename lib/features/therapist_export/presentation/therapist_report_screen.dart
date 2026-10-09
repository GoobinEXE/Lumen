import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';
import 'package:printing/printing.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../../core/widgets/glass_app_bar.dart';
import '../../../core/widgets/glass_toast.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../routine_mood/domain/mood_entry.dart';
import '../../routine_mood/domain/routine_export.dart';
import '../../routine_mood/presentation/daily_routine_screen.dart';
import '../../tasks/domain/task_item.dart';
import '../../tasks/presentation/task_providers.dart';
import '../../../integrations/health/models/daily_recovery_snapshot.dart';
import '../../../integrations/health/models/sleep_record.dart';
import '../data/pdf_style_prefs.dart';
import '../domain/export_tasks.dart';
import '../domain/pdf_report_style.dart';
import '../service/therapist_pdf_generator.dart';
import '../service/therapist_pdf_share.dart';

class TherapistReportScreen extends ConsumerStatefulWidget {
  const TherapistReportScreen({
    super.key,
    this.periodDays = 7,
    this.hideIntimateNotes = false,
  });

  final int periodDays;
  final bool hideIntimateNotes;

  @override
  ConsumerState<TherapistReportScreen> createState() =>
      _TherapistReportScreenState();
}

class _TherapistReportScreenState extends ConsumerState<TherapistReportScreen> {
  Uint8List? _cachedBytes;
  bool _sharing = false;

  Future<Uint8List> _buildPdf({
    required String patientName,
    required List<SleepRecord> sleepRecords,
    required List<MoodEntry> moodEntries,
    required List<DailyRecoverySnapshot> recoverySnapshots,
    required int appleSomCount,
    required List<RoutineExportLine> routineLines,
    required List<TaskExportLine> taskLines,
    required PdfReportStyle style,
    required AppLocalizations l10n,
  }) async {
    final bytes = await TherapistPdfGenerator.generateReport(
      patientName: patientName,
      sleepRecords: sleepRecords,
      moodEntries: moodEntries,
      recoverySnapshots: recoverySnapshots,
      appleHealthSomCount: appleSomCount,
      routineLines: routineLines,
      taskLines: taskLines,
      tasksHeading: l10n.exportTasksHeading,
      tasksNone: l10n.exportTasksNone,
      tasksCompletedMarker: l10n.exportTasksCompletedMarker,
      tasksOpenMarker: l10n.exportTasksOpenMarker,
      periodDays: widget.periodDays,
      style: style,
      l10n: l10n,
    );
    _cachedBytes = bytes;
    return bytes;
  }

  Future<void> _shareFromAppBar(AppLocalizations l10n) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      var bytes = _cachedBytes;
      if (bytes == null) {
        if (mounted) showGlassToast(context, l10n.sharePdfFailed);
        return;
      }
      final ok = await shareTherapistPdf(
        bytes: bytes,
        filename: l10n.pdfFileName,
        subject: l10n.sharePdfSubject,
      );
      if (!ok && mounted) {
        showGlassToast(context, l10n.sharePdfFailed);
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final patientName = profileDisplayName(
      ref.watch(userProfileProvider),
      l10n.patientDisplayName,
    );
    final sleepAsync = ref.watch(sleepHistoryProvider);
    final moodAsync = ref.watch(moodEntriesProvider);
    final recoveryAsync = ref.watch(recoveryHistoryProvider);
    final routineAsync = ref.watch(recentRoutineSnapshotsProvider);
    final tasksAsync = ref.watch(tasksListProvider);
    final appleSomCount =
        ref.watch(appleHealthStateOfMindCountProvider).value ?? 0;
    final pdfStyle = ref.watch(pdfReportStyleProvider);
    final routineSnapshots = routineAsync.value ?? const [];
    final routineLines = routineExportLines(
      snapshots: routineSnapshots,
      now: DateTime.now(),
      periodDays: widget.periodDays,
      hideIntimateNotes: widget.hideIntimateNotes,
    );
    final tasks = tasksAsync.value ?? const <TaskItem>[];
    final taskLines = taskExportLines(
      tasks: tasks,
      now: DateTime.now(),
      periodDays: widget.periodDays,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading =
        sleepAsync.isLoading || moodAsync.isLoading || routineAsync.isLoading;
    final hasError = sleepAsync.hasError || moodAsync.hasError;
    final pageBorder = isDark
        ? AppColors.cardBorderDark
        : AppColors.cardBorderLight;
    final actionInk = isDark ? AppColors.textLight : AppColors.textDark;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(l10n.therapistReportAppBarTitle),
        actions: [
          IconButton(
            tooltip: l10n.sharePdfButton,
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CupertinoActivityIndicator(),
                  )
                : const Icon(AppIcons.share),
            onPressed: _sharing || isLoading || hasError
                ? null
                : () => _shareFromAppBar(l10n),
          ),
          IconButton(
            tooltip: l10n.privacyInfoTooltip,
            icon: const Icon(Icons.shield_outlined),
            onPressed: () {
              showCupertinoDialog<void>(
                context: context,
                builder: (ctx) => CupertinoAlertDialog(
                  title: Text(l10n.privacyDialogTitle),
                  content: Text(l10n.privacyDialogBody),
                  actions: [
                    CupertinoDialogAction(
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
                child: CupertinoActivityIndicator(),
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
                key: ValueKey('report-pdf-$pdfStyle'),
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                allowPrinting: true,
                // Share nativo só aparece se Printing.info().canShare;
                // usamos action custom abaixo pra não sumir de novo.
                allowSharing: false,
                useActions: true,
                shouldRepaint: true,
                pdfFileName: l10n.pdfFileName,
                shareActionExtraSubject: l10n.sharePdfSubject,
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
                  iconColor: actionInk,
                  elevation: 0,
                  height: 56,
                  textStyle: TextStyle(
                    color: actionInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Garante share mesmo quando Printing.info().canShare é false.
                actions: [
                  PdfPreviewAction(
                    icon: Icon(AppIcons.share, color: actionInk),
                    onPressed: (context, build, format) async {
                      final bytes = await build(format);
                      _cachedBytes = bytes;
                      final ok = await shareTherapistPdf(
                        bytes: bytes,
                        filename: l10n.pdfFileName,
                        subject: l10n.sharePdfSubject,
                      );
                      if (!ok && context.mounted) {
                        showGlassToast(context, l10n.sharePdfFailed);
                      }
                    },
                  ),
                ],
                build: (format) => _buildPdf(
                  patientName: patientName,
                  sleepRecords: sleepAsync.value ?? const [],
                  moodEntries: moodAsync.value ?? const [],
                  recoverySnapshots: recoveryAsync.asData?.value ?? const [],
                  appleSomCount: appleSomCount,
                  routineLines: routineLines,
                  taskLines: taskLines,
                  style: pdfStyle,
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
