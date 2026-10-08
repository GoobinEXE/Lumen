import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noa/l10n/app_localizations.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../routine_mood/domain/routine_export.dart';
import '../../routine_mood/presentation/daily_routine_screen.dart';
import '../data/therapist_contact_repository.dart';
import '../service/share_card_exporter.dart';
import '../service/whatsapp_text_formatter.dart';
import 'therapist_report_screen.dart';
import 'widgets/weekly_summary_card_preview.dart';

enum _HubActionTone { primary, outlined }

class TherapistExportHubScreen extends ConsumerStatefulWidget {
  const TherapistExportHubScreen({super.key});

  @override
  ConsumerState<TherapistExportHubScreen> createState() =>
      _TherapistExportHubScreenState();
}

class _TherapistExportHubScreenState
    extends ConsumerState<TherapistExportHubScreen> {
  final GlobalKey _cardKey = GlobalKey();
  final TextEditingController _phoneController = TextEditingController();

  bool _busyWhatsApp = false;
  bool _busyShareCard = false;
  int _periodDays = 7;
  bool _hideIntimateNotes = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  void _loadSavedPhone() {
    _phoneController.text = ref
        .read(therapistContactRepositoryProvider)
        .readPhone();
  }

  Future<void> _savePhone(String value) {
    return ref.read(therapistContactRepositoryProvider).savePhone(value);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsApp(
    AppLocalizations l10n,
    String formattedText,
  ) async {
    if (_busyWhatsApp) return;
    setState(() => _busyWhatsApp = true);
    try {
      final phone = _phoneController.text.trim();
      final success = await WhatsappTextFormatter.sendToWhatsApp(
        messageText: formattedText,
        phoneNumber: phone.isEmpty ? null : phone,
      );

      if (!success) {
        await Clipboard.setData(ClipboardData(text: formattedText));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.textCopiedWhatsAppHint)));
        }
      }
    } finally {
      if (mounted) setState(() => _busyWhatsApp = false);
    }
  }

  Future<void> _shareCard(AppLocalizations l10n) async {
    if (_busyShareCard) return;
    setState(() => _busyShareCard = true);
    try {
      final ok = await ShareCardExporter.captureAndShare(
        repaintKey: _cardKey,
        shareTitle: l10n.shareCardTitleTemplate(l10n.patientDisplayName),
        shareSubject: l10n.shareCardSubject,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shareCardImageFailed)));
      }
    } finally {
      if (mounted) setState(() => _busyShareCard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final sleepAsync = ref.watch(sleepHistoryProvider);
    final moodAsync = ref.watch(moodEntriesProvider);
    final recoveryAsync = ref.watch(recoveryHistoryProvider);
    final routineAsync = ref.watch(recentRoutineSnapshotsProvider);
    final appleSomCount =
        ref.watch(appleHealthStateOfMindCountProvider).value ?? 0;
    final routineSnapshots = routineAsync.value ?? const [];

    final isLoading =
        sleepAsync.isLoading || moodAsync.isLoading || routineAsync.isLoading;
    final hasError = sleepAsync.hasError || moodAsync.hasError;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.therapistExportHubTitle),
          actions: [
            IconButton(
              tooltip: l10n.configureTherapistPhoneTooltip,
              icon: const Icon(AppIcons.settings),
              onPressed: () => _showPhoneDialog(context, l10n),
            ),
          ],
        ),
        body: FadeSwap(
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
                    final sleepRecords = sleepAsync.value ?? [];
                    final moodEntries = redactIntimateMoodNotes(
                      moodAsync.value ?? const [],
                      hideIntimateNotes: _hideIntimateNotes,
                    );
                    final recoverySnapshots = recoveryAsync.asData?.value ?? [];
                    final routineLines = routineExportLines(
                      snapshots: routineSnapshots,
                      now: DateTime.now(),
                      periodDays: _periodDays,
                      hideIntimateNotes: _hideIntimateNotes,
                    );
                    final formattedText = WhatsappTextFormatter.formatSummary(
                      patientName: l10n.patientDisplayName,
                      sleepRecords: sleepRecords,
                      moodEntries: moodEntries,
                      recoverySnapshots: recoverySnapshots,
                      appleHealthSomCount: appleSomCount,
                      periodDays: _periodDays,
                      routineLines: routineLines,
                      l10n: l10n,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH,
                        vertical: AppSpacing.screenV,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final days in [7, 14, 30])
                                ChoiceChip(
                                  label: Text('$days'),
                                  selected: _periodDays == days,
                                  onSelected: (_) =>
                                      setState(() => _periodDays = days),
                                ),
                            ],
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.hideIntimateNotes),
                            value: _hideIntimateNotes,
                            onChanged: (value) =>
                                setState(() => _hideIntimateNotes = value),
                          ),
                          Text(
                            l10n.therapistSendHowTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.therapistSendHowSubtitle,
                            style: theme.textTheme.bodyMedium,
                          ),

                          const SizedBox(height: 20),

                          _buildActionCard(
                            context: context,
                            icon: AppIcons.chat,
                            tone: _HubActionTone.primary,
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.textCopiedSuccessShort,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(AppIcons.copy, size: 18),
                              label: Text(l10n.copyTextButton),
                            ),
                          ),

                          const SizedBox(height: 16),

                          _buildActionCard(
                            context: context,
                            icon: AppIcons.image,
                            tone: _HubActionTone.outlined,
                            title: l10n.visualCardTitle,
                            subtitle: l10n.visualCardSubtitle,
                            buttonLabel: l10n.shareCardButton,
                            busy: _busyShareCard,
                            onPressed: () => _shareCard(l10n),
                          ),

                          const SizedBox(height: 16),

                          _buildActionCard(
                            context: context,
                            icon: AppIcons.pdf,
                            tone: _HubActionTone.outlined,
                            title: l10n.pdfReportTitle,
                            subtitle: l10n.pdfReportSubtitle,
                            buttonLabel: l10n.exportPdfButton,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TherapistReportScreen(
                                    periodDays: _periodDays,
                                    hideIntimateNotes: _hideIntimateNotes,
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 28),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.cardPreviewTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.chip,
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.cardBorderDark
                                        : AppColors.cardBorderLight,
                                  ),
                                ),
                                child: Text(
                                  l10n.exportablePngBadge,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mutedText(isDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          WeeklySummaryCardPreview(
                            repaintKey: _cardKey,
                            patientName: l10n.patientDisplayName,
                            sleepRecords: sleepRecords,
                            moodEntries: moodEntries,
                            routineLines: routineLines,
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

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required _HubActionTone tone,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool busy = false,
    Widget? secondaryAction,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final border = isDark
        ? AppColors.cardBorderDark
        : AppColors.cardBorderLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final ink = isDark ? AppColors.textLight : AppColors.textDark;
    final isPrimary = tone == _HubActionTone.primary;

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
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.shadow).withValues(
              alpha: isDark ? 0.28 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
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

  void _showPhoneDialog(BuildContext context, AppLocalizations l10n) {
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.therapistPhoneDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.therapistPhoneDialogBody,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: l10n.therapistPhoneHint,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancelButton),
            ),
            ElevatedButton(
              onPressed: () async {
                final digits = _phoneController.text.replaceAll(
                  RegExp(r'\D'),
                  '',
                );
                if (digits.length < 10) {
                  setDialogState(() => errorText = l10n.phoneInvalidError);
                  return;
                }
                await _savePhone(_phoneController.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.phoneSavedSuccess)));
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );
  }
}
