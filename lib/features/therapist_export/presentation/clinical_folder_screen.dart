import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../routine_mood/domain/mood_entry.dart';
import '../../routine_mood/domain/routine_export.dart';
import '../../routine_mood/presentation/routine_providers.dart';
import '../../tasks/domain/task_item.dart';
import '../../tasks/presentation/task_providers.dart';
import '../../../integrations/health/models/daily_recovery_snapshot.dart';
import '../../../integrations/health/models/sleep_record.dart';
import '../data/pdf_style_prefs.dart';
import '../data/therapist_contact_repository.dart';
import '../domain/care_contact.dart';
import '../domain/export_tasks.dart';
import '../domain/pdf_report_style.dart';
import '../service/share_card_exporter.dart';
import '../service/therapist_pdf_generator.dart';
import '../service/therapist_pdf_share.dart';
import '../service/whatsapp_text_formatter.dart';
import 'therapist_report_screen.dart';
import 'widgets/weekly_summary_card_preview.dart';
import '../../../core/widgets/glass_chip.dart';
import '../../../core/widgets/glass_nav_bar.dart';
import '../../../core/widgets/glass_toast.dart';

enum _ClinicalFolderActionTone { primary, outlined }

/// Resumos clínicos locais prontos para compartilhar.
class ClinicalFolderScreen extends ConsumerStatefulWidget {
  const ClinicalFolderScreen({super.key});

  @override
  ConsumerState<ClinicalFolderScreen> createState() =>
      _ClinicalFolderScreenState();
}

