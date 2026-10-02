import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noa/l10n/app_localizations.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/localization/l10n_labels.dart';
import '../../../core/localization/language_selector_dialog.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/widgets/async_placeholders.dart';
import '../../../core/widgets/lumen_shell.dart';
import '../../medications/domain/medication.dart';
import '../../medications/domain/medication_log.dart';
import '../../medications/presentation/providers/medication_providers.dart';
import '../../routine_mood/domain/routine_snapshot.dart';
import '../../routine_mood/presentation/daily_routine_screen.dart';
import '../../routine_mood/presentation/quick_checkin_modal.dart';
import '../../sleep_analytics/presentation/recovery_dashboard_card.dart';
import '../../sleep_analytics/presentation/sleep_dashboard_card.dart';
import '../../unstuck_assistant/presentation/unstuck_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    final name = l10n.greetingName;
    if (hour < 12) return l10n.greetingMorning(name);
    if (hour < 18) return l10n.greetingAfternoon(name);
    return l10n.greetingEvening(name);
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return AppIcons.lightMode;
      case ThemeMode.dark:
        return AppIcons.darkMode;
      case ThemeMode.system:
        return AppIcons.systemMode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = ref.watch(appLocalizationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final insights = ref.watch(correlationInsightsProvider);
    final moodAsync = ref.watch(moodEntriesProvider);
    final logsAsync = ref.watch(todayMedicationLogsProvider);
    final medsAsync = ref.watch(medicationsListProvider);
    final routineAsync = ref.watch(todaySnapshotsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sleepHistoryProvider);
            ref.invalidate(recoveryHistoryProvider);
            ref.invalidate(todaySnapshotsProvider);
            await ref.read(moodEntriesProvider.notifier).loadEntries();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              12,
              AppSpacing.screenH,
              28,
            ),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoundIconButton(
                      tooltip: l10n.themeToggleTooltip,
                      icon: _themeIcon(themeMode),
                      onPressed: () =>
                          ref.read(themeModeProvider.notifier).cycle(),
                    ),
                    const SizedBox(width: 8),
                    _RoundIconButton(
                      tooltip: l10n.languageSelectorTitle,
                      icon: AppIcons.language,
                      onPressed: () => LanguageSelectorDialog.show(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(
                      color: isDark
                          ? AppColors.cardBorderDark
                          : AppColors.cardBorderLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.biorhythmCalm,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const _MoodHalo(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(l10n),
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.noPressureSubtitle,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _HeroButton(
                      color: AppColors.primary,
                      icon: AppIcons.forward,
                      title: l10n.quickCheckinTitle,
                      subtitle: l10n.checkinDurationHint,
                      onTap: () => QuickCheckinModal.show(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _HeroButton(
                      color: AppColors.unstuck,
                      icon: AppIcons.unstuck,
                      title: l10n.unstuckButton,
                      subtitle: l10n.unstuckButtonSub,
                      onTap: () => UnstuckSheet.show(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MedWindowCard(
                logs: logsAsync.value ?? const [],
                meds: medsAsync.value ?? const [],
                l10n: l10n,
                onOpen: () => openMedicationsScreen(context),
              ),
              const SizedBox(height: 12),
              _AnchorCard(
                snapshots: routineAsync.value ?? const [],
                l10n: l10n,
                onOpen: () => openRoutineScreen(context),
              ),
              const SizedBox(height: 12),
              const SleepDashboardCard(),
              const SizedBox(height: 12),
              const RecoveryDashboardCard(),
              if (insights.isNotEmpty) ...[
                const SizedBox(height: 12),
                GlassSurface(
                  tint: AppColors.accent,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeBrainPatternsTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        insights.first.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textLight
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.homeRecentEntriesTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              moodAsync.when(
                loading: () => const SlotSkeleton(height: 72, bars: 2),
                error: (err, _) => Text(l10n.errorLoading('$err')),
                data: (entries) {
                  if (entries.isEmpty) {
                    return Text(
                      l10n.homeNoEntriesYet,
                      style: theme.textTheme.bodyMedium,
                    );
                  }
                  return Column(
                    children: [
                      for (final entry in entries.take(3))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            AppIcons.forValence(entry.valence),
                            color: AppColors.primary,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.focus.label(l10n),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  entry.energy.label(l10n),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            DateFormat.Hm(
                              l10n.localeName,
                            ).format(entry.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: kMinBodySecondary,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadii.button);
    return Material(
      color: color,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        overlayColor: glassInkOverlay,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.cardLight, size: 22),
              const SizedBox(height: 16),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.cardLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.cardLight.withValues(alpha: 0.7),
                  fontSize: kMinBodySecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedWindowCard extends StatelessWidget {
  const _MedWindowCard({
    required this.logs,
    required this.meds,
    required this.l10n,
    required this.onOpen,
  });

  final List<MedicationLog> logs;
  final List<Medication> meds;
  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final taken = logs.where((l) => l.isTaken).length;
    final pending = logs.where((l) => l.isPending).toList();
    final MedicationLog? next = pending.isEmpty ? null : pending.first;
    return _SurfaceCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.medication,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.medicationsCardTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (logs.isNotEmpty)
                Text(
                  l10n.homeTakenTodayCount(taken, logs.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: const SizedBox(
              height: 10,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.peak,
                      AppColors.unstuck,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (next != null) ...[
            const SizedBox(height: 8),
            Text(
              '${next.medicationName} · ${DateFormat.Hm(l10n.localeName).format(next.scheduledTime)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.homeNoMedsToday,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnchorCard extends StatelessWidget {
  const _AnchorCard({
    required this.snapshots,
    required this.l10n,
    required this.onOpen,
  });

  final List<RoutineSnapshot> snapshots;
  final AppLocalizations l10n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final locale = l10n.localeName;
    return _SurfaceCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.routineAnchorLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          if (snapshots.isEmpty)
            Text(
              l10n.routineAnchorHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textLight
                    : AppColors.textDark,
              ),
            )
          else
            for (final snapshot in snapshots)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  l10n.homeRoutineSnapshotLine(
                    DateFormat('HH:mm', locale).format(snapshot.savedAt),
                    snapshot.mainFocusAnchor.trim().isEmpty
                        ? l10n.exportRoutineAnchorEmpty
                        : snapshot.mainFocusAnchor.trim(),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.card),
      onTap: onTap,
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: AppColors.mutedText(isDark)),
          ),
        ),
      ),
    );
  }
}

class _MoodHalo extends StatelessWidget {
  const _MoodHalo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            AppColors.primary,
            AppColors.accent,
            AppColors.unstuck,
            AppColors.primary,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: const Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  AppColors.primary,
                  AppColors.accent,
                  AppColors.unstuck,
                ],
              ),
            ),
            child: SizedBox(width: 18, height: 18),
          ),
        ),
      ),
    );
  }
}