class _ClinicalFolderScreenState extends ConsumerState<ClinicalFolderScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busyWhatsApp = false;
  bool _busyShareCard = false;
  bool _busySharePdf = false;
  int _periodDays = 7;

  /// Padrão seguro: notas íntimas (pauta/fechamento) ocultas até a pessoa optar.
  /// O toggle de UI entra numa etapa seguinte; aqui fica só o fio de domínio.
  bool _hideIntimateNotes = true;

  Future<void> _sendWhatsApp(
    AppLocalizations l10n,
    String formattedText,
  ) async {
    if (_busyWhatsApp) return;
    setState(() => _busyWhatsApp = true);
    try {
      final contacts =
          ref.read(careContactsProvider).valueOrNull?.where((contact) {
            return contact.phone.trim().isNotEmpty;
          }).toList() ??
          const <CareContact>[];
      if (contacts.isEmpty) {
        await Clipboard.setData(ClipboardData(text: formattedText));
        if (!mounted) return;
        showGlassToast(context, l10n.textCopiedWhatsAppHint);
        return;
      }
      final selected = await _pickContact(contacts);
      if (!mounted || selected == null) return;

      final success = await WhatsappTextFormatter.sendToWhatsApp(
        messageText: formattedText,
        phoneNumber: selected.phone,
      );
      if (!success && mounted) {
        await Clipboard.setData(ClipboardData(text: formattedText));
        if (!mounted) return;
        showGlassToast(context, l10n.textCopiedWhatsAppHint);
      }
    } finally {
      if (mounted) setState(() => _busyWhatsApp = false);
    }
  }

  Future<CareContact?> _pickContact(List<CareContact> contacts) async {
    if (contacts.isEmpty) return null;
    if (contacts.length == 1) return contacts.single;

    return showModalBottomSheet<CareContact>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final contact in contacts)
            ListTile(
              leading: const Icon(AppIcons.chat),
              title: Text(
                contact.displayName?.trim().isNotEmpty == true
                    ? contact.displayName!
                    : contact.phone,
              ),
              subtitle: Text(contact.phone),
              onTap: () => Navigator.pop(context, contact),
            ),
        ],
      ),
    );
  }

  Future<void> _shareCard(AppLocalizations l10n, String patientName) async {
    if (_busyShareCard) return;
    setState(() => _busyShareCard = true);
    try {
      final ok = await ShareCardExporter.captureAndShare(
        repaintKey: _cardKey,
        shareTitle: l10n.shareCardTitleTemplate(patientName),
        shareSubject: l10n.shareCardSubject,
      );
      if (!ok && mounted) {
        showGlassToast(context, l10n.shareCardImageFailed);
      }
    } finally {
      if (mounted) setState(() => _busyShareCard = false);
    }
  }

  Future<void> _sharePdf({
    required AppLocalizations l10n,
    required String patientName,
    required List<SleepRecord> sleepRecords,
    required List<MoodEntry> moodEntries,
    required List<DailyRecoverySnapshot> recoverySnapshots,
    required List<RoutineExportLine> routineLines,
    required List<TaskExportLine> taskLines,
    required int appleSomCount,
  }) async {
    if (_busySharePdf) return;
    setState(() => _busySharePdf = true);
    try {
      final style = ref.read(pdfReportStyleProvider);
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
        periodDays: _periodDays,
        style: style,
        l10n: l10n,
      );
      final ok = await shareTherapistPdf(
        bytes: bytes,
        filename: l10n.pdfFileName,
        subject: l10n.sharePdfSubject,
      );
      if (!ok && mounted) {
        showGlassToast(context, l10n.sharePdfFailed);
      }
    } catch (_) {
      if (mounted) showGlassToast(context, l10n.sharePdfFailed);
    } finally {
      if (mounted) setState(() => _busySharePdf = false);
    }
  }

  List<T> _datedInPeriod<T>(List<T> items, DateTime Function(T item) dateOf) {
    final start = DateTime.now().subtract(Duration(days: _periodDays));
    return items.where((item) => !dateOf(item).isBefore(start)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = ref.watch(appLocalizationsProvider);
    final profile = ref.watch(userProfileProvider);
    final patientName = profileDisplayName(profile, l10n.patientDisplayName);
    final sleepAsync = ref.watch(sleepHistoryProvider);
    final moodAsync = ref.watch(moodEntriesProvider);
    final recoveryAsync = ref.watch(recoveryHistoryProvider);
    final routineAsync = ref.watch(recentRoutineSnapshotsProvider);
    final tasksAsync = ref.watch(tasksListProvider);
    final appleSomCount =
        ref.watch(appleHealthStateOfMindCountProvider).value ?? 0;
    final pdfStyle = ref.watch(pdfReportStyleProvider);

    final isLoading =
        sleepAsync.isLoading || moodAsync.isLoading || routineAsync.isLoading;
    final hasError = sleepAsync.hasError || moodAsync.hasError;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: FadeSwap(
        child: isLoading
            ? const Padding(
                key: ValueKey('export-loading'),
                padding: EdgeInsets.all(20),
                child: FormSkeleton(),
              )
            : hasError
            ? Center(
                key: const ValueKey('export-error'),
                child: Text(
                  l10n.errorLoadingData(
                    '${sleepAsync.error ?? moodAsync.error}',
                  ),
                ),
              )
            : Builder(
                key: const ValueKey('export-data'),
                builder: (context) {
                  final List<SleepRecord> allSleep =
                      sleepAsync.value ?? const [];
                  final List<MoodEntry> allMood = moodAsync.value ?? const [];
                  final List<DailyRecoverySnapshot> allRecovery =
                      recoveryAsync.asData?.value ?? const [];
                  final sleepRecords = _datedInPeriod(
                    allSleep,
                    (record) => record.date,
                  );
                  final moodEntries = _datedInPeriod(
                    allMood,
                    (entry) => entry.timestamp,
                  ).map(_withoutIntimateNotes).toList();
                  final recoverySnapshots = _datedInPeriod(
                    allRecovery,
                    (record) => record.date,
                  );
                  final allSnapshots = routineAsync.value ?? const [];
                  // Linhas de WhatsApp/PDF respeitam o controle de notas íntimas.
                  final routineLines = routineExportLines(
                    snapshots: allSnapshots,
                    now: DateTime.now(),
                    periodDays: _periodDays,
                    hideIntimateNotes: _hideIntimateNotes,
                  );
                  // O card visual nunca leva pauta/fechamento, mesmo com as
                  // notas íntimas liberadas para o texto/PDF.
                  final cardRoutineLines = routineExportLines(
                    snapshots: allSnapshots,
                    now: DateTime.now(),
                    periodDays: _periodDays,
                    hideIntimateNotes: true,
                  );
                  // Pauta/fechamento só aparecem na pré-visualização quando
                  // as notas íntimas estão liberadas pelo toggle.
                  final intimateLines = _hideIntimateNotes
                      ? const <RoutineExportLine>[]
                      : routineLines
                            .where(
                              (line) =>
                                  (line.eveningReflection ?? '').isNotEmpty ||
                                  (line.therapistNotes ?? '').isNotEmpty,
                            )
                            .toList();
                  final tasks = tasksAsync.value ?? const <TaskItem>[];
                  final taskLines = taskExportLines(
                    tasks: tasks,
                    now: DateTime.now(),
                    periodDays: _periodDays,
                  );
                  final formattedText = WhatsappTextFormatter.formatSummary(
                    patientName: patientName,
                    sleepRecords: sleepRecords,
                    moodEntries: moodEntries,
                    recoverySnapshots: recoverySnapshots,
                    appleHealthSomCount: appleSomCount,
                    periodDays: _periodDays,
                    routineLines: routineLines,
                    taskLines: taskLines,
                    tasksHeading: l10n.exportTasksHeading,
                    tasksNone: l10n.exportTasksNone,
                    tasksCompletedMarker: l10n.exportTasksCompletedMarker,
                    tasksOpenMarker: l10n.exportTasksOpenMarker,
                    l10n: l10n,
                  );

                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      12,
                      AppSpacing.screenH,
                      GlassNavBar.reservedBottom(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileClinicalSectionTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.profileClinicalSectionSubtitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final days in [7, 14, 30])
                              GlassChip(
                                label: '$days',
                                selected: _periodDays == days,
                                onTap: () =>
                                    setState(() => _periodDays = days),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.pdfStyleSectionLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            GlassChip(
                              label: l10n.pdfStyleClinicalLabel,
                              selected:
                                  pdfStyle == PdfReportStyle.clinicalCalm,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(pdfReportStyleProvider.notifier)
                                    .setStyle(PdfReportStyle.clinicalCalm);
                              },
                            ),
                            GlassChip(
                              label: l10n.pdfStyleLumenLabel,
                              selected: pdfStyle == PdfReportStyle.lumenSoft,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(pdfReportStyleProvider.notifier)
                                    .setStyle(PdfReportStyle.lumenSoft);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          toggled: _hideIntimateNotes,
                          label: _hideIntimateNotes
                              ? '${l10n.hideIntimateNotes}, ativado'
                              : '${l10n.hideIntimateNotes}, desativado',
                          child: SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.hideIntimateNotes),
                            subtitle: Text(l10n.hideIntimateNotesHelp),
                            value: _hideIntimateNotes,
                            onChanged: (value) {
                              HapticFeedback.selectionClick();
                              setState(() => _hideIntimateNotes = value);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: AppIcons.chat,
                          tone: _ClinicalFolderActionTone.primary,
                          title: l10n.sendWhatsAppTitle,
                          subtitle: l10n.sendWhatsAppSubtitle,
                          buttonLabel: l10n.sendWhatsAppButton,
                          busy: _busyWhatsApp,
                          onPressed: () => _sendWhatsApp(l10n, formattedText),
                          secondaryAction: TextButton.icon(
                            onPressed: _busyWhatsApp
                                ? null
                                : () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: formattedText),
                                    );
                                    if (context.mounted) {
                                      showGlassToast(context, 
                                            l10n.textCopiedSuccessShort,
                                          );
                                    }
                                  },
                            icon: const Icon(AppIcons.copy, size: 18),
                            label: Text(l10n.copyTextButton),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ActionCard(
                          icon: AppIcons.image,
                          tone: _ClinicalFolderActionTone.outlined,
                          title: l10n.visualCardTitle,
                          subtitle: l10n.visualCardSubtitle,
                          buttonLabel: l10n.shareCardButton,
                          busy: _busyShareCard,
                          onPressed: () => _shareCard(l10n, patientName),
                        ),
                        const SizedBox(height: 16),
                        _ActionCard(
                          icon: AppIcons.pdf,
                          tone: _ClinicalFolderActionTone.outlined,
                          title: l10n.pdfReportTitle,
                          subtitle: l10n.pdfReportSubtitle,
                          buttonLabel: l10n.sharePdfButton,
                          busy: _busySharePdf,
                          onPressed: () => _sharePdf(
                            l10n: l10n,
                            patientName: patientName,
                            sleepRecords: sleepRecords,
                            moodEntries: moodEntries,
                            recoverySnapshots: recoverySnapshots,
                            routineLines: routineLines,
                            taskLines: taskLines,
                            appleSomCount: appleSomCount,
                          ),
                          secondaryAction: TextButton.icon(
                            onPressed: _busySharePdf
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TherapistReportScreen(
                                          periodDays: _periodDays,
                                          hideIntimateNotes:
                                              _hideIntimateNotes,
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(AppIcons.pdf, size: 18),
                            label: Text(l10n.viewPdfButton),
                          ),
                        ),
                        if (!_hideIntimateNotes) ...[
                          const SizedBox(height: 28),
                          Text(
                            l10n.therapyNotesSectionTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.therapyNotesSectionSubtitle,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          _IntimateNotesPreview(
                            lines: intimateLines,
                            localeName: l10n.localeName,
                          ),
                        ],
                        const SizedBox(height: 28),
                        Text(
                          l10n.cardPreviewTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        WeeklySummaryCardPreview(
                          repaintKey: _cardKey,
                          patientName: patientName,
                          sleepRecords: sleepRecords,
                          moodEntries: moodEntries,
                          recoverySnapshots: recoverySnapshots,
                          routineLines: cardRoutineLines,
                          periodDays: _periodDays,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }

  MoodEntry _withoutIntimateNotes(MoodEntry entry) {
    return MoodEntry(
      id: entry.id,
      timestamp: entry.timestamp,
      valence: entry.valence,
      energy: entry.energy,
      focus: entry.focus,
      tookMedication: entry.tookMedication,
      sensoryOverload: entry.sensoryOverload,
      emotionLabels: entry.emotionLabels,
      emotionSource: entry.emotionSource,
    );
  }
}

/// Lista de pauta/fechamento do período, visível só quando o toggle de notas
/// íntimas está desligado.
class _IntimateNotesPreview extends ConsumerWidget {
  const _IntimateNotesPreview({required this.lines, required this.localeName});

  final List<RoutineExportLine> lines;
  final String localeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(appLocalizationsProvider);
    final theme = Theme.of(context);

    if (lines.isEmpty) {
      return Text(l10n.therapyNotesEmpty, style: theme.textTheme.bodyMedium);
    }

    final dateFormat = DateFormat.MMMd(localeName);
    final timeFormat = DateFormat.Hm(localeName);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppColors.cardDark
            : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? AppColors.cardBorderDark
              : AppColors.cardBorderLight,
        ),
      ),
      child: Column(
        children: [
          for (final line in lines.take(12))
            ListTile(
              leading: const Icon(AppIcons.therapist, color: AppColors.primary),
              title: Text(
                '${dateFormat.format(line.savedAt)} · ${timeFormat.format(line.savedAt)}',
                style: theme.textTheme.titleSmall,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((line.eveningReflection ?? '').isNotEmpty)
                    Text(
                      l10n.therapyNotesReflectionSnippet(
                        line.eveningReflection!,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if ((line.therapistNotes ?? '').isNotEmpty)
                    Text(
                      l10n.therapyNotesPautaSnippet(line.therapistNotes!),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
    this.busy = false,
    this.secondaryAction,
  });

  final IconData icon;
  final _ClinicalFolderActionTone tone;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool busy;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark
        ? AppColors.cardBorderDark
        : AppColors.cardBorderLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final ink = isDark ? AppColors.textLight : AppColors.textDark;
    final isPrimary = tone == _ClinicalFolderActionTone.primary;
    final buttonChild = BusyButtonChild(
      busy: busy,
      spinnerColor: isPrimary ? Colors.white : ink,
      label: Text(buttonLabel),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isPrimary)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: busy ? null : onPressed,
              child: buttonChild,
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: ink,
                backgroundColor: card,
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(color: border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
              onPressed: busy ? null : onPressed,
              child: buttonChild,
            ),
          if (secondaryAction != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: secondaryAction,
            ),
          ],
        ],
      ),
    );
  }
}
